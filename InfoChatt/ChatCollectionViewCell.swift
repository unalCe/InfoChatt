//
//  ChatCollectionViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 23.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class ChatCollectionViewCell: UICollectionViewCell {
    
    var message: Message? {
        didSet {
            chatTextView.text = message?.message
            
            fetchPartnerImage()
            
            if let seconds = message?.time?.doubleValue {
                let messageDate = NSDate(timeIntervalSince1970: seconds)

                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(identifier: "GMT+03")
                dateFormatter.locale = NSLocale(localeIdentifier: "tr") as Locale!
                
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                dateFormatter.doesRelativeDateFormatting = true
                
                timeLabel.text = dateFormatter.string(from: messageDate as Date)
            }
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var chatViewBubbleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var partnerProfileImage: UIImageView!
    
    // Storyboard'dan çektiğim constraintleri active, deactive edemiyorum çünkü active'yi false yapmak constrainti silmekle aynı işlevi görüyor. 
    // Bu nedenle her cell oluşturulduğunda buradan tekrar constraint oluşturmak gerek.
    
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    func handleConstraints() {
        // Right Anchor
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        // Default olarak aktif false'dir.
        // Aktif'i chatCollectionView içerisinden vereceğiz.
        
        // Left Anchor
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: self.partnerProfileImage.rightAnchor, constant: 8)
    }
    
    func fetchPartnerImage() {
        if let partnerID = message?.chatPartnerID() {
            FIRDatabase.database().reference().child("Users").child(partnerID).observe(.value, with: { (snap) in
                if let dict = snap.value as? [String: AnyObject] {
                    if let imageUrl = dict["profileImageUrl"] as? String {
                        self.partnerProfileImage.sd_setImage(with: URL(string: imageUrl))
                    }
                }
            }, withCancel: nil)
        }
    }
    
    func handlePartnerProfileImage() {
        partnerProfileImage.layer.cornerRadius = partnerProfileImage.frame.width / 2
        partnerProfileImage.clipsToBounds = true
    }
    
    override func awakeFromNib() {
        bubbleView.layer.cornerRadius = 12
        bubbleView.clipsToBounds = true
        timeLabel.textColor = UIColor.darkGray
        
        handleConstraints()
        handlePartnerProfileImage()
    }
}
