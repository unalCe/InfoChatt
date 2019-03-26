//
//  ContentCollectionViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 6.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Firebase
import UIKit
import Spring

class ContentCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var likeButton: SpringButton!
    
    var centerLikeView: SpringView = {
        let clv = SpringView()
        clv.isHidden = true
        clv.autohide = true
        clv.backgroundColor = UIColor.flatBlack
        clv.layer.cornerRadius = 10
        clv.clipsToBounds = true
        clv.translatesAutoresizingMaskIntoConstraints = false
        return clv
    }()
    
    var centerLikeHeart: UIImageView = {
        let clb = UIImageView()
        clb.image = #imageLiteral(resourceName: "heart")
        clb.contentMode = .scaleAspectFit
        clb.clipsToBounds = true
        clb.translatesAutoresizingMaskIntoConstraints = false
        return clb
    }()
    
    @IBOutlet weak var dateLabel: UILabel!
    
    var delegate: HomeController?
    
    var indexPathRow: Int?
    
    var isLiked = Bool()
    var likeCount = Int()
    var peopleLiked = [String]()
    
    var content: Content? {
        didSet {
            isLiked = false
            peopleLiked = []
            likeCount = 0
            
            guard let currentUserID = FIRAuth.auth()?.currentUser?.uid else { return }
            
            if let imageUrl = content?.imageUrl {
                mainImageView.sd_setImage(with: URL(string: imageUrl))
            }
            
            if let profileImageUrl = content?.profileImageUrl {
                profileImageView.sd_setImage(with: URL(string: profileImageUrl))
            }
            
            if let desc = content?.cDescription {
                let styl = NSMutableParagraphStyle()
                styl.firstLineHeadIndent = 8.0
                
                let attributed = NSAttributedString(string: desc, attributes: [NSParagraphStyleAttributeName: styl])
                descLabel.attributedText = attributed
            }
            
            if let name = content?.name {
                nameLabel.text = name
            }
            
            if let seconds = content?.time?.doubleValue {
                let timeStamp = NSDate(timeIntervalSince1970: seconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(identifier: "GMT+03")
                dateFormatter.locale = NSLocale(localeIdentifier: "tr") as Locale!
                dateFormatter.dateFormat = "MMM d, HH:mm"
                
                dateLabel.text = dateFormatter.string(from: timeStamp as Date)
            }
            
            if (content?.peopleLiked) != nil {
                
                FIRDatabase.database().reference().child("Content").observe(.childAdded, with: { (snapshot) in
                    FIRDatabase.database().reference().child("Content").child(snapshot.key).observe(.childAdded, with: { (innerSnap) in
                        
                        guard let dict = innerSnap.value as? [String:AnyObject] else { return }
                        
                        //print(innerSnap.key) // dict["contentId"] ile aynı değere sahip. istersen databaseden contentId çıkar. bunu kullan.
                        
                        if let contentId = dict["contentId"] as? String {
                            if contentId == self.content?.contentId {
                                
                                if let allLikers = dict["peopleLiked"] as? [String] {
                                    self.peopleLiked = allLikers
                                }
                                
                                if self.peopleLiked.contains(currentUserID) {
                                    self.likeButton.setImage(#imageLiteral(resourceName: "filledLike"), for: .normal)
                                    self.isLiked = true
                                } else {
                                    self.isLiked = false
                                    self.likeButton.setImage(#imageLiteral(resourceName: "emptyLike"), for: .normal)
                                }
                            }
                        }
                    }, withCancel: nil)
                }, withCancel: nil)
            } else {
                self.isLiked = false
                self.likeButton.setImage(#imageLiteral(resourceName: "emptyLike"), for: .normal)
            }
            
            
            if let like = content?.like?.intValue {
                FIRDatabase.database().reference().child("Content").observe(.childAdded, with: { (snapshot) in
                    
                    for innerSnap in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    
                        guard let dict = innerSnap.value as? [String: AnyObject] else { return }
                        
                        if let contentId = dict["contentId"] as? String {
                            if contentId == self.content?.contentId {
                                if let likeC = dict["like"] as? Int {
                                    self.likeCount = likeC
                                    
                                    if (like == 0) {
                                        let style = NSMutableParagraphStyle()
                                        style.firstLineHeadIndent = 8
                                        
                                        let attr = NSAttributedString(string: "No one liked this", attributes: [NSParagraphStyleAttributeName: style])
                                        self.likeLabel.attributedText = attr
                                    } else {
                                        let style = NSMutableParagraphStyle()
                                        style.firstLineHeadIndent = 8
                                        
                                        let attr = NSAttributedString(string: "\(self.likeCount) people liked this", attributes: [NSParagraphStyleAttributeName: style])
                                        self.likeLabel.attributedText = attr
                                    }
                                }
                            }
                        }
                    }
                }, withCancel: nil)
            }
        }
    }
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        headerView.layer.cornerRadius = 4
        headerView.clipsToBounds = true
        
        mainImageView.layer.cornerRadius = 4
        mainImageView.clipsToBounds = true
        
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
        
        footerView.layer.cornerRadius = 4
        footerView.clipsToBounds = true
        
        descLabel.layer.cornerRadius = 4
        descLabel.clipsToBounds = true
        
        likeButton.animation = "pop"
        likeButton.curve = "spring"
        likeButton.duration = 1.0
        likeButton.setImage(#imageLiteral(resourceName: "emptyLike"), for: .normal)
        
        likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        
        addTapGestures()
        handleFrameForCenterLikeButton()
    }
    
    // MARK: Customizations
    func handleFrameForCenterLikeButton() {
        addSubview(centerLikeView)
        centerLikeView.centerXAnchor.constraint(equalTo: mainImageView.centerXAnchor).isActive = true
        centerLikeView.centerYAnchor.constraint(equalTo: mainImageView.centerYAnchor).isActive = true
        centerLikeView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        centerLikeView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        centerLikeView.addSubview(centerLikeHeart)
        centerLikeHeart.centerXAnchor.constraint(equalTo: centerLikeView.centerXAnchor).isActive = true
        centerLikeHeart.centerYAnchor.constraint(equalTo: centerLikeView.centerYAnchor).isActive = true
        centerLikeHeart.widthAnchor.constraint(equalToConstant: 42).isActive = true
        centerLikeHeart.heightAnchor.constraint(equalTo: centerLikeHeart.widthAnchor).isActive = true // 1:1
    }
    
    func addTapGestures() {
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(showProfile))
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(nameTap)
        
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(showProfile))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileTap)
        
        let peopleWhoLiked = UITapGestureRecognizer(target: self, action: #selector(showLikers))
        likeLabel.isUserInteractionEnabled = true
        likeLabel.addGestureRecognizer(peopleWhoLiked)
    
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(likePicture))
        likeTap.numberOfTapsRequired = 2
        mainImageView.isUserInteractionEnabled = true
        mainImageView.addGestureRecognizer(likeTap)
    }
    
    // MARK: - Like
    func likePicture(sender: UITapGestureRecognizer!) {
        handleLike()
    }
    
    // MARK: - Show Profile & Likers
    func showProfile(sender: UITapGestureRecognizer!) {
        guard let currentID = FIRAuth.auth()?.currentUser?.uid else { return }
        if currentID == content?.userID {
            delegate?.goToProfileTabView()
        } else {
            delegate?.id = content?.userID
            delegate?.performSegue(withIdentifier: "showUserProfile", sender: nil)
        }
    }
    
    func showLikers(sender: UITapGestureRecognizer!) {      /// Profil sayfaları içerisinden yollandığında delegate yok.
        delegate?.id = content?.userID
        delegate?.contentID = content?.contentId
        delegate?.performSegue(withIdentifier: "showLikers", sender: nil)
    }
    
    // MARK: - Handle Like
    // DEĞİŞTİR: Like sayısını değişkende tutmak yerine sonradan eklediğin peopleLiked arrayinin sayısını döndürebilirsin.
    // Eşek yüküyle kod ve işlem kısalacak.
    func handleLike() {
        guard let currentUserID = FIRAuth.auth()?.currentUser?.uid else { return }
        
        if isLiked {
            self.likeButton.setImage(#imageLiteral(resourceName: "emptyLike"), for: .normal)
            self.likeCount -= 1
        } else {
            likeButton.setImage(#imageLiteral(resourceName: "filledLike"), for: .normal)
            self.likeCount += 1
            
            centerLikeView.isHidden = false
            centerLikeView.animation = "pop"
            centerLikeView.curve = "spring"
            centerLikeView.force = 1.5
            centerLikeView.duration = 1.0
            centerLikeView.animate()
            
            centerLikeView.animateToNext(completion: {
                self.centerLikeView.animation = "zoomOut"
                self.centerLikeView.delay = 0.25
                self.centerLikeView.animateTo()
            })
        }
        
        likeButton.animate()
        
        FIRDatabase.database().reference().child("Content").observe(.childAdded, with: { (snapshot) in
            FIRDatabase.database().reference().child("Content").child(snapshot.key).observe(.childAdded, with: { (innerSnap) in
                
                guard let dict = innerSnap.value as? [String:AnyObject] else { return }
                
                if let contentId = dict["contentId"] as? String {
                    if contentId == self.content?.contentId {
                        FIRDatabase.database().reference().child("Content").child(snapshot.key).child(contentId).updateChildValues(["like": self.likeCount])
                        
                        if self.isLiked {
                            self.peopleLiked = self.peopleLiked.filter() { $0 != currentUserID }
                            FIRDatabase.database().reference().child("Content").child(snapshot.key).child(contentId).child("peopleLiked").setValue(self.peopleLiked as NSArray)
                            self.isLiked = false
                        } else {
                            self.peopleLiked.append(currentUserID)
                            FIRDatabase.database().reference().child("Content").child(snapshot.key).child(contentId).child("peopleLiked").setValue(self.peopleLiked as NSArray)
                            self.isLiked = true
                        }
                        
                        let style = NSMutableParagraphStyle()
                        style.firstLineHeadIndent = 8
                        
                        var string = String()
                        
                        if self.likeCount == 0 {
                            string = "No one liked this"
                        } else {
                            string = "\(self.likeCount) people liked this"
                        }
                        
                        let attr = NSAttributedString(string: string, attributes: [NSParagraphStyleAttributeName: style])
                        self.likeLabel.attributedText = attr
                    }
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
}
