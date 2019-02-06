//
//  keychainHandler.swift
//  encryptedMultipeer
//
//  Created by Stefan Haßferter on 01.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift

func restoreKey(from keyData: Data)-> SecKey?  {
    let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                  kSecAttrKeySizeInBits as String : 4096]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateWithData(keyData as CFData,
                                         options as CFDictionary,
                                         &error) else {
                                            print("cant generate Key back")
                                            return nil
    }
    return key
}



var keychainCreateDictionary: [String:Any] {
    
    let privateKeyAttr: [String : Any] = [
        kSecAttrIsPermanent as String :true , // Store in KeyChain
        kSecAttrApplicationTag as String : tagPrivateKey] // KeyChain Tag
    
    let keyPairAttr: [String : Any] = [
        kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String : 4096,
        kSecPrivateKeyAttrs as String : privateKeyAttr]
    
    return keyPairAttr
    
}

var keychainLoadDictionary: [String:Any]  {
    
    let privateKeyAttr: [String : Any] = [
        kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
        kSecClass as String: kSecClassKey,
        kSecReturnRef as String : true,
        kSecAttrApplicationTag as String : tagPrivateKey]
    
    return privateKeyAttr
    
}


func createOrLoadCommunicationPrivatKey() -> SecKey? {
    
    let  key:SecKey?
    let  keyPairAttrLoad = keychainLoadDictionary
    
    //Read Keychain if there is already a Key with this tag
    var resultPrivateKey: CFTypeRef?
    let statusPrivateKey = SecItemCopyMatching(keyPairAttrLoad as CFDictionary, &resultPrivateKey)
    var error: Unmanaged<CFError>?
    
    if(statusPrivateKey == noErr){
        print("Key loaded from Keychain")
        key = resultPrivateKey as! SecKey
    }
    else{
        let keyPairAttrCreate = keychainCreateDictionary
        key = SecKeyCreateRandomKey(keyPairAttrCreate as CFDictionary, &error) ?? nil
        print("Key generated")
    }
    
    return key
    
}

func renewCommunicationPublicKey()->SecKey?{
    let status = SecItemDelete(keychainLoadDictionary as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        showLocalNotification(identifier: "KeyChainFailure", title: "Failed to renew CommKey", body: "")
        return nil
    }
    let key = createOrLoadCommunicationPrivatKey()
    
    if key != nil {
        showLocalNotification(identifier: "KeyChainFailure", title: "Renew CommKey successfully", body: "")
    }
    else{
        showLocalNotification(identifier: "KeyChainFailure", title: "Failed to renew CommKey", body: "")
    }
    
    return loadCommunicationPublicKey()
    
}


func loadCommunicationPublicKey() -> SecKey? {
    guard let privateKey = createOrLoadCommunicationPrivatKey() else {return nil}
    let publicKey = SecKeyCopyPublicKey(privateKey)!
    return publicKey
}



