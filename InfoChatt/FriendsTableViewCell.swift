//
//  FriendsTableViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 20.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ppImageView: UIImageView!
    @IBOutlet weak var onlieView: UIView!
    
    var user: User? {
        didSet {
            if let name = user?.name {
                nameLabel.text = name
            }
            
            if let imageUrl = user?.profileImageUrl {
                ppImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "0BD0DFA9-9701-4696-8AF0-959AFDDE8A34"))
            }
            
            if let online = user?.connection {
                if online == "online" {
                    onlieView.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                } else {
                    onlieView.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                }
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customiseImage()
        customiseOnlineView()
    }
    
    func customiseOnlineView() {
        onlieView.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        onlieView.layer.cornerRadius = onlieView.frame.width / 2
        onlieView.clipsToBounds = true
    }
    
    func customiseImage() {
        ppImageView.contentMode = .scaleAspectFit
        ppImageView.layer.cornerRadius = ppImageView.frame.width / 2
        ppImageView.clipsToBounds = true
    }
}
