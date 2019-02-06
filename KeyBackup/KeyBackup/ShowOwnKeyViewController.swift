//
//  ShowOwnKeyViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 11.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class ShowOwnKeyViewController: UIViewController {
    @IBOutlet weak var QRCodeImageOutlet: UIImageView!
    var privateKey:SecKey!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let publicKey = loadCommunicationPublicKey(){
        QRCodeImageOutlet.contentMode = .scaleAspectFit
        QRCodeImageOutlet.image = generateQRCode(from: (publicKey.toBase64String()))
        }
    }
    
    @IBAction func shareWithFileButton(_ sender: Any) {
        let imageToShare = QRCodeImageOutlet.image?.pngData()
        let activityViewController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional) discuss which should be possible
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook, .addToReadingList,.assignToContact,.markupAsPDF,.postToTwitter,.postToVimeo,.postToWeibo,.openInIBooks]
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func RenewCommKeyButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Renew Key", message: "Do your really want to renew your communication key? After that you have to share your new key with every buddy you want to communicate with!", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Renew key", style: .destructive, handler: { [weak alert] (_) in
            if let key = renewCommunicationPublicKey() {
                self.QRCodeImageOutlet.contentMode = .scaleAspectFit
                self.QRCodeImageOutlet.image = generateQRCode(from: key.toBase64String())
            }
            }
        ))
    
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        
        
        
        
        
        
    
    }
}
