//
//  User.swift
//  InfoChatt
//
//  Created by Unal Celik on 8.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Foundation

class User: NSObject {
    var id: String?
    var profileImageUrl: String?
    var connection: String?
    var name: String?
    var email: String?
    var createdAt: NSNumber?
    var friends: NSArray?
}
