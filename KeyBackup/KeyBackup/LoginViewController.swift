//
//  LoginViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 21.12.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit
import RealmSwift
class LoginViewController: UIViewController {

    static let identifier = "LoginViewController"
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        if database != nil {
        self.dismiss(animated: true)
        }
        
    }
    
    
    @IBAction func loginButton(_ sender: Any) {
        if database == nil {
            
            decryptDatabase {
                if database != nil {
                    self.dismiss(animated: true)
                }
            }
        } else {
            self.dismiss(animated: true)
        }
    }
    
}
