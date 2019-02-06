//
//  RecoveryKeyPartContainer.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 31.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit
import RealmSwift

class RecoveryKeyPartContainer: Object {
    override static func primaryKey() -> String? {
        return "containerID"
    }
    
    @objc dynamic var keyUsage:String!
    @objc dynamic var containerID:String!
    @objc dynamic var thresholdKeyParts:Int = 0
    
    let includingKeys = List<KeyPartSSSS>()
    let buddies = List<iCloudBuddyDSO>()
    
    
    //    convenience init(containerID:String, keyUsage: String,thresholdKeyParts:Int,buddies:[iCloudBuddy]) {
    //        self.init()
    //        self.keyUsage = keyUsage
    //        self.thresholdKeyParts = thresholdKeyParts
    //        self.containerID = containerID
    //        self.buddies.append(objectsIn: buddies)
    //        }
    
    convenience init(icloudKeyPart:iCloudKeyPartInformations) {
        self.init()
        self.keyUsage = icloudKeyPart.usage
        self.thresholdKeyParts = icloudKeyPart.thresholdParts
        self.containerID = icloudKeyPart.keyContaierID
        icloudKeyPart.linkedBuddies.forEach{
            self.buddies.append(iCloudBuddyDSO(iCloudBuddy: $0,containerID:icloudKeyPart.keyContaierID))
        }
    }
    
    convenience init(from firstKeyPart:KeyPartDTO ){
        self.init()
        self.keyUsage = firstKeyPart.KeyPartContaierID
        self.thresholdKeyParts = firstKeyPart.partsThreshold
        self.containerID = firstKeyPart.KeyPartContaierID
    }
    
    
}

class iCloudBuddyDSO:Object {
    override static func primaryKey() -> String? {
        return "primaryKey"
    }
    @objc dynamic var primaryKey:String!
    @objc dynamic var nickname:String!
    let keyNumber = RealmOptional<Int>()
    @objc dynamic var keyPartImported = false
    
    
    convenience init(iCloudBuddy:iCloudBuddy,containerID:String) {
        self.init()
        self.nickname = iCloudBuddy.nickname
        self.keyNumber.value = iCloudBuddy.keyNumber
        self.primaryKey = containerID + "_" + nickname + String(keyNumber.value ?? 9999)
    }
}
