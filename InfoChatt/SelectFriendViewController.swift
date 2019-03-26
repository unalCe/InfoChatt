//
//  SelectFriendViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 22.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet
import ChameleonFramework

class SelectFriendViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {

    // MARK: - Properties
    
    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet var titleLabel: UILabel!
    
    // MARK: - ViewLifeCycle
    override func viewWillAppear(_ animated: Bool) {
        fetchFriends()
        navigationItem.titleView = titleLabel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        customiseTableView()
        handleEmptyDataSet()
    }
    
    // MARK: - Customize & Setup
    func customiseTableView() {
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        friendsTableView.tableFooterView = UIView()
    }
    
    func setupEmptyDataSet() {
        friendsTableView.emptyDataSetSource = self
        friendsTableView.emptyDataSetDelegate = self
        friendsTableView.reloadData()
    }
    
    func handleEmptyDataSet() {
        perform(#selector(setupEmptyDataSet), with: nil, afterDelay: 0.2)
    }
    
    // MARK: - DZNEmptyDataSet
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
    
    // MARK: - Fetch Users
    var friends = [User]()
    
    func fetchFriends() {
        friends = []
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in

            if let dict = snapshot.value as? [String: AnyObject] {
                for friend in dict {

                    if friend.value as? Int == 1 {
                        
                        FIRDatabase.database().reference().child("Users").child(friend.key).observe(.value, with: { (innerSnap) in
                            
                            print(innerSnap)
                            
                            if let userDict = innerSnap.value as? [String: AnyObject] {
                                let user = User()
                                
                                user.setValuesForKeys(userDict)
                                user.id = friend.key
                                
                                // değişiklik olduğunda (online-ofline) aynı kişiyi tekrar listeye ekliyor ve birisi online birisi offliine olacak şekilde 2 tane kişi gözüküyor.
                                // Bunu engellemek için daha önce o id ile friends içerisinde olan kişiyi filtreledik.
                                
                                self.friends = self.friends.filter { $0.id != friend.key }
                                
                                self.friends.append(user)
                            }
                            
                            DispatchQueue.main.async {
                                self.friendsTableView.reloadData()
                            }
                        }, withCancel: nil)
                    }
                }
            }
        }, withCancel: nil)
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendsTableView.dequeueReusableCell(withIdentifier: "friendsCell", for: indexPath) as! FriendsTableViewCell
        
        cell.user = friends[indexPath.row]
        
        return cell
    }
    
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "friendChat" {
            let destination = segue.destination as! UINavigationController
            let vc = destination.viewControllers[0] as! ChatViewController
            let index = friendsTableView.indexPathForSelectedRow!
            
            vc.user = self.friends[index.row]
        }
    }
}
