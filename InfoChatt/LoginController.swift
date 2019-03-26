//
//  LoginController.swift
//  InfoChatt
//
//  Created by Unal Celik on 30.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import TextFieldEffects
import SVProgressHUD

class LoginController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var emailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var googleButton: UIView!
    @IBOutlet weak var faceButton: UIView!
    
    var delegate: FirstScreenController?
    
    // MARK: - Login - Register
    @IBAction func login(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Forms are invalid")
            return
        }
        
        SVProgressHUD.show()
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!)
                
                if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                        case .errorCodeInvalidEmail:
                            let alertController = UIAlertController(title: "Invalid E-mail", message: nil, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { (handler) in
                                return
                            }))
                            self.present(alertController, animated: true, completion: nil)
                        case .errorCodeWrongPassword:
                            let alertController = UIAlertController(title: "Wrong Password", message: nil, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { (handler) in
                                return
                            }))
                            self.present(alertController, animated: true, completion: nil)
                        case .errorCodeUserNotFound:
                            let alertController = UIAlertController(title: "User not found", message: nil, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { (handler) in
                                return
                            }))
                            self.present(alertController, animated: true, completion: nil)
                        default: return
                    }
                }
                
                SVProgressHUD.dismiss()
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
                return
            }
            
            // succesfully logged-in
            print("Giris yapan kullanıcı -> \(user?.uid)")
            
            // home screen'e bilgileri iletip gönder.
            
            FIRDatabase.database().reference().child("Users").child((user?.uid)!).updateChildValues(["connection": "online"])
            
            SVProgressHUD.dismiss()
            self.delegate?.checkIfUserLoggedIn()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRegister" {
            let dest = segue.destination as! RegisterController
            
            dest.baseController = self
        } 
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDel = UIApplication.shared.delegate as! AppDelegate
        appDel.loginScreenDelegate = self
        
        customiseTextFields()
        customiseButtons()
        hideKeyboardWhenTappedAround()
        
        addShadow(toView: loginButton)
        addShadow(toView: faceButton)
        addShadow(toView: googleButton)
    }
    
    // MARK: - Customization
    func customiseButtons() {
        faceButton.layer.cornerRadius = 6
        faceButton.clipsToBounds = true
        
        googleButton.layer.cornerRadius = 6
        googleButton.clipsToBounds = true
        
        loginButton.layer.cornerRadius = 6
        loginButton.clipsToBounds = true
    }
    
    func customiseTextFields(){
        emailTextField.layer.cornerRadius = 5
        emailTextField.clipsToBounds = true
        
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.clipsToBounds = true
    }
    
    override func addShadow(toView: UIView) {
        let shadowPath = UIBezierPath(rect: toView.bounds)
        toView.layer.masksToBounds = false
        toView.layer.shadowColor = UIColor.black.cgColor
        toView.layer.shadowOffset = CGSize(width: 0.2, height: 4.0)
        toView.layer.shadowOpacity = 0.20
        toView.layer.shadowPath = shadowPath.cgPath
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailTextField.endEditing(true)
        passwordTextField.endEditing(true)
        return true
    }
}

extension UIViewController {
    func addShadow(toView: UIView) {
        let shadowPath = UIBezierPath(rect: toView.bounds)
        toView.layer.masksToBounds = false
        toView.layer.shadowColor = UIColor.black.cgColor
        toView.layer.shadowOffset = CGSize(width: 0.2, height: 4.0)
        toView.layer.shadowOpacity = 0.20
        toView.layer.shadowPath = shadowPath.cgPath
    }
}
