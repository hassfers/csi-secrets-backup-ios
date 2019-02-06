//
//  BuddyDetailViewController.swift
//  KeyBackup
//
//  Created by Stefan Haßferter on 10.10.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//

import UIKit

class BuddyDetailViewController: UIViewController,KeyImportOptionViewDelegate {
    static let identifier = "BuddyDetailViewController"
    
    //MARK: - outlets
    @IBOutlet weak var ContactPictureOutlet: UIImageView!
    @IBOutlet weak var NiknameLabel: UILabel!
    @IBOutlet weak var AdditionalInformationsOutlet: UITextView!
    @IBOutlet weak var KeypartsFromOwnerOutlet: UITextView!
    @IBOutlet weak var KeypartsTableView: UITableView!
    @IBOutlet weak var upperButton: StandardButton!
    @IBOutlet weak var lowerButton: StandardButton!
    @IBOutlet weak var NiknameTextfield: UITextField!
    //MARK: - variables
    
    
    var rightBarButtonItem: UIBarButtonItem!
    var actualBuddy:Buddy!
    var editMode:Bool = false
    let imagePicker = UIImagePickerController()
    var picturePath:String!
    var commKey:Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarItems()
        ContactPictureOutlet.contentMode = .scaleAspectFit
        KeypartsTableView.dataSource = self
        imagePicker.delegate = self
        NiknameTextfield.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        NiknameTextfield.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showImagePicker))
        ContactPictureOutlet.isUserInteractionEnabled = true
        ContactPictureOutlet.addGestureRecognizer(tapGestureRecognizer)
        ContactPictureOutlet.contentMode = .scaleAspectFit
        AdditionalInformationsOutlet.delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateUIMode()
        if actualBuddy != nil {
            loadBuddyInformations(from: actualBuddy.BuddyID)
        }
        else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    //MARK: - Button Actions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if (NiknameTextfield.text?.isEmpty ?? false) && NiknameLabel.text == "<Nikname>"{
            try! database.write {
                database.delete(actualBuddy)
            }
        }
        actualBuddy = nil
        self.dismiss(animated: true) {
        }
        
    }
    @objc func editButtonPressed() {
        
        if editMode {
            
            if database.object(ofType: Buddy.self, forPrimaryKey: actualBuddy.BuddyID) == nil {
               try! database.write {
                    database.add(actualBuddy)
                }
                
            }
            
            if !(NiknameTextfield.text!.isEmpty),
                NiknameTextfield.text != actualBuddy.nickname{
                try! database.write {
                    actualBuddy.nickname = NiknameTextfield.text
                }
            }
            
            if(!(AdditionalInformationsOutlet.text?.isEmpty)! && AdditionalInformationsOutlet.text != actualBuddy.additionalInformation && AdditionalInformationsOutlet.text != "Enter additional information here such as mail or phonenumber."){
                try! database.write {
                    actualBuddy.additionalInformation  = AdditionalInformationsOutlet.text
                }
            }
            if(commKey != nil){
            try! database.write {
                actualBuddy.commPublicKey = commKey
                }}
            
            if(actualBuddy.contactPicture != nil && actualBuddy.contactPicture != picturePath ){
                //            try? filemgr.removeItem(at:URL(fileURLWithPath: actualBuddy!.contactPicture!))
                try! database.write {
                    actualBuddy.contactPicture = picturePath
                }
            }
            if(actualBuddy.contactPicture == nil && picturePath != nil ){
                try! database.write {
                    actualBuddy.contactPicture = picturePath
                }
            }
            //Dismiss screen after saveing new Buddy
            if NiknameLabel.text == "<Nikname>"{
                navigationController?.popViewController(animated: true)
            }
        }
        
        loadBuddyInformations(from: actualBuddy.BuddyID)
        //      toggle editMode
        editMode = !editMode
        updateUIMode()
    }
    
    @IBAction func upperButtonAction(_ sender: Any) {
        if editMode {
            let importOptionView = KeyImportOptionView()
            importOptionView.modalPresentationStyle = .overCurrentContext
            importOptionView.delegate = self
            present(importOptionView, animated: true, completion: importOptionView.generateImportOptionsView)
        }
        else{
            
            var keyDTO = [KeyPartDTO]()
            Array( actualBuddy.ownKeyParts).forEach{
                let keyPart = KeyPartDTO(from: $0, buddy: self.actualBuddy)
                keyDTO.append(keyPart)
            }
            let encoder = JSONEncoder()
            
            guard let dataForShare = try? encoder.encode(keyDTO.self) else {return}
            
            if let key = actualBuddy.commPublicKey.restoreSecKey(){
                
                if let dataForShare = encryptData(publicKey: key, dataToEncrypt: dataForShare){
                    let url = try? writeToFile(data: dataForShare, fileName: actualBuddy.nickname + "_restoreAllKeyParts")
                    showSharingViewController(vc: self, itemsToShare: [url])
                }
            }
        }
    }
    
    @IBAction func lowerButtonAction(_ sender: Any) {
        if editMode {
            showRealyDeleteAlert()
        }
        else{
            let vc:CommunicationViewController = storyboard?.instantiateViewController(withIdentifier: CommunicationViewController.identifier) as! CommunicationViewController
            vc.actualBuddy = actualBuddy
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func updateUIMode() {
        
        if editMode {
            NiknameTextfield.isHidden = false
            NiknameLabel.isHidden = true
            if actualBuddy.nickname != nil {
                NiknameTextfield.text = actualBuddy.nickname
            }
            rightBarButtonItem.title = "Save"
            upperButton.setTitle("Import new communication key", for: .normal)
            lowerButton.setTitle("Delete buddy", for: .normal)
            AdditionalInformationsOutlet.isEditable = true
        }else {
            NiknameTextfield.isHidden = true
            NiknameLabel.isHidden = false
            rightBarButtonItem.title = "Edit"
            upperButton.setTitle("Send parts back", for: .normal)
            lowerButton.setTitle("Start local communication session", for: .normal)
            AdditionalInformationsOutlet.isEditable = false
        }
        
    }
    
    
    func setupNavBarItems() {
        loadViewIfNeeded()
        rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editButtonPressed))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    
    func prepareForNewBuddy(from CommKey:Data){
        loadViewIfNeeded()
        editMode = true
        actualBuddy = Buddy(publicKey: CommKey)
        KeypartsFromOwnerOutlet.text = "You have got 0 \n keyparts saved from this Buddy"
        rightBarButtonItem.isEnabled = false
    }
    
    
    
    func loadBuddyInformations(from primaryKey:String) {
        
        guard let buddy = database.object(ofType: Buddy.self, forPrimaryKey: primaryKey) else {return}
        loadViewIfNeeded()
        actualBuddy = buddy
        if(buddy.contactPicture != nil){
            let picPath = localDocumentsURL?.appendingPathComponent(buddy.contactPicture!)
            ContactPictureOutlet.image = UIImage(contentsOfFile: picPath!.path)
        }
        
        if(buddy.nickname != nil){
            NiknameLabel.text = buddy.nickname
        }
        if(buddy.additionalInformation != nil){
            AdditionalInformationsOutlet.text = buddy.additionalInformation
        }
        
        KeypartsFromOwnerOutlet.text = "You have got " + String((buddy.ownKeyParts.count)) + "\n keyparts saved from this Buddy"
        
        
        
    }
    
    
    func showRealyDeleteAlert() {
        
        let alert = UIAlertController(title: "Delete key",
                                      message: "do you really want to delete this key",
                                      preferredStyle: .actionSheet)
        
        
        alert.addAction(UIAlertAction(title: "YES", style: .destructive, handler: { [weak alert] (_) in
            showLocalNotification(identifier: "deleted", title: "Deleted", body: ("you succsessfully deleted your buddy " + String(self.actualBuddy.nickname)))
            try? database.write {
                database.delete(self.actualBuddy)
            }
            
            self.navigationController?.popToRootViewController(animated: true)
            }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            
            }
        ))
        
        present(alert, animated: true, completion: nil)
        
        
    }
    
}

extension BuddyDetailViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actualBuddy.keyOwner.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TwoInformationsTableViewCell.identifier) as! TwoInformationsTableViewCell
        
        if indexPath.row < actualBuddy.keyOwner.count {
            cell.FirstInformation.text = actualBuddy.keyOwner[indexPath.row].usage
            cell.SecondInformation.text = "Part " + String(actualBuddy.keyOwner[indexPath.row].partNumber)
        }
        return cell
    }
    
    
}



class TwoInformationsTableViewCell: UITableViewCell {
    static let identifier = "TwoInformationsTableViewCell"
    
    @IBOutlet weak var FirstInformation: UILabel!
    @IBOutlet weak var SecondInformation: UILabel!
    
}
extension BuddyDetailViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @objc func showImagePicker() {
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        present(imagePicker,animated: true,completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            
            ContactPictureOutlet.image = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: UIImage.Orientation.up)
            ContactPictureOutlet.contentMode = .scaleAspectFit
            
            if let data = image.pngData() {
                let relativePath = info[UIImagePickerController.InfoKey.imageURL] as? URL
                let path = relativePath?.lastPathComponent
                let filename = localDocumentsURL!.appendingPathComponent(path!)
                try? data.write(to: filename)
                
                //                picturePath = relativePath
                try? database.write {
                    actualBuddy.contactPicture = path
                }
                
            }
            dismiss(animated: true, completion: nil)
            
        }
    }
    
}

extension BuddyDetailViewController:UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if(textView.text == "Enter Additional Informations here like E-Mail or phonenumber"){
            textView.text = ""
        }
    }
}

extension BuddyDetailViewController:UITextFieldDelegate{

    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        if (NiknameTextfield.text?.count ?? 0) < 1 {
            rightBarButtonItem.isEnabled = false
        } else {
            rightBarButtonItem.isEnabled = true
        }
    }
    
}

extension BuddyDetailViewController{
    func receiveKeyDataFromImportView(key: Data) {
        print("BuddyDetailViewController \(key)")
        if let buddy = loadBuddyWithCommKey(key: key){
       showStandardAlert(view: self, title: "Error", message: "This key is already asiged to " + String(buddy.nickname))
        }
        else{
          commKey = key
            showLocalNotification(identifier: "newKey", title: "key update", body: "\(actualBuddy.nickname)s Communication Key updated Please press safe for keep this key")
           
        }
        
    }
}
