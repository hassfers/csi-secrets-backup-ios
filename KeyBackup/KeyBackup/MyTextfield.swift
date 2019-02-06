//
//  MyTextflied.swift
//  KeyManagement
//
//  Created by Stefan Haßferter on 17.09.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import Foundation
import UIKit
class MyTextflied: UITextField {
    
    required init?(coder aDecoder: NSCoder!) {
        
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 5.0;
        self.layer.borderColor = UIColor.gray.cgColor
        
        self.layer.borderWidth = 1.5
        self.addTarget(self, action: #selector(dissmissAfterActionKey) , for: .primaryActionTriggered)
    }
    
    
    @objc func dissmissAfterActionKey() {
        self.endEditing(true)
    }

    
}
