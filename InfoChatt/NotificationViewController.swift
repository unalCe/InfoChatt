//
//  NotificationViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 18.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Profile controller, notification(0 - 1 - 2) ile uyuşan userleri buraya gönderir. Aynı zamanda bildirim işareti çıkarır( kırmızı yuvarlak içinde sayı). Burada biriken notificatedUserler tableView'i doldurur. Cell classı içinde bu userlerin de friends durumuna göre arkadaşlığı değerlendirirlir. Ona göre buton fonksiyonu belirlenir.
    
    var baseController: ProfileController?
    
    @IBOutlet weak var notificationsTableView: UITableView!
    @IBOutlet weak var friendRequestHeader: UIView!

    @IBOutlet weak var closeButton: UIButton!

    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: ViewLifeCycle
    
    override func viewWillAppear(_ animated: Bool) {
        baseController?.notificationCountLabel.text = nil
        baseController?.notificationBubbleView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // getNotifications()
        
        customiseHeaderAndButton()
        customiseTableView()
        
        setupEmptyDataSet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.dismiss(animated: true, completion: nil)
        baseController?.getReadyForDismissingNotificationView()
    }

    
    // MARK: Customization
    
    func customiseHeaderAndButton() {
        friendRequestHeader.layer.cornerRadius = 6
        friendRequestHeader.clipsToBounds = true
        
        closeButton.backgroundColor = .clear
        closeButton.setImage(#imageLiteral(resourceName: "error"), for: .normal)
    }
    
    func customiseTableView() {
        notificationsTableView.contentInset = UIEdgeInsetsMake(12, 0, 4, 0)
        notificationsTableView.layer.cornerRadius = 6
        notificationsTableView.clipsToBounds = true
        notificationsTableView.delegate = self
        notificationsTableView.dataSource = self
        notificationsTableView.tableFooterView = UIView()
    }
    
    func deleteRow(at indexPath: IndexPath) {
        self.notificatingUsers.remove(at: indexPath.row)
        self.notificationsTableView.deleteRows(at: [indexPath], with: .automatic)
        self.notificationsTableView.reloadData()
    }
    
    // MARK: DZN EmptyDataSet
    
    func setupEmptyDataSet() {
        self.notificationsTableView.emptyDataSetSource = self
        self.notificationsTableView.emptyDataSetDelegate = self
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "instagram")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = String()
        
        text = "You have no friend requests"
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: UIColor.flatBlackDark
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = String()
        
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = NSLineBreakMode.byWordWrapping
        para.alignment = NSTextAlignment.center
        
        let attribs = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.flatGray,
            NSParagraphStyleAttributeName: para
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    
    // MARK: Get notifs
    
    var notificatedUsedIDs = [String: Int]()
    var notificatingUsers = [User]()
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificatingUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = notificationsTableView.dequeueReusableCell(withIdentifier: "notifCell", for: indexPath) as! NotificationTableViewCell
        
        cell.baseController = self
        cell.user = self.notificatingUsers[indexPath.row]
        cell.indexPath = indexPath
        
        return cell
    }
}
