//
//  AddKey.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 15.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class AddKeyViewController: UIViewController {
    
    static let identifier = "AddKeyViewController"
    // MARK: - Outlets
    @IBOutlet weak var usageTextFieldOutlet: MyTextflied!
    @IBOutlet weak var secretTextFieldOutlet: MyTextflied!
    @IBOutlet weak var totalPartsOutlet: MyTextflied!
    @IBOutlet weak var thresholdPartsOutlet: MyTextflied!
    @IBOutlet weak var totalPartsSlider: UISlider!
    @IBOutlet weak var neededPartsSlider: UISlider!
    @IBOutlet weak var sliderContentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let backgroundTapRecognizer = UIGestureRecognizer(target: self, action: Selector(("backgroundTab")))
//        self.view.addGestureRecognizer(backgroundTapRecognizer)
//        sliderContentView.addGestureRecognizer(backgroundTapRecognizer)
        self.hideKeyboardWhenTappedAround()
    }
    
    // MARK: - Button Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
         totalPartsOutlet.text =  String(Int(totalPartsSlider.value))
        thresholdPartsOutlet.text = String(Int(neededPartsSlider.value))
    }
    
    @IBAction func generateKeyButtonPressed(_ sender: Any) {
        secretTextFieldOutlet.text = ""
        secretTextFieldOutlet.text = randomString(32)
    }
    
    
    @IBAction func generatePartsButtonPressed(_ sender: Any) {
        
        guard totalPartsOutlet.text != "" && thresholdPartsOutlet.text != "" && secretTextFieldOutlet.text != "" && usageTextFieldOutlet.text != "" else {
            showStandardAlert(view: self, title: "Insert all needed Information", message: "")
            return
        }
        
        var secret:Secret!
        var secrets:[Secret.Share]!
        
        let totalNumberParts = Int(totalPartsOutlet.text!)
        let thresholdNumber = Int(thresholdPartsOutlet.text!)
        
        guard totalNumberParts != nil && thresholdNumber != nil else {
            showStandardAlert(view: self, title: "Error", message: "please insert only numbers")
            return
        }
        
        guard totalNumberParts! >= thresholdNumber! && thresholdNumber! >= 2 else {
            showStandardAlert(view: self, title: "Error", message: "Parts to Share has to be at least 2 and greater or equal to Parts Needed to Recover")
            return
        }
        do{
            secret = try Secret(data: secretTextFieldOutlet.text!.data(using: .utf8)!, threshold: thresholdNumber!, shares: totalNumberParts!)
            secrets = try secret.split()
            let keys = createPartsAndStore(secrets: secrets,usage: usageTextFieldOutlet.text!)
            let keycontaier = KeyPartContainer(keyUsage: usageTextFieldOutlet.text!, keys: keys, totalKeyParts: totalNumberParts!, thresholdKeyParts: thresholdNumber!)
            try database.write {
                database.add(keycontaier, update: true)
            }
        }
        catch {
            print(error)
            showStandardAlert(view: self, title: "ERROR", message: error.localizedDescription)
            return
        }
//        showStandardAlert(view: self, title: "Success", message: "Parts successfully generated")
        showLocalNotification(identifier: "create", title: "Created", body: "Parts created")
        try? writeBuddyFileToiCloud(fileName: "Buddies")
        navigationController?.popViewController(animated: true)
    }
    


func createPartsAndStore(secrets:[Secret.Share],usage:String)->[KeyPartSSSS]{
    var keys = [KeyPartSSSS]()
    for x in secrets
    {
        let part = KeyPartSSSS(partNR: Int(x.point), keyPart: x.data,usage: usage)
        keys.append(part)
    }
    return keys
}

    //MARK: -
func backgroundTab() {
    usageTextFieldOutlet.endEditing(true)
    secretTextFieldOutlet.endEditing(true)
    totalPartsOutlet.endEditing(true)
    thresholdPartsOutlet.endEditing(true)
}
    //MARK: - Slider functions
    
    
    @IBAction func totalSliderChanged(_ sender: Any) {

        totalPartsOutlet.text =  String(Int(totalPartsSlider.value))
        neededPartsSlider.value = roundf(totalPartsSlider.value/2)
        thresholdPartsOutlet.text = String(Int(neededPartsSlider.value))
    }
    
    @IBAction func thresholdPartsChanged(_ sender: Any) {
        
        if(neededPartsSlider.value>totalPartsSlider.value){
        neededPartsSlider.value = totalPartsSlider.value
    }
        
    thresholdPartsOutlet.text = String(Int(neededPartsSlider.value))
    }
    
}


func randomString(_ n: Int) -> String
{
    let a = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    
    var s = ""
    
    for _ in 0..<n
    {
        let r = Int.random(in: 0 ... (a.count-1))
        s +=  String(a[a.index(a.startIndex, offsetBy: r)])
    }
    
    return s
}
