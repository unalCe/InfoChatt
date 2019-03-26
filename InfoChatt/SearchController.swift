//
//  SearchController.swift
//  InfoChatt
//
//  Created by Unal Celik on 10.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import DZNEmptyDataSet
import ChameleonFramework

enum searchBarSelectedScope: Int {
    case Suggested = 0
    case Friends
}

var searchControllerCount = 0

class SearchController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITextFieldDelegate {

    // MARK: - Properties
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet var titleLabel: UILabel!
    var searchBar: UISearchBar!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        searchControllerCount += 1
        print("SearchController = \(searchControllerCount)")
        
        
        fetchSuggestedUsers()
        getFriends()
        hideKeyboardWhenTappedAround()
        setupSearchBar()
        setupNavBarTitle()
        customiseTableView()
    }
    
    // MARK: - DZNEmptyDataSet
    func setupEmptyDataSet() {
        searchTableView.emptyDataSetSource = self
        searchTableView.emptyDataSetDelegate = self
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        var image = UIImage()
        
        if searchBar.selectedScopeButtonIndex == 1 {
            image = #imageLiteral(resourceName: "Profile Avatar")
        } else {
            image = #imageLiteral(resourceName: "Profile Avatar")
        }
        return image
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = String()
        
        if searchBar.selectedScopeButtonIndex == 1 {
            text = "You have no friends"
            if (searchBar.text?.isNotEmpty)! {
                text = "There is no matched friends"
            }
        } else {
            text = "Start typing to find some friends"
            if (searchBar.text?.isNotEmpty)! {
                text = "There is no matched user"
            }
        }
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = String()

        if searchBar.selectedScopeButtonIndex == 1 {
            text = "You can find some in search section"
            if (searchBar.text?.isNotEmpty)! {
                text = ""
            }
        }
        
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
    
    // MARK: - Customise & Setup
    func setupNavBarTitle() {
        self.navigationItem.titleView = titleLabel
    }
    
    func customiseTableView() {
        searchTableView.delegate = self
        searchTableView.dataSource = self
    
        searchTableView.tableFooterView = UIView()
    }
    
    func setupSearchBar() {
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 70))
        searchBar.barTintColor = #colorLiteral(red: 0.9589233994, green: 0.3153640628, blue: 0.3120325208, alpha: 1)
        searchBar.delegate = self
        searchBar.showsScopeBar = true
        searchBar.scopeButtonTitles = ["Suggested", "Friends"]
        
        self.searchTableView.tableHeaderView = searchBar
    }

    // MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filterByScope(index: searchBar.selectedScopeButtonIndex)
        }
        
        if searchBar.selectedScopeButtonIndex == 1 {
            searchFriends(for: searchText)
        } else {
            search(for: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterByScope(index: searchBar.selectedScopeButtonIndex)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterByScope(index: searchBar.selectedScopeButtonIndex)
    }
    
    func filterByScope(index: Int) {
        switch index {
        case searchBarSelectedScope.Friends.rawValue:
            getFriends()
            self.setupEmptyDataSet()
        case searchBarSelectedScope.Suggested.rawValue:
            fetchSuggestedUsers()
        default:
            return
        }
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    // MARK: - Search Users
    var users = [User]()
    
    func search(for name: String) {
        SVProgressHUD.show()
        users = []
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Users").observe(.childAdded, with: { (snap) in
            
            if let userDict = snap.value as? [String: AnyObject] {
                if let userName = userDict["name"] as? String {
                    if userName.contains(name) {
                        let user = User()
                        
                        user.setValuesForKeys(userDict)
                        user.id = snap.key
                        
                        if user.id != currentID {
                            self.users.append(user)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.searchTableView.reloadData()
            }
        }, withCancel: nil)
    }
    
    // MARK: - Fetch Suggested Users
    
    func fetchSuggestedUsers() {
        SVProgressHUD.show()
        users = []
        
        FIRDatabase.database().reference().child("Users").observe( .childAdded, with: {
            (snapshot) in
            
            var hasMutualFriend = false
            
            guard let dict = snapshot.value as? [String: AnyObject] else { return }
            
            if let userFriend = dict["friends"] as? [String: AnyObject] {
                for friend in userFriend {
                    if friend.value as? Int == 1 {
                        
                        for myFriend in self.friends {
                            if myFriend.id == friend.key {
                                hasMutualFriend = true
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.addToUsers(mutual: hasMutualFriend, userDict: dict, userID: snapshot.key)
                
                self.users.sort(by: { (user1, user2) -> Bool in
                    return (user1.name)! < (user2.name)!
                })
                
                SVProgressHUD.dismiss()
                self.setupEmptyDataSet()
            }
        }, withCancel: nil)
    }
    
    func addToUsers(mutual: Bool, userDict: [String: AnyObject], userID: String) {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        if mutual {
            let user = User()
            user.setValuesForKeys(userDict)
            user.id = userID
            
            if currentID != userID {
                users.append(user)
            }
            
            self.searchTableView.reloadData()
        }
    }
    
    
    // MARK: - Fetch Friends
    var friends = [User]()
    
    func getFriends() {
        friends = []
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
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
                                SVProgressHUD.dismiss()
                                self.searchTableView.reloadData()
                            }
                        })
                    }
                }
            }
        })
    }
    
    func searchFriends(for name: String) {
        SVProgressHUD.show()
        friends = []
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendsDict = snapshot.value as? [String: AnyObject] {
                for friend in friendsDict as! [String: Int] {
                    if friend.value == 1 {
                        
                        FIRDatabase.database().reference().child("Users").child(friend.key).observeSingleEvent(of: .value, with: { (innerSnap) in
                            
                            if let userDict = innerSnap.value as? [String: AnyObject] {
                                if let userName = userDict["name"] as? String {
                                    if userName.contains(name) {
                                        let user = User()
                                        
                                        user.setValuesForKeys(userDict)
                                        user.id = friend.key
                                        
                                        if user.id != currentID {
                                            self.friends.append(user)
                                        }
                                    }
                                }
                            }
                            
                            DispatchQueue.main.async {
                                SVProgressHUD.dismiss()
                                self.searchTableView.reloadData()
                            }
                        })
                    }
                }
            }
        })
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bringSelectedScopeArray(scope: searchBar.selectedScopeButtonIndex).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = searchTableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchTableViewCell
        
        var user = User()
        
        user = bringSelectedScopeArray(scope: searchBar.selectedScopeButtonIndex)[indexPath.row]
        
        cell.user = user
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismissKeyboard()
    }
    
    // MARK: - Show Profile Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            let vc = segue.destination as! ProfileController
            if let indexPath = searchTableView.indexPathForSelectedRow {
                guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
                let selectedRow = indexPath.row
                let selectedUsers = bringSelectedScopeArray(scope: searchBar.selectedScopeButtonIndex)
                let user = selectedUsers[selectedRow]
                
                vc.profileUserID = user.id!
                vc.isMyProfile = (user.id == currentID)
            }
        }
    }
    
    // MARK: - Helper
    
    func bringSelectedScopeArray(scope: searchBarSelectedScope.RawValue) -> [User] {
        if scope == 1 {
            return friends
        } else {
            return users
        }
    }
}
