//
//  FirstScreenController.swift
//  InfoChatt
//
//  Created by Unal Celik on 31.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import Spring
import GoogleSignIn

class FirstScreenController: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var logoView: SpringImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.firstScreenDelegate = self
        
        GIDSignIn.sharedInstance().uiDelegate = self
        animateOut()
    }
    
    func animateOut() {
        perform(#selector(animate), with: nil, afterDelay: 1)
    }
    
    func animate() {
        self.logoView.animation = "zoomOut"
        self.logoView.curve = "easeOut"
        self.logoView.duration = 1.5
        self.logoView.animate()

        perform(#selector(checkIfUserLoggedIn), with: nil, afterDelay: 0.5)
    }
    
    func openLoginScreen() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let Error {
            print(Error)
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginController") as! LoginController
        controller.delegate = self
        
        controller.modalTransitionStyle = .crossDissolve
        present(controller, animated: true, completion: nil)
    }
    
    func openMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "tabController") as! TabController
        controller.baseController = self
        
        controller.modalTransitionStyle = .crossDissolve
        present(controller, animated: true, completion: nil)
    }
    
    func checkIfUserLoggedIn() {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("Users").child(id).updateChildValues(["connection": "online"])
            perform(#selector(openMainScreen), with: nil, afterDelay: 0)
        } else {
            perform(#selector(openLoginScreen), with: nil, afterDelay: 0)
        }
    }
    
    func checkGoogleLogIn() {
        if (FIRAuth.auth()?.currentUser?.uid) != nil {
            perform(#selector(openMainScreen), with: nil, afterDelay: 0)
        } else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
}
