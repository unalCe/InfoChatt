//
//  EditProfileImageViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 27.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class EditProfileImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!

    var isMyProfile = Bool()
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        customiseEditBarButtonItem()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
    }
    
    // MARK: - Customizations
    func customiseEditBarButtonItem() {
        if isMyProfile {
            //let editBarButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(profileImagePicker(_:)))
            
            let editBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "crop-button-1"), style: .plain, target: self, action: #selector(profileImagePicker(_:)))
            
            navigationItem.rightBarButtonItem = editBarButton
        }
    }
    
    // MARK: - Image Picker
    func profileImagePicker(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = editedImage
        } else {
            if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
                selectedImage = originalImage
            }
        }
        
        self.profileImageView.image = selectedImage
        self.saveButton.isHidden = false
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Save & Exit
    @IBAction func saveAndExit(_ sender: Any) {
        SVProgressHUD.show()
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let uniqueName = NSUUID().uuidString
        let storageRef = FIRStorage.storage().reference().child("iOS").child("\(uniqueName).png")
        
        if let uploadedData = UIImagePNGRepresentation(self.profileImageView.image!) {
            storageRef.put(uploadedData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                // image succesfully uploaded.
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    FIRDatabase.database().reference().child("Users").child(currentID).child("profileImageUrl").setValue(imageUrl)
                    
                    FIRDatabase.database().reference().child("Content").child(currentID).observe(.childAdded, with: { (snap) in
                        FIRDatabase.database().reference().child("Content").child(currentID).child(snap.key).child("profileImageUrl").setValue(imageUrl)
                        
                    }, withCancel: nil)
                    
                    SVProgressHUD.dismiss()
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
}
