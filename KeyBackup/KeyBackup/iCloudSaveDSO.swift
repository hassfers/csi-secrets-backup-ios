//
//  iCloudSaveDSO.swift
//  KeyManagement
//
//  Created by Stefan Haßferter on 30.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation

class iCloudBuddy: Codable {
    var nickname:String!
    var keyNumber: Int!
    
    convenience init(buddy:Buddy,keyNumber:Int!) {
        self.init()
        self.nickname = buddy.nickname
        self.keyNumber = keyNumber
    }
}

class iCloudKeyPartInformations: Codable {
    
    var usage:String!
    var keyContaierID:String!
    var linkedBuddies = [iCloudBuddy]()
    var thresholdParts:Int!
    
    convenience init(keyContaierID:String,usage: String, buddies: [iCloudBuddy],thresholdParts: Int) {
        self.init()
        self.usage = usage
        self.linkedBuddies = buddies
        self.thresholdParts = thresholdParts
        self.keyContaierID = keyContaierID
    }
    
}



class iCloudSaveDSO:Codable {
    
    let creationDate:Date = Date.init(timeIntervalSinceNow: 0)
    
    var iCloudKeyPartBuddyUsages = [iCloudKeyPartInformations]()
    
    
    convenience init(keyContainers: [KeyPartContainer]) {
        self.init()
        
        
        for key in keyContainers{
            
            var iCloudBuddies = [iCloudBuddy]()
            for keyItem in key.includingKeys
            {
                var linkedBuddies = [Buddy]()
                linkedBuddies.append(contentsOf: keyItem.buddys)
                iCloudBuddies.append(contentsOf: linkedBuddies.map{iCloudBuddy(buddy: $0,keyNumber: keyItem.partNumber)})
                
            }
            iCloudKeyPartBuddyUsages.append(iCloudKeyPartInformations(keyContaierID: key.containerID, usage: key.keyUsage, buddies: iCloudBuddies, thresholdParts: key.thresholdKeyParts))
        }
    }
    
    func serialize() -> Data? {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        return data
    }
    
}
