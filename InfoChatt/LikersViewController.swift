//
//  LikersViewController.swift
//  InfoChatt
//
//  Created by Unal Celik on 27.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet
import ChameleonFramework

class LikersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // MARK: - Properties
    @IBOutlet weak var likersTableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
    
    var delegate: HomeController?
    
    var userID: String?
    var contentID: String?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        customiseLikersTableView()
        addTapGestureToView()
        fetchLikers()
    }
    
    // MARK: - Customization
    func customiseLikersTableView() {
        likersTableView.layer.cornerRadius = 10
        likersTableView.clipsToBounds = true
        likersTableView.delegate = self
        likersTableView.dataSource = self
        likersTableView.tableFooterView = UIView()
        
        tableHeaderView.layer.cornerRadius = 6
        tableHeaderView.clipsToBounds = true
    }
    
    func addTapGestureToView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissView(sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: {
            self.delegate?.view.alpha = 1
        })
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - DZNEmptyDataSet
    
    func setupEmptyDataSet() {
        likersTableView.emptyDataSetSource = self
        likersTableView.emptyDataSetDelegate = self
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "brokenHeart")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "No one liked this post"
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
/*
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Get some friends to see their images"
        
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
 */
    
    // MARK: - Fetch Likers
    var likers = [User]()
    
    var empty = Bool()
    
    func fetchLikers() {
        likers = []
        guard let userID = userID else { return }
        guard let contentID = contentID else { return }
        
        FIRDatabase.database().reference().child("Content").child(userID).child(contentID).observeSingleEvent(of: .value, with: { (snap) in
            if let dict = snap.value as? [String: AnyObject] {
                if let likers = dict["peopleLiked"] as? [String] {
                    for liker in likers {
                        FIRDatabase.database().reference().child("Users").child(liker).observeSingleEvent(of: .value, with: { (innerSnap) in
                            
                            let user = User()
                            
                            if let userDict = innerSnap.value as? [String: AnyObject] {
                                user.setValuesForKeys(userDict)
                                
                                user.id = liker
                                
                                self.likers.append(user)
                            }
                            
                            DispatchQueue.main.async {
                                self.likersTableView.reloadData()
                            }
                        })
                    }
                }
            }
        }, withCancel: nil)
        
        perform(#selector(checkIfEmpty), with: nil, afterDelay: 0.23)
    }
    
    func checkIfEmpty() {
        if likers.isEmpty {
            setupEmptyDataSet()
            self.likersTableView.reloadData()
        }
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = likersTableView.dequeueReusableCell(withIdentifier: "likersCell", for: indexPath) as! SearchTableViewCell
        
        cell.user = likers[indexPath.row]
        
        return cell
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "likerProfile" {
            let vcNav = segue.destination as! UINavigationController
            if let vc = vcNav.viewControllers[0] as? ProfileController {
                if let indexPath = likersTableView.indexPathForSelectedRow {
                    let selectedRow = indexPath.row
                    
                    print(selectedRow)
                    
                    vc.profileUserID = likers[selectedRow].id!
                    vc.isMyProfile = false
                    vc.isFromLikers = true
                }
            }
        }
    }
}
