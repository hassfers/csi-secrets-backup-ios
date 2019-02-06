//
//  securityFunctions.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 11.11.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation

func encryptData(publicKey:SecKey,dataToEncrypt : Data ) -> Data? {
    var error: Unmanaged<CFError>?
    guard let cipherText = SecKeyCreateEncryptedData(publicKey,
                                                     algorithm,
                                                     dataToEncrypt as CFData,
                                                     &error) as Data?
        else {print("encryption failed")
                                                        return nil}
    return cipherText
}

func decryptData(dataToDecrypt:Data) -> Data? {
    var error: Unmanaged<CFError>?
    
    guard let privateKey = createOrLoadCommunicationPrivatKey() else {
        showLocalNotification(identifier: "ERROR", title: "No Key", body: "No Private Key Found")
        return nil
    }
    
    guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
        print("not supported")
        return nil
    }
    
    guard let clearText = SecKeyCreateDecryptedData(privateKey,
                                                    algorithm,
                                                    dataToDecrypt as CFData,
                                                    &error) as Data? else {
                                                        print("something went wrong \n Wrong Key? ")
                                                        return nil
    }
    return clearText
}
