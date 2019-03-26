//
//  FacebookLoginController.swift
//  InfoChatt
//
//  Created by Unal Celik on 3.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Foundation
import FBSDKLoginKit
import FirebaseAuth
import Firebase
import SVProgressHUD

extension LoginController {
    
    @IBAction func loginWithFacebook(_ sender: UITapGestureRecognizer) {
        SVProgressHUD.show()
        FBSDKLoginManager().logIn(withReadPermissions: ["email","public_profile"], from: self) { (result, error) in
            if error != nil {
                print(error!)
                SVProgressHUD.dismiss()
                return
            }
            
            // succesfully logged in
            
            self.registerToFirebase()
        }
    }
    
    func registerToFirebase() {
        let accesToken = FBSDKAccessToken.current()
        guard let accesTokenString = accesToken?.tokenString else { return }
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: accesTokenString)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("error at FIRAuth.auth().signIn", error!)
                SVProgressHUD.dismiss()
                return
            }
            
            guard let userId = user?.uid else {
                return
            }
            
            // succesfully signed in
            print("succesfully signed in with facebook", user!)
            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "id, name, email"]).start { (connection, result, error) in
                if error != nil {
                    print(error!)
                    SVProgressHUD.dismiss()
                    return
                }
                
                let dict = result as! [String: AnyObject]
                
                guard let name = dict["name"] as? String else { return }
                
                guard let email = dict["email"] as? String else { return }
                
                guard let userID = dict["id"] as? String else { return }
                
                let timeStamp = NSDate().timeIntervalSince1970
                let time = NSNumber(value: timeStamp)
                
                let imageUrl = "https://graph.facebook.com/\(userID)/picture?type=large"
                let ref = FIRDatabase.database().reference().child("Users").child(userId)
                let values = ["name": name, "email": email, "profileImageUrl": imageUrl, "connection": "online", "createdAt": time] as [String : Any]
                
                ref.updateChildValues(values, withCompletionBlock: { (error, ref) in
                    if error != nil {
                        print(error!)
                        SVProgressHUD.dismiss()
                        return
                    }
                    
                    SVProgressHUD.dismiss()
                    self.delegate?.checkIfUserLoggedIn()
                    self.dismiss(animated: true, completion: nil)
                })
            }
        })
    }
}

/*
    Hazır olan FBSDKLoginButton'u kullansaydım delegate protocolünü ekleyip bu metodları uygulamam gerekirdi.
     
     
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("he çıktım he")
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        print("i'll login")
        return true
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print("qwqewqweasdli23123")
            return
        }
        
        print("at last.")
    }
*/
