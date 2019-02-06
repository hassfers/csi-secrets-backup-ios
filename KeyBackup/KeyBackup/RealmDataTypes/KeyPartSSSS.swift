//
//  keyPartSSSS.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 29.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation

import RealmSwift

class KeyPartSSSS: Object {
    
    override static func primaryKey() -> String? {
        return "keyPartID"
    }
    
    @objc dynamic var keyPartID:String!
    @objc dynamic var partNumber:Int = 0
    @objc dynamic var keyPart:Data!
    @objc dynamic var alreadyShared = 0
    @objc dynamic var usage:String!
    
    let fromOwner = RealmOptional<Bool>()
    
    let buddys = List<Buddy>()
    
    let keyContainer = LinkingObjects(fromType: KeyPartContainer.self, property: "includingKeys")
    
    
    convenience init(keyPartID:String = "", partNR: Int, keyPart:Data, usage: String) {
        self.init()
//        self.primaryKey = usage + String(partNR)
        if(keyPartID.isEmpty){
            self.keyPartID = "KeyPart_" + UUID().uuidString
        }else {
            self.keyPartID = keyPartID
        }
        self.usage = usage
        self.partNumber = partNR
        self.keyPart = keyPart
        alreadyShared = 0
    }
    
}
