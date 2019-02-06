//
//  Buddy.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 24.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift


class Buddy:Object{
    
    override static func primaryKey() -> String? {
        return "BuddyID"
    }
    
    
    @objc dynamic var BuddyID:String!
    @objc dynamic var commPublicKey:Data!
    @objc dynamic var nickname:String!
    @objc dynamic var contactPicture:String?
    @objc dynamic var additionalInformation:String?
    
    let ownKeyParts = List<BuddyOwnKeyPartContainer>()
    let keyOwner = LinkingObjects(fromType: KeyPartSSSS.self, property: "buddys")
    
    convenience init(tag:String,publicKey:Data) {
        self.init()
        self.nickname = tag
        self.commPublicKey = publicKey
        self.BuddyID = "Buddy_" + UUID().uuidString
    }
    
    convenience init(publicKey:Data) {
        self.init()
        self.commPublicKey = publicKey
        self.BuddyID = "Buddy_" + UUID().uuidString
    }
    
    //    func setPicture(picuture:UIImage?)  {
    //        if let pictureInstance = picuture {
    //            contactPicture =
    //        }
    //    }
}

func loadBuddyWithCommKey(key: String)-> Buddy? {
    
    let buddy = database.objects(Buddy.self).filter { (buddy) -> Bool in
        return (buddy.commPublicKey.base64EncodedString() == key)
    }
    if buddy.count==1 {
        return buddy.first
    }
    return nil
}
func loadBuddyWithCommKey(key: Data)-> Buddy? {
    
    let buddy = database.objects(Buddy.self).filter { (buddy) -> Bool in
        return (buddy.commPublicKey == key)
    }
    if buddy.count==1 {
        return buddy.first
    }
    return nil
}
