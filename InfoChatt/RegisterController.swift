//
//  RegisterController.swift
//  InfoChatt
//
//  Created by Unal Celik on 31.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import SVProgressHUD

class RegisterController: UIViewController, UITextFieldDelegate {
    // MARK: - Properties
    @IBOutlet weak var profileImageView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTextField: YoshikoTextField!
    @IBOutlet weak var mailTextField: YoshikoTextField!
    @IBOutlet weak var passwordTextField: YoshikoTextField!
    @IBOutlet weak var passwordAgainTextField: YoshikoTextField!
    @IBOutlet weak var errorView: UIView!
    
    @IBOutlet weak var ppTrailingConstraint: NSLayoutConstraint!            // Resim picklendiğinde bu constraintleri
    @IBOutlet weak var ppLeadingConstraint: NSLayoutConstraint!             // sıfırlamayı unutma
    @IBOutlet weak var ppBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var ppTopConstraint: NSLayoutConstraint!
    
    var isPicked = false {
        didSet {
            if isPicked {
                ppTrailingConstraint.constant = 0
                ppLeadingConstraint.constant = 0
                ppBotConstraint.constant = 0
                ppTopConstraint.constant = 0
            } else {
                ppTrailingConstraint.constant = 15
                ppLeadingConstraint.constant = 15
                ppBotConstraint.constant = 15
                ppTopConstraint.constant = 15
            }
        }
    }
    
    var isInUse = false {
        didSet {
            if isInUse {
                errorView.isHidden = false
            } else {
                errorView.isHidden = true
            }
        }
    }
    
    var baseController: LoginController?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        customiseProfileImage()
        customiseTextFields()
        customiseRegButton()
        
        hideKeyboardWhenTappedAround()
        keyboardNotifications()
        
        isInUse = false
        isActive = false
    }
    
    // MARK: - Customizations
    func customiseRegButton() {
        registerButton.layer.cornerRadius = 6
        registerButton.clipsToBounds = true
        addShadow(toView: registerButton)
    }
    
    func customiseProfileImage() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
    }
    
    func customiseTextFields() {
        mailTextField.addTarget(self, action: #selector(textFieldDidEnd), for: .editingDidEnd)
        mailTextField.addTarget(self, action: #selector(textFieldDidBegin), for: .editingDidBegin)
        
        nameTextField.layer.cornerRadius = 5
        nameTextField.clipsToBounds = true
        
        mailTextField.layer.cornerRadius = 5
        mailTextField.clipsToBounds = true
        
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.clipsToBounds = true
        
        passwordAgainTextField.layer.cornerRadius = 5
        passwordAgainTextField.clipsToBounds = true
    }
    
    override func addShadow(toView: UIView) {
        let shadowPath = UIBezierPath(rect: toView.bounds)
        toView.layer.masksToBounds = false
        toView.layer.shadowColor = UIColor.black.cgColor
        toView.layer.shadowOffset = CGSize(width: 0.2, height: 4.0)
        toView.layer.shadowOpacity = 0.20
        toView.layer.shadowPath = shadowPath.cgPath
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Handle Register
    @IBOutlet weak var registerButton: UIButton!
    
    var isActive = false {
        didSet {
            if isActive {
                self.registerButton.backgroundColor = UIColor(hex: "D83F34")
                self.registerButton.isEnabled = true
            } else {
                self.registerButton.backgroundColor = UIColor.init(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
                self.registerButton.isEnabled = false
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        SVProgressHUD.show()
        guard let email = mailTextField.text, let name = nameTextField.text, let password = passwordTextField.text else {
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
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
                    case .errorCodeEmailAlreadyInUse:
                        let alertController = UIAlertController(title: "E-mail already in use", message: nil, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title:"Ok", style: .default, handler: { (handler) in
                            return
                        }))
                        self.present(alertController, animated: true, completion: nil)
                    default: return
                    }
                }
                SVProgressHUD.dismiss()
                return
            }
            
            // succesfully created user
            
            guard let id = user?.uid else {
                return
            }
            
            // handle image storage
            
            let uniqueImageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("iOS").child("\(uniqueImageName).png")
            
            if let uploadData = UIImagePNGRepresentation(self.profileImage.image!) {
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print(error!)
                        SVProgressHUD.dismiss()
                        return
                    }
                    
                    // image succesfully uploaded
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        
                        // add properties to database
                        
                        let timeInterval = NSDate().timeIntervalSince1970
                        let createdTime = NSNumber(value: timeInterval)
                        
                        let ref = FIRDatabase.database().reference().child("Users").child(id)
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl, "connection": "online", "createdAt": createdTime] as [String : Any]
                        
                        ref.updateChildValues(values, withCompletionBlock: { (error, ref) in
                            if error != nil {
                                print(error!)
                                SVProgressHUD.dismiss()
                                return
                            }
                            
                            SVProgressHUD.dismiss()
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
                                self.baseController?.delegate?.checkIfUserLoggedIn()
                            })
                        })
                    }
                })
            }
        })
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        mailTextField.endEditing(true)
        passwordTextField.endEditing(true)
        passwordAgainTextField.endEditing(true)
        nameTextField.endEditing(true)
        return true
    }
    
    func textFieldDidEnd() {
        FIRDatabase.database().reference().child("Users").observe(.childAdded, with: { (snapshot) in
        
            if self.isInUse {
                return
            }
            
            if let dict = snapshot.value as? [String: AnyObject] {
                if let mail = dict["email"] as? String {
                    if mail == self.mailTextField.text {
                        self.isInUse = true
                        self.isActive = false
                    } else {
                        self.isInUse = false
                        self.isActive = true
                    }
                }
            }
        }, withCancel: nil)
    }
    
    func textFieldDidBegin() {
        self.isInUse = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if passwordTextField.text == passwordAgainTextField.text {
            if (mailTextField.text?.isNotEmpty)! && (nameTextField.text?.isNotEmpty)! && (passwordAgainTextField.text?.isNotEmpty)! && (passwordTextField.text?.isNotEmpty)! {
                isActive = true
            } else {
                isActive = false
            }
            passwordTextField.backgroundColor = .clear
            passwordAgainTextField.backgroundColor = .clear
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordTextField.backgroundColor = UIColor.init(red: 255/255, green: 61/255, blue: 62/255, alpha: 1)
                self.passwordAgainTextField.backgroundColor = UIColor.init(red: 255/255, green: 61/255, blue: 62/255, alpha: 1)
            }, completion: { (true) in
                self.isActive = false
            })
        }
    }
    
    // MARK: - Keyboard Behavior
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            //print(self.passwordTextField.frame.origin.y) // StackView'in başlangıç y sini veriyor aslında.
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
