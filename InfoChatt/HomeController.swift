//
//  HomeController.swift
//  InfoChatt
//
//  Created by Unal Celik on 30.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import DZNEmptyDataSet
import SVProgressHUD
import ChameleonFramework

var homeControllerCount: Int = 0

class HomeController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // MARK: - Properties
    weak var baseController: TabController?
    
    @IBOutlet var titleView: UIView!
    @IBOutlet weak var flowCollectionView: UICollectionView!
    
    // MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {

        fetchContents()

/*
         performans açısından sadece buradaki cell'leri yeniletiyordum ama profilde yapılan değişiklikleri çekebilmek için fetchContents'i direk viewWillAppear içerisine koydum.
 
        for cells in flowCollectionView.visibleCells {
            let indexPath = flowCollectionView.indexPath(for: cells)
            flowCollectionView.reloadItems(at: [indexPath!])
        }
 */
    }
    
    deinit {
        homeControllerCount -= 1
        print("deinit HomeController = \(homeControllerCount)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeControllerCount += 1
        print("HomeController = \(homeControllerCount)")
        
        customiseCollView()
        customiseNavTitle()
        
        flowCollectionView.reloadData()
    }

    // MARK: - Logout
    @IBAction func logOutBarAction(_ sender: UIBarButtonItem) {
        do {
            if let id = FIRAuth.auth()?.currentUser?.uid {
                FIRDatabase.database().reference().child("Users").child(id).updateChildValues(["connection": "offline"])
            }
            
            try FIRAuth.auth()?.signOut()
            GIDSignIn.sharedInstance().signOut()
            FBSDKLoginManager().logOut()
        } catch let Error {
            print(Error)
        }
        
        self.baseController?.baseController?.checkIfUserLoggedIn()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Customizations
    // FetchContents'in işi bittiğinde çağırılır.
    func setupEmptyDataSet() {
        flowCollectionView.emptyDataSetDelegate = self
        flowCollectionView.emptyDataSetSource = self
    }
    
    func customiseNavTitle() {
        self.navigationItem.titleView = titleView
    }
    
    func customiseCollView() {
        flowCollectionView.delegate = self
        flowCollectionView.dataSource = self
    }
    
    // MARK: - Fetch Contents
    var allContents = [Content]()
    
    func fetchContents() {
        allContents = []
        SVProgressHUD.show()
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Content").child(currentID).observe(.childAdded, with: { (snap) in
            let content = Content()
            
            if let dict = snap.value as? [String:AnyObject] {
                
                content.setValuesForKeys(dict)
                self.allContents.append(content)
            }
            
            DispatchQueue.main.async {
                self.allContents.sort(by: { (content1, content2) -> Bool in
                    return (content1.time?.intValue)! > (content2.time?.intValue)!
                })
                
                SVProgressHUD.dismiss()
                self.setupEmptyDataSet()
                self.flowCollectionView.reloadData()
            }
        })
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observe(.childAdded, with: { (friendSnap) in
            if friendSnap.value as? Int == 1 {
                
                FIRDatabase.database().reference().child("Content").child(friendSnap.key).observe(.childAdded, with: { (innerSnap) in
                    let content = Content()
                    
                    if let dict = innerSnap.value as? [String: AnyObject] {
                        content.setValuesForKeys(dict)
                        self.allContents.append(content)
                    }
                    
                    DispatchQueue.main.async {
                        self.allContents.sort(by: { (content1, content2) -> Bool in
                            return (content1.time?.intValue)! > (content2.time?.intValue)!
                        })
                        
                        SVProgressHUD.dismiss()
                        self.setupEmptyDataSet()
                        self.flowCollectionView.reloadData()
                    }
                }, withCancel: nil)
            } else {
                SVProgressHUD.dismiss()
                self.setupEmptyDataSet()
                self.flowCollectionView.reloadData()
            }
        }, withCancel: nil)
        perform(#selector(checkIfEmpty), with: nil, afterDelay: 1.5) // hardcoded değer.
    }

    func checkIfEmpty() {
        if allContents.isEmpty {
            SVProgressHUD.dismiss()
            self.setupEmptyDataSet()
            self.flowCollectionView.reloadData()
        }
    }
    
    // MARK: - DZNEmptyDataSet
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "instagram")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "There is no post"
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
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
    
    // MARK: - Show User Profile & Likers Segue
    var id: String? // CollectionViewCell içerisinden id'yi getirir.
    var contentID: String?
    
    func goToProfileTabView() {
        self.tabBarController?.selectedIndex = 3
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        if segue.identifier == "showUserProfile" {
            if let vc = segue.destination as? ProfileController {
                vc.profileUserID = id!
                vc.homeController = self
                vc.isMyProfile = false
            }
        } else if segue.identifier == "showLikers" {
            if let vc = segue.destination as? LikersViewController {
                vc.userID = id
                vc.contentID = contentID
                vc.delegate = self
                
                UIView.animate(withDuration: 0.3, animations: { 
                    self.view.alpha = 0.2
                })
            }
        }
    }

    // MARK: - CollectionView Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allContents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = flowCollectionView.dequeueReusableCell(withReuseIdentifier: "contentCell", for: indexPath) as! ContentCollectionViewCell
        let content = allContents[indexPath.row]
        
        cell.content = content
        cell.delegate = self
        cell.indexPathRow = indexPath.row
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.width + 118)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
