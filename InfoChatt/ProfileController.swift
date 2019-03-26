//
//  ProfileController.swift
//  InfoChatt
//
//  Created by Unal Celik on 30.01.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import SDWebImage
import DZNEmptyDataSet
import SVProgressHUD
import ChameleonFramework

var profileControllerCount: Int = 0

class ProfileController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var profileFlowCollectionView: UICollectionView!
    @IBOutlet weak var profileDescription: UIView!
    @IBOutlet weak var profileBackgroundView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var flowHeightConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var addFriendButton: UIButton!
    
    var profileUserID = String()
    var homeController: HomeController?    // Memory management öğren. weak var olabilirdi. bazı referanslar kalıyor. 
    var isMyProfile = true
    
    var isFromLikers = Bool()
    
    func isFromLikerss() {
        if isFromLikers {
            isMyProfile = false
            self.navigationController?.navigationItem.titleView = titleLabel
            
            let backBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(back))
            self.navigationItem.leftBarButtonItem = backBarButtonItem
        }
    }
    
    func back() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Life Cycle
    
    func checkIfMyProfile() {
        if profileUserID == "" {
            profileUserID = (FIRAuth.auth()?.currentUser?.uid)!
            isMyProfile = true
            addFriendButton.isHidden = true
        } else {
            isMyProfile = false
            addFriendButton.isHidden = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        customiseRightBarButtonItem() // isMyProfile değişkeni bazen geç geliyor. Bu metodun hata vermemesi için geç çalışması lazım.
        
        profileFlowCollectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileControllerCount += 1
        print("ProfileController = \(profileControllerCount)")
        
        isFromLikerss()
        customiseAddButton()
        customiseProfileImage()
        customiseDescriptionView()
        customiseFlowCollectionView()
        customiseFriendsLabel()
        tapGestureToFriendsLabel()
        tapGestureToImageView()
        
        fetchContents()
        
        getProfileImage()
        
        checkIfMyProfile()
        checkIfFriend(isMyProfile: isMyProfile)
        
        listenForChanges()
        listenForFriendChanges()

      //  getNotifications()   // tab controller içerisinde daha en başta çağırılıyor ki sağ altta notifications gözüksün.
    }
    
    deinit {
        profileControllerCount -= 1
        print("ProfileController = \(profileControllerCount)")
    }

    // MARK: - DZNEmptyDataSet
    
    func setupEmptyDataSet() {
        self.profileFlowCollectionView.emptyDataSetSource = self
        self.profileFlowCollectionView.emptyDataSetDelegate = self
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "instagram")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = String()
        
        if isMyProfile {
            text = "You have no images"
        } else {
            text = "User has no images"
        }
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: FlatGray()
        ]
        
        return NSAttributedString(string: text, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = String()
        
        if isMyProfile {
            text = "Share the best moments of your life with your friends"
        } else {
            text = ""
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
    
    
    // MARK: - Customization
    
    func customiseDescriptionView() {
        profileDescription.layer.cornerRadius = 6
        profileDescription.clipsToBounds = true
    }
    
    func customiseFlowCollectionView() {
        profileFlowCollectionView.delegate = self
        profileFlowCollectionView.dataSource = self
        profileFlowCollectionView.layer.cornerRadius = 6
        profileFlowCollectionView.clipsToBounds = true
        
        //profileFlowCollectionView.isScrollEnabled = false // zaten aşağıda tam olarak boyut veriyorum. farketmedi.
    }
    
    func customiseProfileBackgroundView() {
        profileBackgroundView.backgroundColor = UIColor.init(red: 220/255, green: 220/255, blue: 0.86, alpha: 1)
        profileBackgroundView.image = profileImageView.image
        profileBackgroundView.contentMode = .scaleAspectFill
        profileBackgroundView.clipsToBounds = true
        profileBackgroundView.addBlurEffect()
    }
    
    func customiseProfileImage() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.isUserInteractionEnabled = true
    }
    
    func customiseRightBarButtonItem() {
        if isMyProfile {
            rightBarButtonView.backgroundColor = .clear
            notificationBubbleView.layer.cornerRadius = notificationBubbleView.frame.height / 2
            notificationBubbleView.clipsToBounds = true
        }
    }
    
    func customiseAddButton() {
        addFriendButton.layer.cornerRadius = 4
        addFriendButton.clipsToBounds = true
        
        addFriendButton.setTitle("Add Friend", for: .normal)
    }
    
    func tapGestureToImageView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(editProfileImage))
        profileImageView.addGestureRecognizer(tap)
    }
    
    func tapGestureToFriendsLabel() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showFriends))
        friendsLabel.addGestureRecognizer(tap)
    }
    
    func showFriends(sender: UITapGestureRecognizer!) {
        performSegue(withIdentifier: "showFriends", sender: nil)
    }
    
    var acceptedFriends = [String: Int]()
    var found = false
    
    func customiseFriendsLabel() {
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        acceptedFriends = [:]
        
        FIRDatabase.database().reference().child("Users").child(userID).child("friends").observe(.childAdded, with: { (snap) in
            
            if snap.value as? Int == 1 {
                self.acceptedFriends[snap.key] = snap.value as? Int
                self.found = true
            }
            
            if self.found {
                self.friendsLabel.text = "\(self.acceptedFriends.count) friends"
            } else {
                self.friendsLabel.text = "No friends"
            }
        }, withCancel: nil)
    }
    
    func listenForFriendChanges() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        // profileUserID başlangıçta normal davranıyor. Sayfanın yüklemesi bittiğinde add-remove yapıldığında çalışan, bu observerler içerisinde profileUserID, currenID'ye eşit oluyor???  (HALLEDİLDİ)
        
        FIRDatabase.database().reference().child("Users").child(userID).child("friends").observe(.childChanged, with: { (snapp) in
            self.customiseFriendsLabel()
        })
        
        FIRDatabase.database().reference().child("Users").child(userID).child("friends").observe(.childRemoved, with: { (snapp) in
            self.customiseFriendsLabel()
        })
    }
    
    // MARK: - Show & Edit Profile Image
    
    func editProfileImage(sender: UITapGestureRecognizer!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editNav = storyboard.instantiateViewController(withIdentifier: "editnav") as! UINavigationController
        let editvc = editNav.viewControllers[0] as! EditProfileImageViewController
        
        editvc.view.backgroundColor = .black
        editvc.profileImageView.image = self.profileImageView.image
        editvc.isMyProfile = isMyProfile
        
        present(editNav, animated: true, completion: nil)
    }
    
    // MARK: - Edit Username
    
    @IBAction func editName(_ sender: UITapGestureRecognizer) {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var tField: UITextField!
        
        let alert = UIAlertController(title: "Change your username", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Enter a new name"
            textField.backgroundColor = UIColor.white
            textField.keyboardAppearance = .default
            textField.returnKeyType = .done
            textField.enablesReturnKeyAutomatically = true
            tField = textField
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (handle) in
            guard let userName = tField.text else { return }
            SVProgressHUD.show()
            
            FIRDatabase.database().reference().child("Users").child(currentID).child("name").setValue(userName)
            
            FIRDatabase.database().reference().child("Content").child(currentID).observe(.childAdded, with: { (snap) in
                FIRDatabase.database().reference().child("Content").child(currentID).child(snap.key).child("name").setValue(userName)
                
                self.titleLabel.text = userName
                self.titleLabel.layoutIfNeeded()
            }, withCancel: nil)
            
            SVProgressHUD.dismiss()
            self.fetchContents()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Fetch Data
    
    func getProfileImage() {
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        FIRDatabase.database().reference().child("Users").child(userID).observeSingleEvent(of: .value, with: {
            (snapshot) in
            
            guard let dict = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            if let imageUrl = dict["profileImageUrl"] as? String {
                self.profileImageView.sd_setImage(with: URL(string: imageUrl)) { (completed) in
                    self.customiseProfileBackgroundView()
                }
            }
            
            if let name = dict["name"] as? String {
                self.titleLabel.text = name
                self.navigationItem.titleView = self.titleLabel
            }
        }, withCancel: nil)
    }
    
    var allContents = [Content]()
    
    func fetchContents() {
        allContents = []
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        let ref = FIRDatabase.database().reference()
        ref.observe(.childAdded, with: { (outerSnap) in
            if outerSnap.key == "Content" {
                
                FIRDatabase.database().reference().child("Content").observe(.childAdded, with: { (snapshot) in
                    if userID == snapshot.key {
                        FIRDatabase.database().reference().child("Content").child(userID).observe(.childAdded, with: { (innerSnap) in
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
                                self.profileFlowCollectionView.reloadData()
                            }
                        }, withCancel: nil)
                    } else {
                        self.setupEmptyDataSet()
                        self.profileFlowCollectionView.reloadData()
                    }
                }, withCancel: nil)    
            } else {
                SVProgressHUD.dismiss()
                self.setupEmptyDataSet()
                self.profileFlowCollectionView.reloadData()
            }
        })
    }
    
    
    // MARK: - Check For Friend

    func checkIfFriend(isMyProfile: Bool) {
        
        if isMyProfile {
            return
        } else {
            guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
            
            addFriendButton.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
            
            
            FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observe(.childAdded, with: { (snapshot) in
                
                        if snapshot.key == self.profileUserID {
                            
                            // switch case ile butonun durumunu ve işlevini belirle. databasede 0 - 1 - 2
                            switch snapshot.value as! Int {
                            case 0:
                                self.customiseSendRequestButton()
                                break
                                
                            case 1:
                                self.customiseAlreadyFriendsButton()
                                break
                                
                            case 2:
                                self.customiseAcceptFriendButton()
                                break
                                
                            default:
                                break
                            }
                        }
            }, withCancel: nil)
        }
    }
    
    func listenForChanges() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").child(userID).observe(.childAdded, with: { (snap) in
            self.checkIfFriend(isMyProfile: self.isMyProfile)
        }, withCancel: nil)
    }
    
    // MARK: - Customize Add Button
    func customiseAddFriendButton() {
        addFriendButton.setTitle("Add Friend", for: .normal)
        addFriendButton.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
    }
    
    func customiseAlreadyFriendsButton() {
        addFriendButton.setTitle("Remove", for: .normal)
        addFriendButton.removeTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        addFriendButton.addTarget(self, action: #selector(handleRemove), for: .touchUpInside)
        self.customiseFriendsLabel()
    }
    
    func customiseSendRequestButton() {
        addFriendButton.setTitle("Pending", for: .normal)
        addFriendButton.removeTarget(self, action: #selector(handleAdd), for: .touchUpInside)
    }
    
    func customiseAcceptFriendButton() {
        addFriendButton.setTitle("Accept", for: .normal)
        addFriendButton.removeTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        addFriendButton.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)
        self.customiseFriendsLabel()
    }

   
    // MARK: - Add Button Actions
    func handleAdd() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        FIRDatabase.database().reference().child("Users").child(currentID).observeSingleEvent(of: .value, with: { (snap) in
            if let userDict = snap.value as? [String: AnyObject] {
                if var friendsDict = userDict["friends"] as? [String: AnyObject] {
                    // Append the user
                    friendsDict[userID] = 0 as AnyObject?
                    
                    // Update new values
                    FIRDatabase.database().reference().child("Users").child(currentID).child("friends").updateChildValues(friendsDict)
                } else {
                    // Daha önce hiç friend eklememiş kişiler için friend node oluşturup içerisine ekler.
                    FIRDatabase.database().reference().child("Users").child(currentID).child("friends").updateChildValues([userID: 0])
                }
            }
            
            FIRDatabase.database().reference().child("Users").child(userID).observeSingleEvent(of: .value, with: { (innerSnap) in
                if let pendingUserDict = innerSnap.value as? [String: AnyObject] {
                    if var pendingUsersFriendsDict = pendingUserDict["friends"] as? [String: AnyObject] {
                        // Append request
                        pendingUsersFriendsDict[currentID] = 2 as AnyObject?
                        
                        // Update values
                        FIRDatabase.database().reference().child("Users").child(userID).child("friends").updateChildValues(pendingUsersFriendsDict)
                    } else {
                        FIRDatabase.database().reference().child("Users").child(userID).child("friends").updateChildValues([currentID: 2])
                    }
                }
            })
        })
        customiseSendRequestButton()
    }
    
    func handleRemove() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        // Şuandaki kullanıcının işlemleri
        FIRDatabase.database().reference().child("Users").child(currentID).observeSingleEvent(of: .value, with: { (snap) in
            if let userDict = snap.value as? [String: AnyObject] {
                if (userDict["friends"] as? [String: AnyObject]) != nil {
                    // Remove the user
                    // Update new values
                    FIRDatabase.database().reference().child("Users").child(currentID).child("friends").child(userID).removeValue()
                }
            }
            
            // Karşı tarafın işlemleri
            FIRDatabase.database().reference().child("Users").child(userID).observeSingleEvent(of: .value, with: { (innerSnap) in
                if let pendingUserDict = innerSnap.value as? [String: AnyObject] {
                    if (pendingUserDict["friends"] as? [String: AnyObject]) != nil {
                        // remove request
                        
                        // Update values
                        FIRDatabase.database().reference().child("Users").child(userID).child("friends").child(currentID).removeValue()
                    } // Ekstra güvenlik istenirse burada else block ile karşı userin friend'i var mı sorgusu yapılabilir. Ama zaten friend olunabilmesi için iki tarafta da userId'lerin bulunması gerektiği için şuanda koymadım.
                }
            })
        })
        customiseAddFriendButton()
    }
    
    func handleAccept() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        var userID = String()
        
        if isMyProfile {
            userID = currentID
        } else {
            userID = profileUserID
        }
        
        // Şuandaki kullanıcının işlemleri
        FIRDatabase.database().reference().child("Users").child(currentID).observeSingleEvent(of: .value, with: { (snap) in
            if let userDict = snap.value as? [String: AnyObject] {
                if var friendsDict = userDict["friends"] as? [String: AnyObject] {
                    // Change value to 1
                    friendsDict[userID] = 1 as AnyObject?
                    
                    // Update new values
                    FIRDatabase.database().reference().child("Users").child(currentID).child("friends").updateChildValues(friendsDict)
                }
            }
            
            // Karşı tarafın işlemleri
            FIRDatabase.database().reference().child("Users").child(userID).observeSingleEvent(of: .value, with: { (innerSnap) in
                if let pendingUserDict = innerSnap.value as? [String: AnyObject] {
                    if var pendingUsersFriendsDict = pendingUserDict["friends"] as? [String: AnyObject] {
                        // Append request
                        pendingUsersFriendsDict[currentID] = 1 as AnyObject?
                        
                        // Update values
                        FIRDatabase.database().reference().child("Users").child(userID).child("friends").updateChildValues(pendingUsersFriendsDict)
                    } // Ekstra güvenlik istenirse burada else block ile karşı userin friend'i var mı sorgusu yapılabilir. Ama zaten friend olunabilmesi için iki tarafta da userId'lerin bulunması gerektiği için şuanda koymadım.
                }
            })
        })
        customiseAlreadyFriendsButton()
    }

    // MARK: - Prepare for Notification Segue
    
    @IBOutlet var rightBarButtonView: UIView!
    @IBOutlet weak var notificationBubbleView: UIView!
    @IBOutlet weak var notificationCountLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    
    var notificatedUsedIDs = [String: Int]()
    var notificatingUsers = [User]()
    
    func getNotifications() {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        FIRDatabase.database().reference().child("Users").child(currentID).child("friends").observe(.childAdded, with: { (snapshot) in
            
            if snapshot.value as? Int == 2 {
                self.notificatedUsedIDs[snapshot.key] = snapshot.value as? Int
                
                FIRDatabase.database().reference().child("Users").child(snapshot.key).observeSingleEvent(of: .value, with: { (innerSnap) in
                    
                    let user = User()
                    
                    if let userDict = innerSnap.value as? [String: AnyObject] {
                        user.setValuesForKeys(userDict)
                        
                        user.id = innerSnap.key
                        
                        self.notificatingUsers.append(user)
                    }
                    
                    // Custom right bar button item
                    
                    self.setupRightBarButton()
                 /*
                    self.navigationController?.tabBarItem.badgeValue = "\(self.notificatingUsers.count)"
                    self.navigationController?.tabBarItem.badgeColor = FlatBlue()
                 */
                }, withCancel: nil)
            }
        }, withCancel: nil)
    }
    
    func setupRightBarButton() {
        self.notificationBubbleView.isHidden = false
        self.notificationButton.addTarget(self, action: #selector(self.handleRightBarButton), for: .touchUpInside)
        self.notificationCountLabel.text = "\(self.notificatingUsers.count)"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.rightBarButtonView)
        self.navigationItem.rightBarButtonItem?.tintColor = .clear
    }
    
    func handleRightBarButton() {
        performSegue(withIdentifier: "notifSegue", sender: nil)
    }
    
    func deleteUser(at indexPath: IndexPath) {
        self.notificatingUsers.remove(at: indexPath.row)
    }
    
    func getReadyForNotificationView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.6
        }, completion: nil)
    }
    
    func getReadyForDismissingNotificationView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1.0
        }, completion: nil)
    }
    
    
    // MARK: - Handle Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "notifSegue" {
            let vc = segue.destination as! NotificationViewController
            
            vc.baseController = self
            vc.notificatedUsedIDs = notificatedUsedIDs
            vc.notificatingUsers = notificatingUsers
            
            getReadyForNotificationView()
        } else if segue.identifier == "showFriends" {
            let vc = segue.destination as! FriendsViewController
            guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
            
            if isMyProfile {
                vc.userID = currentID
            } else {
                vc.userID = self.profileUserID
            }
        }
    }

    // MARK: - Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if allContents.count == 0 {
            self.flowHeightConstraint.constant = CGFloat(1 * 493)          
        } else {
            self.flowHeightConstraint.constant = CGFloat(allContents.count * 493)
        }
        return allContents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = profileFlowCollectionView.dequeueReusableCell(withReuseIdentifier: "contentCell", for: indexPath) as! ContentCollectionViewCell
        
        let content = allContents[indexPath.row]
        
        cell.content = content
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.width + 118)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension UIImageView {
    func addBlurEffect()
    {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.alpha = 0.9
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
    }
}


