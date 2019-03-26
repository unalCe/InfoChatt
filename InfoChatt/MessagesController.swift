//
//  MessagesController.swift
//  InfoChatt
//
//  Created by Unal Celik on 30.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import ChameleonFramework
import Firebase
import SVProgressHUD
import DZNEmptyDataSet

var messagesControllerCount: Int = 0

class MessagesController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet var titleLabel: UILabel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesControllerCount += 1
        print("MessagesController = \(messagesControllerCount)")
        
        customiseTableView()
        customiseNavigationItem()
        
        fetchMessages()
    }
    
    deinit {
        messagesControllerCount -= 1
        print("MessagesController = \(messagesControllerCount)")
    }
    
    // MARK: - Customizations
    func customiseTableView() {
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        messagesTableView.tableFooterView = UIView()
    }
    
    func customiseNavigationItem() {
        self.navigationItem.titleView = titleLabel
    }
    
    // MARK: - DZNEmptyDataSet
    func setupEmptyDataSet() {
        messagesTableView.emptyDataSetSource = self
        messagesTableView.emptyDataSetDelegate = self
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "mail-inbox-empty")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "You have no messages"
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Inbox is empty"
        
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = NSLineBreakMode.byWordWrapping
        para.alignment = NSTextAlignment.center
        
        let attribs = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: FlatWhiteDark(),
            NSParagraphStyleAttributeName: para
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    // MARK: - Fetch Messages
    var messages = [Message]()
    var messagesDict = [String: Message]()
    
    func fetchMessages() {
        SVProgressHUD.show()
        
        guard let currentMail = FIRAuth.auth()?.currentUser?.email else { return }
        let replacedMail = currentMail.replacingOccurrences(of: ".", with: "-")
        
        FIRDatabase.database().reference().child("iOSMessage").observe(.childAdded, with: { (snapshot) in
            if snapshot.key.contains(replacedMail) {
                
                for innerSnap in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    
                    if let dict = innerSnap.value as? [String: AnyObject] {
                        
                        let message = Message()
                        message.setValuesForKeys(dict)
                        
                        if let recipient = message.chatPartnerID() {
                            if let timeVal = self.messagesDict[recipient]?.time?.intValue {
                                if (message.time?.intValue)! > timeVal {
                                    self.messagesDict[recipient] = message
                                }
                            } else {
                                self.messagesDict[recipient] = message
                            }
                           
                            self.messages = Array(self.messagesDict.values)
                            
                            self.messages.sort(by: { (message1, message2) -> Bool in
                                return (message1.time?.intValue)! > (message2.time?.intValue)!
                            })
                        }
                        
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadData), userInfo: nil, repeats: false)
                    }
                }
            } else {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadData), userInfo: nil, repeats: false)
            }
        })
    }
    
    // DispatchQueue'de firebase metodu içerisinde birden fazla kez çağırıldığı için bazen buglar oluşabiliyor.
    // Bunu düzeltmek için bir timer yardımı ile metodu 0.1 saniye sonra çalıştıracağız.
    
    var timer: Timer?
    
    func handleReloadData() {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            self.setupEmptyDataSet()
            self.messagesTableView.reloadData()
        }
    }
    
    
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = messagesTableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as! MessageTableViewCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chat" {
            let indexPath = self.messagesTableView.indexPathForSelectedRow!
            let selectedRow = indexPath.row
            
            let message = messages[selectedRow]
            
            guard let partner = message.chatPartnerID() else { return }
            
            FIRDatabase.database().reference().child("Users").child(partner).observeSingleEvent(of: .value, with: { (snap) in
                guard let dict = snap.value as? [String: AnyObject] else { return }
                
                let user = User()
                user.id = partner
                user.setValuesForKeys(dict)
                
                let destination = segue.destination as! UINavigationController
                let vc = destination.viewControllers[0] as! ChatViewController
                vc.user = user
                
            }, withCancel: nil)
        }
    }
}
