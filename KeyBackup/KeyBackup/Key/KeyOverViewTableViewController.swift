//
//  KeyOverViewTableViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 17.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

import UserNotifications
import RealmSwift
class KeyOverViewTableViewController: UITableViewController {
    
    
    let usageStrings = ["local saved keys", "iCloud keys for Recovery"]
    
    var localKeyContainers = [KeyPartContainer]()
    var iCloudKeyContainers = [RecoveryKeyPartContainer]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //        let predicate = NSPredicate(format: "forRecovery == %@",NSNumber(value: false))
        if database == nil {
            decryptDatabase {
                if database != nil {
//                    self.localKeyContainers = Array(database.objects(KeyPartContainer.self))
                    self.readContainersFormDatabase()
                    self.tableView.isHidden = false
                } else {
                    if let vc = self.storyboard?.instantiateViewController(withIdentifier: LoginViewController.identifier){
                        super.present(vc, animated: true, completion: nil)
                    }
                }
            }
            
        } else {
            self.tableView.isHidden = false
            readContainersFormDatabase()
            //            localKeyContainers = Array(database.objects(KeyPartContainer.self))
        }
        
    }
    
    func readContainersFormDatabase(){
        iCloudKeyContainers = []
        self.localKeyContainers = Array(database.objects(KeyPartContainer.self))
        let localRecoveryContainer = Array(database.objects(RecoveryKeyPartContainer.self))
        
        if let iCloudKeys = try? readBuddyFileFromiCloud(fileName: "Buddies"){
            
            iCloudKeys?.iCloudKeyPartBuddyUsages.forEach{ (iCloudKeyPart) in
                if !localKeyContainers.contains(iCloudKeyPart){
                    let recoveryKeyPartContainer = RecoveryKeyPartContainer(icloudKeyPart: iCloudKeyPart)
                    
                    // if obejct doesnst exist create if it does load it
                    if database.object(ofType: RecoveryKeyPartContainer.self,
                                       forPrimaryKey: iCloudKeyPart.keyContaierID) == nil {
                        try! database.write {
                            database.add(recoveryKeyPartContainer,update: true)
                        }
                        iCloudKeyContainers.append(recoveryKeyPartContainer)
                    } else {
                        iCloudKeyContainers.append(database.object(ofType: RecoveryKeyPartContainer.self,
                                                                   forPrimaryKey: iCloudKeyPart.keyContaierID)!)
                    }
                }
            }
        }
        
        
        localRecoveryContainer.forEach { (container) in
            if !iCloudKeyContainers.contains(container),
                !localKeyContainers.contains(container){
                iCloudKeyContainers.append(container)
            }
        }
        tableView.reloadData()
        print(localKeyContainers.map{$0.containerID})
        print(iCloudKeyContainers.map{$0.containerID})

    }
    
    // MARK: - Button Actions
    @IBAction func addKeyButtonPressed(_ sender: Any) {
        guard let addKeyVC = storyboard?.instantiateViewController(withIdentifier: AddKeyViewController.identifier) else {return}
        navigationController?.pushViewController(addKeyVC, animated: true)
        //        present(addKeyVC, animated: true, completion: nil)
    }
    
    
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 0
        if localKeyContainers.count > 0 {
            numberOfSections += 1
        }
        if iCloudKeyContainers .count > 0 {
            numberOfSections += 1
        }
        
        return numberOfSections
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if localKeyContainers.count > 0 {
            return usageStrings[section]
        }else {
            return usageStrings[section+1] //Only happens if new installed
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if localKeyContainers.count > 0 {
            if section == 0 {
                return localKeyContainers.count
            }else{
                return iCloudKeyContainers.count
            }
        }else {
            return iCloudKeyContainers.count
            //Only happens if new installed
        }
        
        //        self.navigationController.present
        
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: KeyOverViewTableViewCell.identifier, for: indexPath) as! KeyOverViewTableViewCell
        
        var usage:String = ""
        var image:UIImage = #imageLiteral(resourceName: "circleRed")
        if localKeyContainers.count > 0 {
            if indexPath.section == 0 {
                if localKeyContainers.count > indexPath.row{
                    usage = localKeyContainers[indexPath.row].keyUsage
                    image = setSharingProgressImage(container: localKeyContainers[indexPath.row])
                }}else{
                if iCloudKeyContainers.count > indexPath.row{
                    usage = iCloudKeyContainers[indexPath.row].keyUsage
                    image = setSharingProgressImage(container: iCloudKeyContainers[indexPath.row])
                }
            }
        }
        else {
            if iCloudKeyContainers.count > indexPath.row{
                usage = iCloudKeyContainers[indexPath.row].keyUsage
                image = setSharingProgressImage(container: iCloudKeyContainers[indexPath.row])
            }
        }
        
        cell.keyUsage.text = usage
        cell.statusImage.image = image
        return cell
    }
    
    
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if localKeyContainers.count > 0 {
            if indexPath.section == 0 {
                if localKeyContainers.count > indexPath.row{
                    let vc:KeyDetailViewController = storyboard?.instantiateViewController(withIdentifier:
                        KeyDetailViewController.identifier) as! KeyDetailViewController
                    vc.actualKeyContainer = localKeyContainers[indexPath.row]
                    //                    present(vc, animated: true)
                    navigationController?.pushViewController(vc, animated: true)
                }}else{
                if iCloudKeyContainers.count > indexPath.row{
                    let vc:KeyRecoveryViewController = storyboard?.instantiateViewController(withIdentifier:
                        KeyRecoveryViewController.identifier) as! KeyRecoveryViewController
                    vc.acctualKeyContainer = iCloudKeyContainers[indexPath.row]
                    //                    present(vc, animated: true)
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        else {
            if iCloudKeyContainers.count > indexPath.row{
                let vc:KeyRecoveryViewController = storyboard?.instantiateViewController(withIdentifier:
                    KeyRecoveryViewController.identifier) as! KeyRecoveryViewController
                vc.acctualKeyContainer = iCloudKeyContainers[indexPath.row]
                //                present(vc, animated: true)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    
    func setSharingProgressImage(container:KeyPartContainer)->UIImage{
        if container.alreadySharedParts >= container.totalKeyParts {
            return #imageLiteral(resourceName: "circleGreen")
        }
        else if container.alreadySharedParts >= container.thresholdKeyParts{
            return #imageLiteral(resourceName: "circleOrange")
        }
        return #imageLiteral(resourceName: "circleRed")
    }
    
    func setSharingProgressImage(container:RecoveryKeyPartContainer)->UIImage{
        if container.includingKeys.count >= container.thresholdKeyParts {
            return #imageLiteral(resourceName: "circleGreen")
        }
        return #imageLiteral(resourceName: "circleRed")
    }
    
}
