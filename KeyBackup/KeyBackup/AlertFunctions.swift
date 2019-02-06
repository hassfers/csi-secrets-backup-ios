//
//  AlertFunctions.swift
//  encryptedMultipeer
//
//  Created by Stefan Haßferter on 05.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

func showStandardAlert(view: UIViewController,title:String, message:String,stay:Bool = false){
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
        if(!stay){
            view.dismiss(animated: true, completion: nil)
        }}
    ))
    view.present(alert, animated: true, completion: nil)
}


func showSharingViewController(vc:UIViewController,itemsToShare:[Any]){
    
    let activityViewController = UIActivityViewController(activityItems: itemsToShare , applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = vc.view // so that iPads won't crash
    
    // exclude some activity types from the list (optional) discuss which should be possible
    activityViewController.excludedActivityTypes = [ .postToFacebook,
                                                     .assignToContact,
                                                     .addToReadingList,
                                                     .postToVimeo,
                                                     .postToWeibo,
                                                     .postToFlickr,
                                                     .postToTwitter,
                                                     .postToTencentWeibo,
                                                     .openInIBooks]
    
    // present the view controller
    vc.present(activityViewController, animated: true, completion: nil)
}


func showAddNewOrModifyBuddyAlert(vc: UIViewController, keydata:Data){
    
    let alert = UIAlertController(title: "New Key", message: "Do you want to add a new Buddy or modify an existing buddy", preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Add new", style: .default, handler: { [weak alert] (_) in
        if let buddy = loadBuddyWithCommKey(key: keydata){
            showLocalNotification(identifier: "ERROR", title: "Already imported", body: ("This Key is already asigned to your buddy calleddel" + String(buddy.nickname)))
        }
        else {
            let buddyVC = vc.storyboard?.instantiateViewController(withIdentifier: BuddyDetailViewController.identifier) as! BuddyDetailViewController
            buddyVC.prepareForNewBuddy(from: keydata)
            buddyVC.editMode = true
            (vc as! UINavigationController).pushViewController(buddyVC, animated: true)
        }
        }
    ))
    
    alert.addAction(UIAlertAction(title: "Modify Old", style: .default, handler: { [weak alert] (_) in
        
        showLocalNotification(identifier: "NewKey", title: "Select Buddy", body: "Select the buddy you want to add the key to")

        let buddyTVC = (vc as! UINavigationController).viewControllers.first as! BuddyTableViewController
        buddyTVC.importedKeyBuffer = keydata
        buddyTVC.isKeySelectModeEnabled = true
        
//        (vc as! UINavigationController).pushViewController(buddyTVC, animated: true)
        }
    ))
    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (alert) in
    }))
    
    vc.present(alert, animated: true, completion: nil)
    
}



