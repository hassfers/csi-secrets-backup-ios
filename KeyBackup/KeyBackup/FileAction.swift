//
//  fileactions.swift
//  encryptedMultipeer
//
//  Created by Stefan Haßferter on 05.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift

func writeToFile(data: Data,fileName:String,buddiesfile:Bool = false) throws -> URL?  {
    
    let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
    var docsURL = dirPaths[0]
    if (buddiesfile){
        docsURL = dirPaths[0].appendingPathComponent(fileName + ".buddies")
    }else{
        docsURL = dirPaths[0].appendingPathComponent(fileName + ".abf")
    }
    print("\(#function) \n docsURL:\n \(docsURL)\n")
    
    try data.write(to: docsURL, options: [.completeFileProtection,.atomic])
    
    return docsURL
    
}

func deleteKeyContainerFormBuddyFile(fileName:String,container: KeyPartContainer) throws {
    
    let iCloudContainers = try readBuddyFileFromiCloud(fileName: fileName)
    
//    if (oldContainers?.iCloudKeyPartBuddyUsages.contains(container))!{
////        let index = oldContainers?.iCloudKeyPartBuddyUsages.ind
//        oldContainers?.iCloudKeyPartBuddyUsages.remove(container)
//    }
 
    
    
    iCloudContainers?.iCloudKeyPartBuddyUsages = (iCloudContainers?.iCloudKeyPartBuddyUsages.filter {
        $0.keyContaierID != container.containerID
        })!
    
    let data = iCloudContainers!.serialize()!
    if var iCloudDocumentsURL = filemgr.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
        
        if(!(filemgr.fileExists(atPath: iCloudDocumentsURL.path))){
            try! filemgr.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
        }
        iCloudDocumentsURL.appendPathComponent(fileName + ".buddies")
        
        //        try data.write(to:iCloudDocumentsURL,options: [.atomic,.completeFileProtection])
        try data.write(to:iCloudDocumentsURL,options: [.completeFileProtection])
        try! filemgr.setAttributes([FileAttributeKey.init("666"):666], ofItemAtPath: iCloudDocumentsURL.path)
        
    }
    
}

func deleteKeyContainerFormBuddyFile(fileName:String,container: RecoveryKeyPartContainer) throws {
    
    let iCloudContainers = try readBuddyFileFromiCloud(fileName: fileName)
    
    iCloudContainers?.iCloudKeyPartBuddyUsages = (iCloudContainers?.iCloudKeyPartBuddyUsages.filter {
        $0.keyContaierID != container.containerID
        })!
    
    let data = iCloudContainers!.serialize()!
    if var iCloudDocumentsURL = filemgr.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
        
        if(!(filemgr.fileExists(atPath: iCloudDocumentsURL.path))){
            try! filemgr.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
        }
        iCloudDocumentsURL.appendPathComponent(fileName + ".buddies")
        
        //        try data.write(to:iCloudDocumentsURL,options: [.atomic,.completeFileProtection])
        try data.write(to:iCloudDocumentsURL,options: [.completeFileProtection])
        try! filemgr.setAttributes([FileAttributeKey.init("666"):666], ofItemAtPath: iCloudDocumentsURL.path)
        
    }
}



func readFromFile(url:URL) throws -> Data?  {
    var data: Data?
    try NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges) { url in
        data = try Data(contentsOf: url)
    }
    return data ?? Data()
}


extension NSFileCoordinator {
    func coordinate(readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions = [], byAccessor reader: (URL) throws -> Swift.Void) throws {
        var outerError: NSError?
        var innerError: Error?
        coordinate(readingItemAt: url, options: options, error: &outerError) { url in
            do {
                try reader(url)
            } catch {
                innerError = error as NSError
            }
        }
        
        if let error = outerError {
            throw error
        }
        
        if let error = innerError {
            throw error
        }
    }
}


func parseIncomingKeyData(fileData: Data){
    
    let decoder = JSONDecoder()
    
    if let keyPartDTO = try? decoder.decode(KeyPartDTO.self, from: fileData) {
        
        
        let owner = loadBuddyWithCommKey(key: keyPartDTO.SenderCommKey)
        
        let buddyOwnKeyPartContainer = BuddyOwnKeyPartContainer(keyPartDTO: keyPartDTO)
        
        
        if database.object(ofType: BuddyOwnKeyPartContainer.self, forPrimaryKey: buddyOwnKeyPartContainer.primaryKey) == nil {
            showLocalNotification(identifier: "KeyPartImported", title: "Part imported", body: "Imported \(String(describing: owner?.nickname))'s keypart successfully")
            try? database.write {
                owner?.ownKeyParts.append(buddyOwnKeyPartContainer)
            }
        } else {
            showLocalNotification(identifier: "KeyPartImported", title: "Part already imported", body: " \(String(describing: owner?.nickname))'s keypart already imported") }
    }
    else {
        if let recoveryKeyPartDTOs = try? decoder.decode([KeyPartDTO].self, from: fileData) {
            
            recoveryKeyPartDTOs.forEach { (item) in
                // if container doesnt exist
                if  database.object(ofType: RecoveryKeyPartContainer.self, forPrimaryKey: item.KeyPartContaierID) == nil {
                    let newContainer = RecoveryKeyPartContainer(from: item)
                    try? database.write{
                        database.add(newContainer)
                    }
                }
                
                
                if let container = database.object(ofType: RecoveryKeyPartContainer.self, forPrimaryKey: item.KeyPartContaierID){
                    
                    if database.object(ofType: KeyPartSSSS.self, forPrimaryKey: item.KeyPartContaierID + "_" + String(item.partNumber)) == nil {
                        let keyPartFromItem = KeyPartSSSS(keyPartID:item.KeyPartContaierID + "_" + String(item.partNumber),
                                                          partNR: item.partNumber,
                                                          keyPart: item.keyPart,
                                                          usage: "")
                        
                        try! database.write {
                            if !container.includingKeys.contains(keyPartFromItem){
                                container.includingKeys.append(keyPartFromItem)
                                let buddies = container.buddies.filter{$0.keyNumber.value == keyPartFromItem.partNumber}
                                buddies.forEach({ (buddy) in
                                    buddy.keyPartImported = true
                                })
                            }
                        }
                    }
                    
                }
            }
        }
        
        
    }
    
}
