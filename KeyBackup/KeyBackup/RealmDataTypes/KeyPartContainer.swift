//
//  KeyPartContainer.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 25.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift

class KeyPartContainer: Object {
    override static func primaryKey() -> String? {
        return "containerID"
    }
    
    @objc dynamic var containerID:String!
    @objc dynamic var keyUsage:String!
    @objc dynamic var totalKeyParts:Int = 0
    @objc dynamic var thresholdKeyParts:Int = 0
    @objc dynamic var KeySharingCounter:Int = 0
    
    let forRecovery = RealmOptional<Bool>()
    let includingKeys = List<KeyPartSSSS>()
    
    convenience init(keyUsage: String, keys:[KeyPartSSSS],totalKeyParts:Int,thresholdKeyParts:Int) {
        self.init()
        self.keyUsage = keyUsage
        self.includingKeys.append(objectsIn: keys)
        self.totalKeyParts = totalKeyParts
        self.thresholdKeyParts = thresholdKeyParts
        self.containerID = "KeyPartContainer_"+UUID().uuidString

        }

    
    
    func selectRandomKeyPart() -> KeyPartSSSS? {
        var predicate = NSPredicate(format: "alreadyShared == %@ AND usage == %@", KeySharingCounter as NSObject, keyUsage as NSObject)
        print(predicate)
        var keyparts = Array(database.objects(KeyPartSSSS.self).filter(predicate))
        
        if(keyparts.count == 0){
            try? database.write {
                KeySharingCounter += 1
                database.add(self,update: true)
            }
            predicate = NSPredicate(format: "alreadyShared == %@", KeySharingCounter as NSObject)
            //    print(predicate)
            keyparts = Array(database.objects(KeyPartSSSS.self).filter(predicate))
        }
        
        
        //    print(keyparts.count)
        let randomInt = Int.random(in: 0..<keyparts.count)
        //    print(randomInt)
        
        let selectedKeyPart = keyparts[randomInt]
        return selectedKeyPart
    }
    
    var alreadySharedParts:Int {
        
        var count = 0
        includingKeys.forEach{count += $0.buddys.count}
        return count
    }
    
    var alreadySharedPartWithBuddies:[Buddy]{
    
        var buddies = [Buddy]()
        
        includingKeys.forEach {
            buddies.append(contentsOf: $0.buddys)
        }
        
        return buddies
    }
    
    func getKeyPart(sharedWith buddy:Buddy) -> KeyPartSSSS?{
        
        var keyPart:KeyPartSSSS?
        
        includingKeys.forEach {
            if ($0.buddys.contains(buddy)){
                keyPart = $0
            }
        }
        return keyPart
    }
    
    
    
}
