//
//  MessageTableViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 6.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var onlineView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var message: Message? {
        didSet {
            descLabel.text = message?.message
            
            if let seconds = message?.time?.doubleValue {
                
                //                let currentTime = NSNumber(value: NSDate().timeIntervalSince1970)
                let timeStamp = NSDate(timeIntervalSince1970: seconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(identifier: "GMT+03")
                dateFormatter.dateFormat = "hh:mm a"
                
                timeLabel.text = dateFormatter.string(from: timeStamp as Date)
            }
            
            // setup Profile name, image, online
            setupUserProfile()
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        customiseProfileView()
        customiseOnlineView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
    
    func setupUserProfile() {
        if let partnerID = message?.chatPartnerID() {
            FIRDatabase.database().reference().child("Users").child(partnerID).observe(.value, with: { (snap) in
                if let dict = snap.value as? [String: AnyObject] {
                    self.nameLabel.text = dict["name"] as? String
                    
                    if let imageUrl = dict["profileImageUrl"] as? String {
                        self.profileImageView.sd_setImage(with: URL(string: imageUrl))
                    }
                    
                    if let connection = dict["connection"] as? String {
                        if connection == "online" {
                            self.setOnline()
                        } else {
                            self.setOffline()
                        }
                    }
                }
            }, withCancel: nil)
        }
    }
    
    func setOnline() {
        onlineView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    }
    
    func setOffline() {
        onlineView.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    }
    
    func customiseOnlineView() {
        onlineView.layer.cornerRadius = onlineView.bounds.width / 2
        onlineView.clipsToBounds = true
    }
    
    func customiseProfileView() {
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
}
