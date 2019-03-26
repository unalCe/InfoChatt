//
//  AppDelegate.swift
//  InfoChatt
//
//  Created by Unal Celik on 30.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//
import UIKit
import Firebase
import GoogleSignIn
import FBSDKCoreKit
import SVProgressHUD
import ChameleonFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    var firstScreenDelegate: FirstScreenController?
    var loginScreenDelegate: LoginController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        SVProgressHUD.setBackgroundColor(.white)
        SVProgressHUD.setForegroundColor(UIColor(hex: "D83F34"))
        
        FIRApp.configure()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Google 
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        
        return true
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        SVProgressHUD.show()
        if let err = error {
            print("error occured", err)
            SVProgressHUD.dismiss()
            return
        }
        
        // succesfully logged in to Google
        print("successfuly logged in", user)
        
        guard let name = user.profile.name else { return }
        
        guard let email = user.profile.email else { return }
        
        guard let optionalUrl = user.profile.imageURL(withDimension: 100) else { return }
        
        let imageUrl = String(describing: optionalUrl)
        
        guard let idToken = user.authentication.idToken else { return }
        guard let accesToken = user.authentication.accessToken else { return }
        
        let credentials = FIRGoogleAuthProvider.credential(withIDToken: idToken, accessToken: accesToken)
        
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            if error != nil {
                print("sign in failed:", error!)
                SVProgressHUD.dismiss()
                return
            }
            
            // user succesfully signed in to Firebase
            print("succesfully signed in Google user with:", user?.uid ?? "google user.uid yok")
            
            
            let timeStamp = NSDate().timeIntervalSince1970
            let time = NSNumber(value: timeStamp)
            
            let values = ["name": name, "email": email, "profileImageUrl": imageUrl, "connection": "online", "createdAt": time] as [String : Any]
            
            FIRDatabase.database().reference().child("Users").child((user?.uid)!).updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    SVProgressHUD.dismiss()
                    return
                }
                
                // user succesfully added to database
                SVProgressHUD.dismiss()
                self.firstScreenDelegate?.checkIfUserLoggedIn()
                self.loginScreenDelegate?.dismiss(animated: true, completion: nil)
            })
        })
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                              annotation: [:])
        
        return GIDSignIn.sharedInstance().handle(url,
                                                    sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                    annotation: [:])
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if let id = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("Users").child(id).updateChildValues(["connection": "offline"])
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if let id = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("Users").child(id).updateChildValues(["connection": "online"])
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        if let id = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("Users").child(id).updateChildValues(["connection": "offline"])
        }
    }
}

