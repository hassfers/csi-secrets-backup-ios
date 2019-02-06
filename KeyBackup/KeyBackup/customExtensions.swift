//
//  customExtensions.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 28.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import UIKit

extension Array{
    func contains(_ item: iCloudKeyPartInformations) -> Bool {
        
        if type(of: self.first) == KeyPartContainer?.self {
            for x in self {
                let testItem = x as! KeyPartContainer
                if testItem.containerID == item.keyContaierID {
                    return true
                }
            }
            return false
        }
        
        if type(of: self.first) == iCloudKeyPartInformations?.self {
            for x in self {
                let testItem = x as! iCloudKeyPartInformations
                if testItem.keyContaierID == item.keyContaierID {
                    return true
                }
            }
            return false
        }
        return false
    }
    
    
    
    func contains(secret: Secret.Share) -> Bool {
        
        for item in self{
            let innerItem = item as! Secret.Share
            if innerItem.point == secret.point{
                return true
            }
        }
        return false
    }
    
    func contains(_ item: RecoveryKeyPartContainer) -> Bool {
        
        if type(of: self.first) == KeyPartContainer?.self {
            for x in self {
                let testItem = x as! KeyPartContainer
                if testItem.containerID == item.containerID {
                    return true
                }
            }
            return false
        }
        
        if type(of: self.first) == iCloudKeyPartInformations?.self {
            for x in self {
                let testItem = x as! iCloudKeyPartInformations
                if testItem.keyContaierID == item.containerID {
                    return true
                }
            }
            return false
        }
        
        if type(of: self.first) == RecoveryKeyPartContainer?.self {
            for x in self {
                let testItem = x as! RecoveryKeyPartContainer
                if testItem.containerID == item.containerID {
                    return true
                }
            }
            return false
        }
        return false
    }
    
    func contains(_ item: KeyPartContainer) -> Bool {
        
        if type(of: self.first) == KeyPartContainer?.self {
            for x in self {
                let testItem = x as! KeyPartContainer
                if testItem.containerID == item.containerID {
                    return true
                }
            }
            return false
        }
        
        if type(of: self.first) == iCloudKeyPartInformations?.self {
            for x in self {
                let testItem = x as! iCloudKeyPartInformations
                if testItem.keyContaierID == item.containerID {
                    return true
                }
            }
            return false
        }
        return false
    }
    
    func remove(_ item: KeyPartContainer){
        
        if type(of: self.first) == iCloudKeyPartInformations?.self {
            for (index,x) in self.enumerated() {
                let testItem = x as! iCloudKeyPartInformations
                if testItem.keyContaierID == item.containerID {
                    print("found at \(index)")
            
                    
                    return
                }
            }
        }
        
    }
    
    func contains(_ buddy: Buddy) -> Bool { 
        
        if type(of: self.first) == Buddy?.self{
            for x in self {
                let testItem = x as! Buddy
                if testItem.BuddyID  == buddy.BuddyID {
                    return true
                }
            }
            
        }
        return false
    }
    
    
}


extension UIViewController {
    func showToast(message: String,x:CGFloat,y:CGFloat) {
        let windowWidth = CGFloat(message.count)*8+20
        let toastLabel = UILabel(frame: CGRect(x: x - windowWidth/2, y: y, width: windowWidth, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })}
    }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension SecKey {
    func toBase64Data() -> Data {
        let key = SecKeyCopyExternalRepresentation(self, &error)! as Data
        return key.base64EncodedData()
    }
    func Data() -> Data {
        let key = SecKeyCopyExternalRepresentation(self, &error)! as Data
        return key
    }
    
    func toBase64String() -> String {
        let key = SecKeyCopyExternalRepresentation(self, &error)! as Data
        return key.base64EncodedString()
    }
}

extension Data {
    func restoreSecKey() -> SecKey?{
        return restoreKey(from: self)
    }
    
}
