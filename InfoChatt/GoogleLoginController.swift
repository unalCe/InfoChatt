//
//  GoogleLoginController.swift
//  InfoChatt
//
//  Created by Unal Celik on 2.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Firebase
import GoogleSignIn
import UIKit

extension LoginController: GIDSignInUIDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("LOGIN CONTROLLER APPEARED. CURRENT USER:", FIRAuth.auth()?.currentUser?.uid ?? "NONE")
    }
    
    @IBAction func loginWithGoogle(_ sender: UITapGestureRecognizer) {
        self.delegate?.checkGoogleLogIn()
    }
}
