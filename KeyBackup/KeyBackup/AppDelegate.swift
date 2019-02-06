//
//  AppDelegate.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 10.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit
import AVFoundation
import RealmSwift
import UserNotifications


//let database = try!Realm()

var database:Realm!{
    didSet{
        print("Database opened")
    }
}

let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA512AESGCM

let notificationCenter = UNUserNotificationCenter.current()
let tagPrivateKey = "adrosysBackup.mykey.private".data(using: .utf8)!

var error: Unmanaged<CFError>?
let filemgr = FileManager.default
let iCloudDocumentsURL = filemgr.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents")
let localDocumentsURL = filemgr.urls(for: .documentDirectory, in: .userDomainMask).first



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        if database == nil {
//            print("open secure database")
//            loadKeyForDatabase { key -> Realm in
//                configureDB(key: key)
//            }
//        }
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print(NSHomeDirectory())
        let options: UNAuthorizationOptions = [.alert, .sound,.badge];
        
        notificationCenter.requestAuthorization(options: options) {
            (granted, error) in
            print(granted)
            if !granted {
                print("Something went wrong")
            }
        }
        notificationCenter.delegate = self
        
        
        return true
    }
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print("open file")
        print(inputURL.pathExtension)
        
        guard database != nil else {
            showLocalNotification(identifier: "Error", title: "Database locked", body: "Please unlock Database before import data!")
            return false
        }
        
        if(inputURL.pathExtension == "png"){
            print("Picture input found") 
            let data = try? Data(contentsOf: inputURL)
            let image = UIImage(data: data!)
            if let incomingKeyData = parseImage(image: image) {
                
                //TODO
                guard let viewcontroller  = window?.rootViewController as? RootViewController else {
                    fatalError("The root view is not a document browser!")
                }
                
                guard loadCommunicationPublicKey()?.Data() != incomingKeyData else {
                    showLocalNotification(identifier: "Error", title: "Not Allowed", body: "Its not allowed to import your own public key")
                    return false
                }
                
                
                if let buddy = loadBuddyWithCommKey(key: incomingKeyData){
                    showLocalNotification(identifier: "Buddy", title: "Key already imported", body: "Key already in Database and belongs to " + String(buddy.nickname))
                } else {
                    viewcontroller.selectedIndex = 1
                    showAddNewOrModifyBuddyAlert(vc: viewcontroller.selectedViewController!, keydata: incomingKeyData)
                    return true
                }
                
            }
            else{
                showLocalNotification(identifier: "BackupKeys", title: "Import failed", body: "Key import failed")
            }
            
            return true
        }
        
        if(inputURL.pathExtension == "abf"){
            print("Backup File found")
            print(inputURL)
            guard let viewcontroller = window?.rootViewController as? RootViewController else {
                fatalError("The root view is not a document browser!")
            }
            
            guard database != nil else {
                showLocalNotification(identifier: "Error", title: "Database locked", body: "Please unlock Database and try to import again!")
                return false
            }
            
            guard let fileData = try? readFromFile(url: inputURL) else {
                showStandardAlert(view: viewcontroller,
                                  title: "Import Failed",
                                  message: "Decryption failed, maybe the wrong key was used to encrypt")
                return false
            }
            
            if let decryptedData = decryptData(dataToDecrypt: fileData!){
                parseIncomingKeyData(fileData: decryptedData)
            }
            
        }
        return false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}


