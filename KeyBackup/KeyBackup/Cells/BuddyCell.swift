//
//  BuddyCell.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 10.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class BuddyCell: UITableViewCell {
    
    static let identifier = "BuddyCell"
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var metadataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
