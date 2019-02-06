//
//  RealmObjects.swift
//  KeyManagement
//
//  Created by Stefan Haßferter on 09.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//
import RealmSwift
import Foundation



class BuddyOwnKeyPartContainer:Object {
    
    override static func primaryKey() -> String? {
        return "primaryKey"
    }
    
    @objc dynamic var primaryKey:String!
    @objc dynamic var partNumber:Int=0
    @objc dynamic var keyPart:Data!
    @objc dynamic var id:String!
    @objc dynamic var thresholdParts:Int=0
    
    convenience init(usage:String,keypart:Data,partNumber:Int,thresholdParts:Int) {
        self.init()
        self.primaryKey = usage + String(partNumber)
        self.partNumber = partNumber
        self.keyPart = keypart
        self.id = usage
        self.thresholdParts = thresholdParts
        
    }
    
    convenience init(keyPartDTO:KeyPartDTO) {
        self.init()
        self.primaryKey = keyPartDTO.KeyPartContaierID + "_" + String(keyPartDTO.partNumber)
        self.partNumber = keyPartDTO.partNumber
        self.keyPart = keyPartDTO.keyPart
        self.id = keyPartDTO.KeyPartContaierID
        self.thresholdParts = keyPartDTO.partsThreshold
        
    }
    
    
    
    
}




