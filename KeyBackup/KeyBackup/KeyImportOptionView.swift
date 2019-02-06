//
//  QRscanning.swift
//  encryptedMultipeer
//
//  Created by Stefan Haßferter on 15.08.18.
//  Copyright © 2018 Stefan Haßferter. All rights reserved.
//
import UIKit
import Foundation
import AVFoundation

protocol KeyImportOptionViewDelegate {
    func receiveKeyDataFromImportView(key:Data)
}

class KeyImportOptionView:UIViewController {
    var avCaptureSession:AVCaptureSession!
    var cameraPreViewContainerView:UIView!
    var imagepicker = UIImagePickerController()
    var delegate:KeyImportOptionViewDelegate!
    
    
    override func viewDidLoad() {
        print ("KeyImportOptionController loaded")
        view.backgroundColor = UIColor.clear
//        generateImportOptionsView(update: true)
    }

    
    
    func scanQRCode(cameraPreview:UIImageView)  {
        
        if(avCaptureSession==nil){
            avCaptureSession = AVCaptureSession()
            guard let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                print ("no camera")
                return
            }
            
            guard let avCaptureInput = try? AVCaptureDeviceInput(device: avCaptureDevice) else {
                print("Faild to init camera")
                return
            }
            
            let avCaptureMetadataOutput = AVCaptureMetadataOutput()
            
            avCaptureMetadataOutput.setMetadataObjectsDelegate(self,queue: DispatchQueue.main)
            
            avCaptureSession.addInput(avCaptureInput)
            avCaptureSession.addOutput(avCaptureMetadataOutput)
            
            avCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
            
            avCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            avCaptureVideoPreviewLayer.frame = cameraPreview.bounds
            cameraPreview.isHidden = false
            
            cameraPreview.layer.addSublayer(avCaptureVideoPreviewLayer)
            
            
            //Green searching frame
            let  qrCodeFrameView = UIView()
            qrCodeFrameView.frame.size.width = cameraPreview.frame.size.width*0.7
            qrCodeFrameView.frame.size.height = cameraPreview.frame.size.height*0.7
            qrCodeFrameView.frame.origin.x = (cameraPreview.frame.minX)+(cameraPreview.frame.size.width - qrCodeFrameView.frame.size.width)/2
            qrCodeFrameView.frame.origin.y = ((cameraPreview.frame.size.height -  qrCodeFrameView.frame.size.height)/2)//(cameraPreview.frame.minY)+
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            cameraPreview.addSubview(qrCodeFrameView)
            cameraPreview.bringSubviewToFront(qrCodeFrameView)
            
        }
        if(avCaptureSession.isRunning==true){
            avCaptureSession.stopRunning()
            cameraPreview.isHidden = true
        }
        else if(avCaptureSession.isRunning == false) {
            avCaptureSession.startRunning()
            cameraPreview.isHidden = false
        }
    }
    
    func generateQRScanningScreen()
    {
        self.cameraPreViewContainerView = UIView()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
        let cameraPreview = UIImageView()
        cameraPreview.layer.borderColor = UIColor.gray.cgColor
        cameraPreview.layer.borderWidth = 2
        cameraPreview.layer.cornerRadius = 8
        cameraPreview.layer.shadowColor = UIColor.gray.cgColor
        cameraPreview.frame = CGRect(x: 0, y: (self.view.frame.height/2) - (self.view.frame.width/2) ,
                                     width: self.view.frame.width, height: self.view.frame.width)
        
        
        self.cameraPreViewContainerView.addSubview(blurEffectView)
        self.cameraPreViewContainerView.addSubview(cameraPreview)
        
        let textLabel = UILabel(frame:  CGRect(x: self.view.frame.minX, y: cameraPreview.frame.minY - 80 , width: self.view.frame.width, height: 50))
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.boldSystemFont(ofSize: 20)
        textLabel.text = "Scan your buddy's \n personal QR-Code"
        textLabel.textAlignment = .center
        
        
        self.cameraPreViewContainerView.addSubview(textLabel)
        self.view.addSubview(self.cameraPreViewContainerView)
        
        let button = UIButton(frame: CGRect(x: self.view.frame.minX, y: cameraPreview.frame.maxY + 10, width: self.view.frame.width, height: 50))
        button.backgroundColor = UIColor.lightGray
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 8.0
    }
    
    
}

extension KeyImportOptionView: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //         Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            print( "No QR code is detected")
            avCaptureSession.stopRunning()
            return
        }
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        //if metadata is from type QR
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            
            
            if metadataObj.stringValue != nil {
                print(metadataObj.stringValue!)
                
                
                if let publicKeyIncomingdata = Data(base64Encoded: metadataObj.stringValue!) {
                    print(publicKeyIncomingdata as NSData)
                    //Show Datastring in textfield
                    self.dismiss(animated: true) {
                        self.delegate.receiveKeyDataFromImportView(key: publicKeyIncomingdata)
                    }
                }
                cameraPreViewContainerView.isHidden = true
                avCaptureSession.stopRunning()
            }
        }
        
    }
    
    func finishScreen(key:Data) {
        if cameraPreViewContainerView != nil {
            cameraPreViewContainerView.removeFromSuperview()
        }
        imagepicker.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true)
        self.removeFromParent()
        delegate.receiveKeyDataFromImportView(key: key)
    }
    
}


extension KeyImportOptionView : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //extract Infos form saved QR-Image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            guard let data = parseImage(image: image) else {
                dismiss(animated: true, completion: nil)
                return
            }
            print( "\(#function) \(data as NSData)")
            
            finishScreen(key: data)
        }
        
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        self.dismiss(animated: true)
    }
    
    func openImagePicker(){
        imagepicker.sourceType = .photoLibrary
        imagepicker.allowsEditing = true
        present(imagepicker,animated: true,completion: nil)
    }
    
}




extension KeyImportOptionView {
    
    func generateImportOptionsView() {
        
        let alert = UIAlertController(title: "Choose an option", message: "Please choose one of the options to import a new communication key", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Scan Public Key", style: .default, handler: { [weak alert] (_) in
            
            self.cameraPreViewContainerView = UIView()
            
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            
            let cameraPreview = UIImageView()
            cameraPreview.layer.borderColor = UIColor.gray.cgColor
            cameraPreview.layer.borderWidth = 2
            cameraPreview.layer.cornerRadius = 8
            cameraPreview.layer.shadowColor = UIColor.gray.cgColor
            cameraPreview.frame = CGRect(x: 0, y: (self.view.frame.height/2) - (self.view.frame.width/2) ,
                                         width: self.view.frame.width, height: self.view.frame.width)
            
            
            self.cameraPreViewContainerView.addSubview(blurEffectView)
            self.cameraPreViewContainerView.addSubview(cameraPreview)
            //
            let textLabel = UILabel(frame:  CGRect(x: self.view.frame.minX, y: cameraPreview.frame.minY - 80 , width: self.view.frame.width, height: 50))
            textLabel.numberOfLines = 0
            textLabel.font = UIFont.boldSystemFont(ofSize: 20)
            textLabel.text = "Scan your buddy's \n personal QR-Code"
            textLabel.textAlignment = .center
            
            
            self.cameraPreViewContainerView.addSubview(textLabel)
            self.view.addSubview(self.cameraPreViewContainerView)
            
            let button = UIButton(frame: CGRect(x: self.view.frame.minX, y: cameraPreview.frame.maxY + 10, width: self.view.frame.width, height: 50))
            button.backgroundColor = UIColor.lightGray
            button.setTitle("Cancel", for: .normal)
            button.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
            button.layer.cornerRadius = 8.0
            
            self.view.addSubview(button)
            
            self.scanQRCode(cameraPreview: cameraPreview)
            
            }
            )
        )
        
        alert.addAction(UIAlertAction(title: "Import Public Key", style: .default, handler: { [weak alert] (_) in
            self.imagepicker.delegate = self
            self.openImagePicker()
            }
            )
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
            self.dismiss(animated: true, completion: nil)
            }
            )
        )
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.modalPresentationStyle = .overCurrentContext
        self.present(alert, animated: true)
    }
    
    @objc func cancelButtonPressed(sender: UIButton!) {
        cameraPreViewContainerView.removeFromSuperview()
        sender.removeFromSuperview()
        avCaptureSession.stopRunning()
        cameraPreViewContainerView = nil
        avCaptureSession = nil
        self.dismiss(animated: true)
    }
    
}


//MARK: - Global functions
func generateQRCode(from string: String) -> UIImage? {
    print(string.count)
    let ciContext = CIContext()
    let data = string.data(using: .utf8)
    
    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let upScaledImage = filter.outputImage?.transformed(by: transform)
        
        let cgImage = ciContext.createCGImage(upScaledImage!,
                                              from: upScaledImage!.extent)
        let qrcodeImage = UIImage(cgImage: cgImage!)
        return qrcodeImage
    }
    return nil
}


func parseImage(image:UIImage?)-> Data? {
    
    guard image != nil else {
        return nil
    }
    let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
    
    let ciImage:CIImage=CIImage(image:image!)!
    
    let features=detector.features(in: ciImage)
    
    for feature in features as! [CIQRCodeFeature] {
        print(feature.messageString!)
        if let publicKeyIncomingdata = Data(base64Encoded: feature.messageString!) {
            //                parseQRCode(readedData: publicKeyIncomingdata)
            return publicKeyIncomingdata
        }
        
    }
    
    return nil
}
