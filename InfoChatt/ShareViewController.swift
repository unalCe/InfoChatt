//
//  ShareViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 6.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

var shareControllerCount = 0

class ShareViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var resimSecView: UIView!
    @IBOutlet weak var descriptionBackView: UIView!
    
    @IBOutlet weak var descriptionTextField: UITextField!
    
    
    deinit {
        shareControllerCount -= 1
        print(shareControllerCount)
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shareControllerCount += 1
        print("ShareController = \(shareControllerCount)")
        
        getUserInfo()
        customiseViews()
        customiseTextField()
        keyboardNotifications()
        hideKeyboardWhenTappedAround()
    }
    
    // MARK: - Customise
    func customiseViews() {
        sendButton.layer.cornerRadius = 6
        sendButton.clipsToBounds = true
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        addShadow(toView: sendButton)
        
        resimSecView.layer.cornerRadius = 6
        resimSecView.clipsToBounds = true
        
        descriptionBackView.layer.cornerRadius = 6
        descriptionBackView.clipsToBounds = true
    }
    
    func customiseTextField() {
        descriptionTextField.autocorrectionType = .no
        descriptionTextField.autocapitalizationType = .sentences
    }
    
    // MARK: - Get Image
    @IBAction func pickImageTapGesture(_ sender: UITapGestureRecognizer) {
        let selectAlert = UIAlertController(title: "Pick a photo", message: nil, preferredStyle: .actionSheet)
        
        selectAlert.addAction(UIAlertAction(title: "Library", style: .default, handler: { (action) in
            self.handleLibrary()
        }))
        
        selectAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.handleCamera()
        }))
            
        selectAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            return
        }))
        
        self.present(selectAlert, animated: true, completion: nil)
    }
    
    func handleCamera() {
        /*
          Handling camera is not working in simulator

         let picker = UIImagePickerController()
         picker.delegate = self
         picker.allowsEditing = true
         picker.sourceType = .camera
         
         present(picker, animated: true, completion: nil)
         */
        
        let alert = UIAlertController(title: "Kamera yok", message: "Simulatorde kamera yok", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func handleLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.modalPresentationStyle = .overFullScreen
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBOutlet weak var picview: UIImageView!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImage: UIImage?
    
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = editedImage
        } else {
            if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
                selectedImage = originalImage
            }
        }
        
        self.picview.contentMode = .scaleToFill
        self.picview.image = selectedImage

        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    // MARK: - Get UserInfo & Send
    var profileImageUrl: String?
    var name: String?
    
    func getUserInfo() {
        guard let currentUser = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let userRef = FIRDatabase.database().reference().child("Users").child(currentUser)
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String: AnyObject] else { return }
            self.profileImageUrl = dict["profileImageUrl"] as? String
            self.name = dict["name"] as? String
        }, withCancel: nil)
    }
    
    func handleSend() {
        SVProgressHUD.show()
        
        guard let currentUser = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let timeInterval = NSDate().timeIntervalSince1970
        let time: NSNumber = NSNumber(value: timeInterval)
        
        let like: NSNumber = 0
        let uniqueName = NSUUID().uuidString
        
        // Storing image in Storage
        
        guard let image = self.picview.image else {
            SVProgressHUD.dismiss()
            return
        }
        
        let storageRef = FIRStorage.storage().reference().child("Images").child(uniqueName)
        if let uploadData = UIImagePNGRepresentation(image) {
            storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error!)
                    SVProgressHUD.dismiss()
                    return
                }
                
                // Image Succesfully Uploaded
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    // Contente geri çevir
                    
                    let ref = FIRDatabase.database().reference().child("Content").child(currentUser).child(uniqueName)
                    let values = ["userID": currentUser, "contentId": uniqueName, "imageUrl": imageUrl, "cDescription": self.descriptionTextField.text!, "profileImageUrl": self.profileImageUrl!, "name": self.name!, "time": time, "like": like] as [String : Any]
                    
                    ref.updateChildValues(values, withCompletionBlock: { (error, ref) in
                        if error != nil {
                            print(error!)
                            SVProgressHUD.dismiss()
                            return
                        }
                        // values succesfully updated
                        
                        SVProgressHUD.dismiss()
                        self.navigationController!.popViewController(animated: true)
                    })
                }
            })
        }
    }
    
    // MARK: - Handle Keyboard Behavior
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 64 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 64 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
}
