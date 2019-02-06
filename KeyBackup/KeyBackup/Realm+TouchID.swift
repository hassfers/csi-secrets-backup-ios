//
//  Realm+TouchID.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 21.12.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import RealmSwift

func configureDB(key: Data) -> Realm {
    let configuration = Realm.Configuration( encryptionKey: key)
    let realm = try! Realm(configuration: configuration)
    return realm
}

func realmKeychainQuery(tag: String, reading: Bool)-> NSDictionary{
    let sacObject =
        SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                        .userPresence,
                                        nil)!
    let select_query: NSDictionary = [
        kSecClass: kSecClassKey,
        kSecAttrApplicationTag: tag,
        kSecAttrAccessControl: sacObject,
        kSecReturnData: reading, // cause we want to read it from keychain
        kSecUseOperationPrompt: "Authenticate to access safety storage"
    ]
    return select_query
}


func decryptDatabase(completion: @escaping () -> () ){
    let group = DispatchGroup()
    group.enter()
    var key:Data!
    

    DispatchQueue.main.async {
        if database == nil {
            
            
            print("try to open secure database")
            //                loadKeyForDatabase { key -> Realm in
            //                    configureDB(key: key)
            //                }

            let keychainIdentifier = "de.adorsys.CryptoWalletBackupApplication"

            let keychainIdentifierTag = keychainIdentifier.data(using: String.Encoding.utf8)!
            var extractedData: CFTypeRef!
            var error: Unmanaged<CFError>?
            let protectionRef = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as CFTypeRef
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                protectionRef,
                                                                .biometryAny, // Always ask for TouchID
                &error)
            var select_status = SecItemCopyMatching(realmKeychainQuery(tag: keychainIdentifier, reading: true), &extractedData)
            if select_status == errSecSuccess {
                print(extractedData)
                key = extractedData as! Data
            } else if select_status == errSecItemNotFound {
                print ("Key not Found generate new key")
                let keyData = NSMutableData(length: 64)!
                let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
                assert(result == 0, "Failed to get random bytes")
                
                // Store the key in the keychain
                let query: [NSString: AnyObject] = [
                    kSecClass: kSecClassKey,
                    kSecAttrApplicationTag: keychainIdentifierTag as AnyObject,
                    kSecAttrKeySizeInBits: 512 as AnyObject,
                    kSecValueData: keyData,
                    kSecAttrAccessControl: accessControl as AnyObject
                ]
                
                select_status = SecItemAdd(query as CFDictionary, nil)
                assert(select_status == errSecSuccess, "Failed to insert the new key in the keychain")
                //                database = configureDB(key: keyData as Data)
                key = keyData as Data
            } else if select_status == errSecUserCanceled{
                print ("Cancel")
            }
        }
        group.leave()
    }
    
    // does not wait. But the code in notify() gets run
    // after enter() and leave() calls are balanced
    
    group.notify(queue: .main) {
        if key != nil {
            database = configureDB(key: key)
        }
        completion()
    }
    
}

