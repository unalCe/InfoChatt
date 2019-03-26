//
//  FriendsViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 20.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
import DZNEmptyDataSet

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Properties
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var friendsTableView: UITableView!

    var friends = [User]()
    var userID = String()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customiseTableView()
        setupEmptyDataSet()
        
        getFriends()
        
        navigationItem.titleView = titleLabel
    }
    
    func getFriends() {
        friends = []
        
        FIRDatabase.database().reference().child("Users").child(userID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendsDict = snapshot.value as? [String: AnyObject] {
                for friend in friendsDict as! [String: Int] {
                    if friend.value == 1 {
                        
                        FIRDatabase.database().reference().child("Users").child(friend.key).observeSingleEvent(of: .value, with: { (innerSnap) in
                            
                            let user = User()
                            
                            if let userDict = innerSnap.value as? [String: AnyObject] {
                                user.setValuesForKeys(userDict)
                                
                                user.id = friend.key
                                
                                self.friends.append(user)
                            }
                            
                            DispatchQueue.main.async {
                                self.friendsTableView.reloadData()
                            }
                        })
                    }
                }
            }
        })
    }
    
    // MARK: Customize & Setup

    func customiseTableView() {
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        friendsTableView.tableFooterView = UIView()
    }
    
    func setupEmptyDataSet() {
        friendsTableView.emptyDataSetSource = self
        friendsTableView.emptyDataSetDelegate = self
    }
    
    // MARK: DZNEmptyDataSet
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "Profile Avatar")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "You have no friends"
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "You can find friends in search section"
        
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
    
    // MARK: TableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendsTableView.dequeueReusableCell(withIdentifier: "friendsCell", for: indexPath) as! SearchTableViewCell
        
        cell.user = friends[indexPath.row]
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "friendProfilee" {
            let vc = segue.destination as! ProfileController
            if let indexPath = friendsTableView.indexPathForSelectedRow {
                let selectedRow = indexPath.row
                
                vc.profileUserID = friends[selectedRow].id!
                vc.isMyProfile = false
            }
        }
    }
    
}
