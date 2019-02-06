//
//  keyBuddyCollectionViewCell.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 22.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class keyBuddyCollectionViewCell: UICollectionViewCell {
    var wasSelected:Bool = false
    
    @IBOutlet weak var buddyContactPicture: UIImageView!
    
    @IBOutlet weak var textLabel: UILabel!
    
    static let identifier = "keyBuddyCollectionViewCell"
    
    override var isSelected: Bool{
        didSet{
            print(isSelected)
            print(textLabel.text)
            if isSelected{
                layer.borderWidth = 1
                layer.borderColor = UIColor.clear.cgColor
                backgroundColor = UIColor.lightGray.withAlphaComponent(0.7)
                layer.cornerRadius = 3
                wasSelected = true
                
            }else {
                layer.borderWidth = 0
                backgroundColor = UIColor.clear
                wasSelected = false
            }
        }
    }
}
