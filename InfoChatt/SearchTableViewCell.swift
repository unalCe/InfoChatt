//
//  SearchTableViewCell.swift
//  InfoChatt
//
//  Created by Unal Celik on 10.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit
import SDWebImage

class SearchTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var user: User? {
        didSet {
            if let name = user?.name {
                nameLabel.text = name
            }
            
            if let imageUrl = user?.profileImageUrl {
                profileImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "0BD0DFA9-9701-4696-8AF0-959AFDDE8A34"))
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customiseImage()
    }
    
    func customiseImage() {
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
    }
    
}
