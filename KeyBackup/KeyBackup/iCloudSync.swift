//
//  iCloudSync.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 29.12.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift

func writeBuddyFileToiCloud(fileName:String) throws {
    
    let allBuddies = Array(database.objects(KeyPartContainer.self))
    
    let newICloudContaiers = iCloudSaveDSO(keyContainers: allBuddies)
    
    guard let iCloudDocumentsURL = iCloudDocumentsURL else { return }
    if(!(filemgr.fileExists(atPath: iCloudDocumentsURL.path))){
        try! filemgr.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
    }
    let  iCloudBuddyFile = iCloudDocumentsURL.appendingPathComponent(fileName).appendingPathExtension("buddies")
    if filemgr.fileExists(atPath: iCloudBuddyFile.path) {
        let oldICloudContaiers = try readBuddyFileFromiCloud(fileName: fileName)
        
        oldICloudContaiers?.iCloudKeyPartBuddyUsages.forEach({ (oldItem) in
            if !newICloudContaiers.iCloudKeyPartBuddyUsages.contains(oldItem){
                newICloudContaiers.iCloudKeyPartBuddyUsages.append(oldItem)
            }
        })
    }
    
    let data = newICloudContaiers.serialize()!

        try data.write(to:iCloudBuddyFile,options: [.completeFileProtection])
        try! filemgr.setAttributes([FileAttributeKey.init("666"):666], ofItemAtPath: iCloudDocumentsURL.path)

}

func readBuddyFileFromiCloud(fileName:String) throws -> iCloudSaveDSO? {
    
    var iCloudBuddyFile:URL
    
    guard let iCloudDocumentsURL = iCloudDocumentsURL else { return nil  }
    
    if(!(filemgr.fileExists(atPath: iCloudDocumentsURL.path))){
        try! filemgr.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
    }
    let filelist = try filemgr.contentsOfDirectory(atPath:iCloudDocumentsURL.path)
    print(filelist)
    
    iCloudBuddyFile = iCloudDocumentsURL.appendingPathComponent(fileName).appendingPathExtension("buddies")
    
    
    if(!(filemgr.fileExists(atPath: iCloudBuddyFile.path))){
        //Hidden iCloud file which should be downloaded
        let hiddeniCloudBuddyFileForDownload = iCloudDocumentsURL.appendingPathComponent("." + fileName).appendingPathExtension("buddies").appendingPathExtension("icloud")
        
        if((filemgr.fileExists(atPath: hiddeniCloudBuddyFileForDownload.path))){ 
            if(filemgr.changeCurrentDirectoryPath((localDocumentsURL?.path)!)){
                try  filemgr.startDownloadingUbiquitousItem(at: hiddeniCloudBuddyFileForDownload)
                
            }
        }
    }
    guard let iCloudData =  try readFromFile(url: iCloudBuddyFile) else {return nil}
    let decoder = JSONDecoder()
    return try decoder.decode(iCloudSaveDSO.self, from: iCloudData)
    
}
