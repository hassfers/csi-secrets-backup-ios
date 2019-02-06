//
//  SelectBuddyViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 23.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class SelectBuddyViewController: UIViewController {
    
    static let identifier = "SelectBuddyViewController"
    
    var buddies:[Buddy]! = nil
    var selectedRow:Int = 0
    
    var acctualKeyPartContainer:KeyPartContainer!{
        didSet{
            updatePickerViewEntrys(usage: acctualKeyPartContainer.keyUsage)
        }
    }
    
    
    @IBOutlet weak var selectBuddyPickerView: UIPickerView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectBuddyPickerView.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Button actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func shareViaFileButtonPressed(_ sender: Any) {
        guard selectedRow<buddies.count else {
            return
        }
        
        let selectedBuddy = buddies[selectedRow]
        let keypart = acctualKeyPartContainer.selectRandomKeyPart()
        let keypartDTO = KeyPartDTO(from: keypart!, from: selectedBuddy, partsThreshold: (acctualKeyPartContainer?.thresholdKeyParts)!)
        
        
        
        try! database.write {
            keypart?.alreadyShared += 1
            keypart?.buddys.append(selectedBuddy)
            //update Keypart database entry
            database.add(keypart!,update: true)
            
            //ONLY FOR TESTING
            
//            selectedBuddy.ownKeyParts.append(BuddyOwnKeyPartContainer(usage: acctualKeyPartContainer.keyUsage, keypart: (keypart?.keyPart)!, partNumber: (keypart?.partNumber)!, thresholdParts: (acctualKeyPartContainer?.thresholdKeyParts)!))
            
        }

        updatePickerViewEntrys(usage: acctualKeyPartContainer.keyUsage)
        guard let keypartDTOData = keypartDTO.serialize() else {return}
        
        guard let key = restoreKey(from: selectedBuddy.commPublicKey) else {return}
        guard let encryptedDTOData = encryptData(publicKey: key , dataToEncrypt: keypartDTOData) else {return}
        var path:URL??
        if selectedBuddy.nickname == nil {
         path = try? writeToFile(data: encryptedDTOData, fileName: acctualKeyPartContainer.keyUsage + "_" + "")
        }else{
             path = try?  writeToFile(data: encryptedDTOData, fileName: acctualKeyPartContainer.keyUsage + "_" + selectedBuddy.nickname)
        }
        
        showSharingViewController(vc: self, itemsToShare: [path])
        
        
        //TODO
        try! writeBuddyFileToiCloud(fileName: "Buddies")
    }
    @IBAction func startP2PConnection(_ sender: Any) {
    }
    
    
}

//Mark: - PickerView datasource and delegate

extension SelectBuddyViewController:UIPickerViewDataSource,UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
         return buddies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return buddies[row].nickname
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedRow = row
    }
    
    func updatePickerViewEntrys(usage:String)  {
        loadViewIfNeeded()
        
        var predicate = NSPredicate(format: "NONE keyOwner.usage == %@",usage as NSObject)
        //
        print(predicate)
        
        buddies = Array(database.objects(Buddy.self).filter(predicate).sorted(byKeyPath: "nickname", ascending: true))
        selectBuddyPickerView.reloadAllComponents()
        predicate = NSPredicate(format: "alreadyShared != 0")
        //    print(predicate)
        let keyparts = Array(database.objects(KeyPartSSSS.self).filter(predicate))
    }
    
}
