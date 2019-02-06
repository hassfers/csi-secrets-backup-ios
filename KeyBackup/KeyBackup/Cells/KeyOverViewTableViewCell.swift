//
//  keyOverViewTableViewCell.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 22.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class KeyOverViewTableViewCell: UITableViewCell {

    static let identifier = "KeyOverViewTableViewCell"
    
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBOutlet weak var keyUsage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
