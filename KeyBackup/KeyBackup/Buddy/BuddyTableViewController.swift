//
//  BuddyTableViewTableViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 10.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit



class BuddyTableViewController: UITableViewController,KeyImportOptionViewDelegate {
    
    static let identifier = "BuddyTableViewController"
    
    var isKeySelectModeEnabled:Bool = false
    var importedKeyBuffer:Data!
    
    
    var imagepicker = UIImagePickerController()
    //    var buddies:[Buddy]! = nil
    @IBOutlet var buddiesTableViewOutlet: UITableView!
    
    var buddies = [Buddy](){
        didSet{
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        buddies = Array(database.objects(Buddy.self).sorted(byKeyPath: "nickname", ascending: true))
        if isKeySelectModeEnabled {
            isKeySelectModeEnabled = false
            importedKeyBuffer = nil
        }
    }
    
    
    
    @IBAction func addBuddyButtonPressed(_ sender: Any) {
        
        let importOptions = KeyImportOptionView()
        importOptions.modalPresentationStyle = .overCurrentContext
        importOptions.delegate = self
        present(importOptions, animated: true, completion: {importOptions.generateImportOptionsView()})
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buddies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BuddyCell.identifier, for: indexPath) as! BuddyCell
        if indexPath.row < buddies.count {
            let buddy = buddies[indexPath.row]
            cell.metadataLabel.text = buddy.nickname
            if(buddy.contactPicture == nil){
                cell.photoView.image = #imageLiteral(resourceName: "Stephen-A.-Sonstein-advisory.png")
            }else{
                let picPath = localDocumentsURL?.appendingPathComponent(buddy.contactPicture!)
                cell.photoView.image = UIImage(contentsOfFile: picPath!.path)
            }
            //            cell.metadataLabel.text = buddies[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < buddies.count {
            let buddy = buddies[indexPath.row]
            let vc = storyboard?.instantiateViewController(withIdentifier: BuddyDetailViewController.identifier) as! BuddyDetailViewController
            vc.loadBuddyInformations(from: buddy.BuddyID)
            if isKeySelectModeEnabled {
                vc.editMode = true
                vc.receiveKeyDataFromImportView(key: importedKeyBuffer)
            
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
}

extension BuddyTableViewController{
    func receiveKeyDataFromImportView(key: Data) {
        
        print("BuddyTableViewController \(key)")
//        createNewBuddy(key: key)
        
        if let buddy = loadBuddyWithCommKey(key: key){
            showLocalNotification(identifier: "ERROR", title: "Already imported", body: ("This Key is already asigned to your buddy calleddel" + String(buddy.nickname)))
        }
        else {
            let vc: BuddyDetailViewController = storyboard?.instantiateViewController(withIdentifier: BuddyDetailViewController.identifier) as! BuddyDetailViewController
            vc.prepareForNewBuddy(from: key)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
