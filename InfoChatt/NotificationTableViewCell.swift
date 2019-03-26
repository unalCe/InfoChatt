//
//  NotificationTableViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 18.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase

class NotificationTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var ppImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!

    var baseController: NotificationViewController?
    var indexPath: IndexPath?
    
    var user: User? {
        didSet {
            if let name = user?.name {
                self.nameLabel.text = name
            }
            
            if let imageUrl = user?.profileImageUrl {
                self.ppImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "0BD0DFA9-9701-4696-8AF0-959AFDDE8A34"))
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        customiseButton()
    }

    func customiseButton() {
        acceptButton.layer.cornerRadius = 4
        acceptButton.clipsToBounds = true
        acceptButton.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)
    }
    
    func handleAccept() {
        print("gördüm ve ettim")
        
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        // Şuandaki kullanıcının işlemleri
        FIRDatabase.database().reference().child("Users").child(currentID).observeSingleEvent(of: .value, with: { (snap) in
            if let userDict = snap.value as? [String: AnyObject] {
                if var friendsDict = userDict["friends"] as? [String: AnyObject] {
                    // Change value to 1
                    friendsDict[(self.user?.id)!] = 1 as AnyObject?
                    
                    // Update new values
                    FIRDatabase.database().reference().child("Users").child(currentID).child("friends").updateChildValues(friendsDict)
                }
            }
            
            // Karşı tarafın işlemleri
            FIRDatabase.database().reference().child("Users").child((self.user?.id)!).observeSingleEvent(of: .value, with: { (innerSnap) in
                if let pendingUserDict = innerSnap.value as? [String: AnyObject] {
                    if var pendingUsersFriendsDict = pendingUserDict["friends"] as? [String: AnyObject] {
                        // Append request
                        pendingUsersFriendsDict[currentID] = 1 as AnyObject?
                        
                        // Update values
                        FIRDatabase.database().reference().child("Users").child((self.user?.id)!).child("friends").updateChildValues(pendingUsersFriendsDict)
                    }
                }
            })
        })
        
        baseController?.baseController?.deleteUser(at: self.indexPath!)
        baseController?.deleteRow(at: self.indexPath!)
    }
}
