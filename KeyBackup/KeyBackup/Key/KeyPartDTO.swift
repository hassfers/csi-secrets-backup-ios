//
//  KeyPartDTO.swift
//  KeyManagement
//
//  Created by Stefan Haßferter on 26.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation


class KeyPartDTO: Codable {

    let partNumber:Int!
    let keyPart:Data!
    let transferDate:Date!
    let fromOwner:Bool!
    
    
    let partsThreshold:Int!
    let KeyPartContaierID:String!
    let SenderCommKey:Data!
    
    
    init(from keyPart:KeyPartSSSS,from buddy:Buddy,partsThreshold:Int) {
        
        self.keyPart = keyPart.keyPart
        self.partNumber = keyPart.partNumber
        self.transferDate = Date.init(timeIntervalSinceNow: 0)
        self.fromOwner = true
        self.partsThreshold = partsThreshold
        self.KeyPartContaierID = keyPart.keyContainer.first?.containerID
        
        //here has to be the senders(my) publickey to the receiver knows where the key comes from

//        self.SenderCommKey = loadCommunicationPublicKey()?.toBase64String()

        self.SenderCommKey = loadCommunicationPublicKey()?.Data()
    }
    
    
    init(from ownKeyPart:BuddyOwnKeyPartContainer,buddy: Buddy) {
        self.keyPart = ownKeyPart.keyPart
        self.partNumber = ownKeyPart.partNumber
        self.transferDate = Date.init(timeIntervalSinceNow: 0)
        self.fromOwner = true
        self.partsThreshold = ownKeyPart.thresholdParts
        self.KeyPartContaierID = ownKeyPart.id
//        self.SenderCommKey = loadCommunicationPublicKey()?.toBase64String()
        self.SenderCommKey = loadCommunicationPublicKey()?.Data()
        
    }
    

    
    func serialize() -> Data? {
        
        let encoder = JSONEncoder()
        let encodedData = try? encoder.encode(self)
        
        return encodedData
    }
    
    func decodeDataFromBase64() {
//        keyPart = Data(base64Encoded: keyPart)
    }
    
    
}

