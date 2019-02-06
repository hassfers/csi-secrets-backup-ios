//
//  StandardButton.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 02.11.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class StandardButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    required init() {
        // set myValue before super.init is called
        
        super.init(frame: .zero)
        
        // set other operations after super.init, if required
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setTitleColor(.white, for: .normal)
        layer.cornerRadius = 5
        backgroundColor = UIColor.lightGray
    }
    

}
