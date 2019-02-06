//
//  CommunicationViewController.swift
//  encryptedMultipeer
//
//  Created by Stefan Haßferter on 10.08.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

enum transmitStatus:String,Equatable {
    case success
    case failure
    case partAlreadyTransmitted
}


class CommunicationViewController : UIViewController{
    
    static let identifier = "CommunicationViewController"
    
    var actualBuddy:Buddy!
    var privateKey:SecKey!
    var publicKey:SecKey!
    var selectedRow:Int = 0
    var error: Unmanaged<CFError>?
    
    var containers = [KeyPartContainer]()
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    //    let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA512
    @IBOutlet weak var cancelButtonPressed: UIBarButtonItem!
    
    @IBOutlet weak var keyUsagePickerView: UIPickerView!
    @IBOutlet weak var SendPartsButton: StandardButton!
    @IBOutlet weak var sendAllPartsBack: StandardButton!
    
    
    @IBOutlet weak var connectedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        privateKey = createOrLoadCommunicationPrivatKey()
        keyUsagePickerView.delegate = self
        
    }
    override func viewDidAppear(_ animated: Bool) {
        enableButtons(true)
        updatePickerViewEntrys()
    }
    
    
    
    //MARK: - Button Actions
    @IBAction func CancelButtonPressed(_ sender: Any) {
        mcSession.disconnect()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendPartToBuddy(_ sender: Any) {
        
        guard selectedRow < containers.count else {return}
        
        let container = containers[selectedRow]
        
        if container.alreadySharedPartWithBuddies.contains(actualBuddy){
            
            print("already shared")
            
            if let keypart = container.getKeyPart(sharedWith: actualBuddy){
                
                
                let keypartDTO = KeyPartDTO(from: keypart, from: actualBuddy, partsThreshold: (keypart.keyContainer.first?.thresholdKeyParts)!)
                
                if let data = keypartDTO.serialize(){
                    guard let key = restoreKey(from: actualBuddy.commPublicKey) else {return}
                    guard let encryptedDTOData = encryptData(publicKey: key , dataToEncrypt: data) else {return}
                    sendData(data: encryptedDTOData, message: "part retransmitted")
                }
            }
        }else {
            
            if let keypart = container.selectRandomKeyPart(){
                
                let keypartDTO = KeyPartDTO(from: keypart, from: actualBuddy, partsThreshold: (keypart.keyContainer.first?.thresholdKeyParts)!)
                
                if let data = keypartDTO.serialize(){
                    guard let key = restoreKey(from: actualBuddy.commPublicKey) else {return}
                    guard let encryptedDTOData = encryptData(publicKey: key , dataToEncrypt: data) else {return}
                    sendData(data: encryptedDTOData, message: "part transmitted")
                }
                
                try? database.write {
                    keypart.buddys.append(actualBuddy)
                }
                
            }
        }
    }
    
    @IBAction func sendAllPartsBack(_ sender: Any) {
        var keyDTO = [KeyPartDTO]()
        Array( actualBuddy.ownKeyParts).forEach{
            let keyPart = KeyPartDTO(from: $0, buddy: self.actualBuddy)
            keyDTO.append(keyPart)
        }
        let encoder = JSONEncoder()
        
        guard let dataForShare = try? encoder.encode(keyDTO.self) else {return}
        
        
        guard let key = restoreKey(from: actualBuddy.commPublicKey) else {return}
        guard let encryptedDTOData = encryptData(publicKey: key , dataToEncrypt: dataForShare) else {return}
        
        sendData(data: encryptedDTOData, message: "transmitted \(keyDTO.count) Part(s) back")
        
    }
    
    
    @IBAction func hostSession(_ sender: Any) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "adorsys", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        connectedLabel.text = "Session Hosted"
        connectedLabel.textColor = UIColor.orange
    }
    
    @IBAction func connectSession(_ sender: Any) {
        
        let mcBrowser = MCBrowserViewController(serviceType: "adorsys", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    
    func enableButtons(_ state: Bool){
        SendPartsButton.isEnabled = state
        sendAllPartsBack.isEnabled = state
        keyUsagePickerView.isUserInteractionEnabled = state
    }
    
    func sendData(data:Data,message:String){
        if mcSession.connectedPeers.count > 0 {
            do {
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                
                
            }catch{
                fatalError("Could not send keypart")
            }
            
        }else{
            print("you are not connected to another device")
        }
    }
    
    func sendResponse(_ status: transmitStatus){
        if mcSession.connectedPeers.count > 0 {
            
            switch status {
            case .success:
                do {
                    try mcSession.send(transmitStatus.success.rawValue.data(using: .utf8)!, toPeers: mcSession.connectedPeers, with: .reliable)
                }catch{
                    fatalError("Could not send todo item")
                }
            case .failure: do {
                try mcSession.send(transmitStatus.failure.rawValue.data(using: .utf8)!, toPeers: mcSession.connectedPeers, with: .reliable)
            }catch{
                fatalError("Could not send todo item")
                }
            case .partAlreadyTransmitted: do {
                try mcSession.send(transmitStatus.partAlreadyTransmitted.rawValue.data(using: .utf8)!, toPeers: mcSession.connectedPeers, with: .reliable)
            }catch{
                fatalError("Could not send todo item")
                }
            }
        }else{
            print("you are not connected to another device")
        }
    }
}

//MARK: - CommunicationViewControllerDelegate

extension CommunicationViewController: MCSessionDelegate, MCBrowserViewControllerDelegate{
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            DispatchQueue.main.async {
                print("Connected: \(peerID.displayName)")
                self.connectedLabel.text = "Connected: \(peerID.displayName)"
                self.connectedLabel.textColor = UIColor.green
                self.enableButtons(true)
                
            }
            
        case MCSessionState.connecting:
            DispatchQueue.main.async {
                //            print("Connecting: \(peerID.displayName)")
                //             self.connectedLabel.text = "Connecting: \(peerID.displayName)"
            }
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.connectedLabel.text = "Not Connected: \(peerID.displayName)"
                self.connectedLabel.textColor = .red
                showLocalNotification(identifier: "connection", title: "Disconnected", body: "You've been disconnected from \(String(self.actualBuddy.nickname))")
                
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        DispatchQueue.main.async {
            
            
            if let statusString = String(data: data, encoding: .utf8),
                let statusCode = transmitStatus(rawValue: statusString){
                
                switch statusCode {
                case .success: self.showToast(message: "successful transmitted",
                                                            x: self.view.frame.size.width/2,
                                                            y: self.view.frame.size.height-150)
                    try? writeBuddyFileToiCloud(fileName: "Buddies")
                    return
                case .failure: self.showToast(message: "transmit failure",
                                                            x: self.view.frame.size.width/2,
                                                            y: self.view.frame.size.height-150)
                    return
                case .partAlreadyTransmitted: self.showToast(message: "Part already transmitted",
                                                                           x: self.view.frame.size.width/2,
                                                                           y: self.view.frame.size.height-150)
                    return
                }
            }
            
            if let decryptedData = decryptData(dataToDecrypt: data){
                
                parseIncomingKeyData(fileData: decryptedData)
                
                self.showToast(message: "part received", x: self.view.frame.size.width/2, y: self.view.frame.size.height-150)
                self.sendResponse(.success)
            }else {
                self.showToast(message: "decyrption failed", x: self.view.frame.size.width/2, y: self.view.frame.size.height-150)
                self.sendResponse(.failure)
            }
        }
        
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - PickerView datasource and delegate

extension CommunicationViewController:UIPickerViewDataSource,UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return containers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return containers[row].keyUsage
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedRow = row
    }
    
    func updatePickerViewEntrys()  {
        loadViewIfNeeded()
        
        
        //        if acctualBuddy.keyOwner.count>0{
        //        acctualBuddy.keyOwner.forEach({
        //            acctualBuddyContainers.append(($0.keyContaier.first?.containerID)!)})
        //        }
        //
        containers = Array(database.objects(KeyPartContainer.self))
        //            return !acctualBuddyContainers.contains($0.containerID)
        //        })
        
        keyUsagePickerView.reloadAllComponents()
        
    }
    
}
