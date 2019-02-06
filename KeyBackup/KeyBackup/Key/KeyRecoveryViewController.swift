//
//  KeyDetailViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 22.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class KeyRecoveryViewController: UIViewController {
    
    
    static let identifier = "KeyRecoveryViewController"
    var selectedCell:Int = -1
    
    @IBOutlet weak var keyUsageOutlet: UILabel!
    @IBOutlet weak var partsSharedOutlet: UILabel!
    @IBOutlet weak var buddySharedView: UITableView!
    @IBOutlet weak var keyPartsSharedVisualization: UIStackView!
    @IBOutlet weak var recoveryButton: UIButton!
  

    var acctualKeyContainer: RecoveryKeyPartContainer!{
        didSet{
            loadViewIfNeeded()
            keyUsageOutlet.text = acctualKeyContainer.keyUsage
            
        }
    }
    
    var buddies = [iCloudBuddyDSO](){
        didSet{
            buddySharedView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buddySharedView.dataSource = self
//        buddySharedView.delegate = self

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
//
        buddies = Array(acctualKeyContainer.buddies).filter{!$0.keyPartImported}
        
        keyPartsSharedVisualization.subviews.forEach({ $0.removeFromSuperview() })
        
        
        visualizeSharedParts()
        
        if acctualKeyContainer.includingKeys.count >= acctualKeyContainer.thresholdKeyParts {
            recoveryButton.isEnabled = true
        }
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

    @IBAction func restoreButtonPressed(_ sender: Any) {
        
        if acctualKeyContainer.includingKeys.count >= acctualKeyContainer.thresholdKeyParts {
             var fewShares = [Secret.Share]()
            
            acctualKeyContainer.includingKeys.forEach { (keyPart) in
            
                
                print(keyPart.keyPart)
                print(keyPart.keyPart.hexEncodedString())
                
//                let newKeyPart = try! Secret.Share.init(data: Data(base64Encoded: keyPart.keyPart!)!)
                
                let newKeyPart = try! Secret.Share.init(data: keyPart.keyPart!)
                
                print(newKeyPart.point)
                newKeyPart.bytes.forEach({ (item) in
                    print(item.hex)
                })
                print(newKeyPart.data.hexEncodedString())
                if(!(fewShares.contains(secret: newKeyPart))){
                    fewShares.append(newKeyPart)
                }
            }
            
            let data = try? Secret.combine(shares: fewShares)
            
            print(data?.hexEncodedString())
            print(String(data: data!, encoding: .utf8))
            showStandardAlert(view: self, title: "recovery", message: String(data: data!, encoding: .utf8)!)
        }
        
    }
    
    @IBAction func deleteKeyButtonPressed(_ sender: Any) {
        
        try? deleteKeyContainerFormBuddyFile(fileName:"Buddies",container: acctualKeyContainer)
        try? database.write {
            database.delete(self.acctualKeyContainer.buddies)
            database.delete(self.acctualKeyContainer.includingKeys)
            database.delete(self.acctualKeyContainer)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: -
    func visualizeSharedParts() {

        let importedParts = acctualKeyContainer.includingKeys.count
        let thresholdParts = acctualKeyContainer.thresholdKeyParts

        let alreadySharedParts = acctualKeyContainer.includingKeys.filter { (keyPartSSSS) -> Bool in
            return keyPartSSSS.buddys.count>0
        }
        print(alreadySharedParts.count)

        //TODO hack
        partsSharedOutlet.text = String(importedParts) + " / " + String(thresholdParts)

        //create StackView
        for x in 0...thresholdParts-1 {
            let view = UIView()
            
            if x<acctualKeyContainer.includingKeys.count
            {
                view.backgroundColor = .green
            }else
            {
                view.backgroundColor = .red
            }
            view.layer.cornerRadius = 6
            keyPartsSharedVisualization.addArrangedSubview(view)
        }


    }
    
    
}
  //MARK: - CollectionView
extension KeyRecoveryViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buddies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TwoInformationsTableViewCell = tableView.dequeueReusableCell(withIdentifier: TwoInformationsTableViewCell.identifier, for: indexPath) as! TwoInformationsTableViewCell
        if indexPath.row < buddies.count {
            let buddy = buddies[indexPath.row]
            cell.FirstInformation.text = buddy.nickname
            cell.SecondInformation.text = "Part " + String(buddy.keyNumber.value ?? 0)
        }
        return cell
    }
    
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
