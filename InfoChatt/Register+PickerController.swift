//
//  Register+PickerController.swift
//  InfoChatt
//
//  Created by Unal Celik on 6.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Foundation
import UIKit

extension RegisterController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBAction func profileImagePicker(_ sender: UITapGestureRecognizer) {
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
        
        self.isPicked = true
        self.profileImage.image = selectedImage
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
