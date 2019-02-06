//
//  KeyDetailViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 22.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class KeyDetailViewController: UIViewController {
    
    
    static let identifier = "KeyDetailViewController"
    var selectedCell:Int = -1
    
    @IBOutlet weak var keyUsageOutlet: UILabel!
    @IBOutlet weak var partsSharedOutlet: UILabel!
    @IBOutlet weak var buddySharedView: UICollectionView!
    @IBOutlet weak var keyPartsSharedVisualization: UIStackView!
    

    var actualKeyContainer: KeyPartContainer!{
        didSet{
            loadViewIfNeeded()
            keyUsageOutlet.text = actualKeyContainer.keyUsage
        }
    }
    
    var buddies = [Buddy](){
        didSet{
            buddySharedView.reloadData()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buddySharedView.dataSource = self
        buddySharedView.delegate = self

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        let predicate = NSPredicate(format: "ANY keyOwner.usage == %@",actualKeyContainer.keyUsage as NSObject)
        
        buddies = Array(database.objects(Buddy.self).filter(predicate).sorted(byKeyPath: "nickname", ascending: true))
        
        let addBuddy = Buddy(publicKey: "test".data(using: .utf8)!)
        addBuddy.contactPicture = "AddPicture"
        buddies.append(addBuddy)
        
        
        keyPartsSharedVisualization.subviews.forEach({ $0.removeFromSuperview() })
        visualizeSharedParts()
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareWithNewBuddyPressed(_ sender: Any) {
        
        if selectedCell >= 0 && selectedCell<buddies.count{
            let selectedBuddy = buddies[selectedCell]
            
            //TODO use Container 
            let predicate = NSPredicate(format: "usage == %@",actualKeyContainer.keyUsage as NSObject)
            
            
           let keypart = Array(selectedBuddy.keyOwner.filter(predicate))
            
            if(keypart.count == 1){
                let keypartDTO = KeyPartDTO(from: keypart.first!, from: selectedBuddy, partsThreshold: (actualKeyContainer?.thresholdKeyParts)!)
                
                guard let keypartDTOData = keypartDTO.serialize() else {return}
                guard let key = restoreKey(from: selectedBuddy.commPublicKey) else {return}
                guard let encryptedDTOData = encryptData(publicKey: key , dataToEncrypt: keypartDTOData) else {return}
                
                
                var path:URL??
                if selectedBuddy.nickname == nil {
                    path = try?  writeToFile(data: encryptedDTOData, fileName: actualKeyContainer.keyUsage + "_" + "")
                }else{
                    path = try?  writeToFile(data: keypartDTOData, fileName: actualKeyContainer.keyUsage + "_" + selectedBuddy.nickname)
                }
                showSharingViewController(vc: self, itemsToShare: [path])
                   try! writeBuddyFileToiCloud(fileName: "Buddies")
            }
        }
        
        
    }
    
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        showRealyDeleteAlert()
    }
    
    
    
    //MARK: -
    func visualizeSharedParts() {
        
        let totalParts = actualKeyContainer.totalKeyParts
        let thresholdParts = actualKeyContainer.thresholdKeyParts
        
        let alreadySharedParts = actualKeyContainer.includingKeys.filter { (keyPartSSSS) -> Bool in
            return keyPartSSSS.buddys.count>0
        }
        print(alreadySharedParts.count)
        
        //TODO hack
        partsSharedOutlet.text = String(buddies.count-1) + " / " + String(totalParts)
        
        //create StackView
        
        let NumberOfAlreadySharedParts = actualKeyContainer.alreadySharedPartWithBuddies.count

        for x in 0...totalParts-1 {
            let view = UIView()
            if x < NumberOfAlreadySharedParts{
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
extension KeyDetailViewController: UICollectionViewDataSource,UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buddies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: keyBuddyCollectionViewCell.identifier, for: indexPath) as! keyBuddyCollectionViewCell
    
        
        if indexPath.row < buddies.count-1 {
            let buddy = buddies[indexPath.row]
            if(buddy.contactPicture == nil){
                cell.buddyContactPicture.image = #imageLiteral(resourceName: "Stephen-A.-Sonstein-advisory.png")
            }else{
                let picPath = localDocumentsURL?.appendingPathComponent(buddy.contactPicture!)
                cell.buddyContactPicture.image = UIImage(contentsOfFile: picPath!.path)
            }
            cell.textLabel.text = buddy.nickname
            //            cell.metadataLabel.text = buddies[indexPath.row]
        }
        if(indexPath.row == buddies.count-1){
            cell.buddyContactPicture.image = #imageLiteral(resourceName: "images")
            cell.textLabel.text = "share with new buddy"
        }
        
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        
        guard selectedCell != indexPath.item else {
         collectionView.deselectItem(at: indexPath, animated: true)
        selectedCell = -1
            return
        }
        
        selectedCell = indexPath.item
        if indexPath.row == buddies.count-1 {
            let buddySelectVC:SelectBuddyViewController = storyboard?.instantiateViewController(withIdentifier: SelectBuddyViewController.identifier) as! SelectBuddyViewController
            buddySelectVC.acctualKeyPartContainer = actualKeyContainer
            navigationController?.pushViewController(buddySelectVC, animated: true)
        }
    }
}

extension KeyDetailViewController {
    func showRealyDeleteAlert() {
        
        let alert = UIAlertController(title: "Delete key",
                                      message: "do you really want to delete this key",
                                      preferredStyle: .actionSheet)

        
        alert.addAction(UIAlertAction(title: "YES", style: .destructive, handler: { [weak alert] (_) in

            try? deleteKeyContainerFormBuddyFile(fileName:"Buddies",container: self.actualKeyContainer)
            
            
           try! database.write {
            self.actualKeyContainer.includingKeys.forEach({ (keyPartSSSS) in
                database.delete(keyPartSSSS)
            })
                database.delete(self.actualKeyContainer)
            }
            
           self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
            }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in

//            self.dismiss(animated: true, completion: nil)
            }
        ))
        
        present(alert, animated: true, completion: nil)
        

    }
}
