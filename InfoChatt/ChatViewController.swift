//
//  ChatViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 22.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties
    var user: User? {
        didSet {
            if let name = user?.name {
                titleLabel.text = name
                navigationItem.titleView = titleLabel
            }
            
            fetchMessagesPerUser()
        }
    }
    
    @IBOutlet weak var messageCollectionView: UICollectionView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    @IBAction func dismissView(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Fetch Messages
    var messages = [Message]()
    
    func fetchMessagesPerUser() {
        guard let currentMail = FIRAuth.auth()?.currentUser?.email else { return }
        guard let partnerMail = user?.email else { return }
        
        let replacedCurrentMail = currentMail.replacingOccurrences(of: ".", with: "-")
        let replacedPartnerMail = partnerMail.replacingOccurrences(of: ".", with: "-")
        
        FIRDatabase.database().reference().child("iOSMessage").observe(.childAdded, with: { (snap) in
            if snap.key.contains(replacedPartnerMail) && snap.key.contains(replacedCurrentMail) {
                FIRDatabase.database().reference().child("iOSMessage").child(snap.key).observe(.childAdded, with: { (innerSnap) in
                    
                    if let dict = innerSnap.value as? [String: AnyObject] {
                        let message = Message()
                        message.setValuesForKeys(dict)
                        self.messages.append(message)
                        self.messages.sort(by: { (ms1, ms2) -> Bool in
                            return (ms1.time?.intValue)! < (ms2.time?.intValue)!        // En yeni en altta.
                        })
                    }
                    
                    DispatchQueue.main.async {
                        self.messageCollectionView.reloadData()
                    }
                })
            }
        }, withCancel: nil)
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        keyboardNotifications()
        
        customiseCollectionView()
        customizeTextField()
        customiseSendButton()
    }
    
    deinit {
        print("chat controller deallocated")
    }
    
    // MARK: - Customizations
    var sendButtonIsEnabled = false {
        didSet {
            if sendButtonIsEnabled {
                self.sendButton.isEnabled = true
                self.sendButton.setTitleColor(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), for: .normal)
            } else {
                self.sendButton.isEnabled = false
                self.sendButton.setTitleColor(#colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1), for: .normal)
            }
        }
    }
    
    func customiseCollectionView() {
        messageCollectionView.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        messageCollectionView.delegate = self
        messageCollectionView.dataSource = self
    }
    
    func customizeTextField() {
        messageTextField.delegate = self
        messageTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func customiseSendButton() {
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        sendButton.isEnabled = false
    }
    
    func handleSend() {
        let time = NSDate().timeIntervalSince1970
        let timeStamp = NSNumber(value: time)
        
        guard let toId = user?.id else { return }
        guard let fromId = FIRAuth.auth()?.currentUser?.uid else { return }
        
        guard let from = FIRAuth.auth()?.currentUser?.email?.replacingOccurrences(of: ".", with: "-") else { return }
        guard let to = user?.email?.replacingOccurrences(of: ".", with: "-") else { return }
        
        guard let message = messageTextField.text else { return }
        
        let values = ["message": message, "sender": fromId, "recipient": toId, "time": timeStamp] as [String : Any]
        
        FIRDatabase.database().reference().child("iOSMessage").child(from + "-" + to).childByAutoId().updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            // Values updated succesfully
            self.messageTextField.text = nil
            self.sendButtonIsEnabled = false
            
        }
    }
    
    
    // MARK: - TextField Delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    // textField ekrandan gittiğinde çalışır.
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // TextField içerisinde "done" basıldığında çalışır.
        handleSend()
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if self.messageTextField.text == "" {
            self.sendButtonIsEnabled = false
        } else {
            self.sendButtonIsEnabled = true
        }
    }
    
    // MARK: - CollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "chatCell", for: indexPath) as! ChatCollectionViewCell
        let message = messages[indexPath.item]
        
        cell.message = message
        
        cell.chatViewBubbleViewWidthConstraint.constant = estimateFrame(for: message.message!).width + 20
        
        setupCellBubble(cell: cell, message: message)
        
        return cell
    }
    
    private func setupCellBubble(cell: ChatCollectionViewCell, message: Message) {
        if message.sender == FIRAuth.auth()?.currentUser?.uid {
            // blue bubbleView
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
            cell.chatTextView.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            cell.partnerProfileImage.isHidden = true
            
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
        } else {
            // gray bubbleView
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            cell.chatTextView.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            
            cell.partnerProfileImage.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height = CGFloat()
        
        if let text = messages[indexPath.item].message {
            height = estimateFrame(for: text).height + 20 + 8 // + 12 sonradan aşağıya datelabel eklediğimiz için
        }

        return CGSize(width: view.frame.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func estimateFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 10000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.init(name: "Helvetica", size: 15)!], context: nil)
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
