//
//  Message.swift
//  InfoChatt
//
//  Created by Unal Celik on 8.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import Foundation
import Firebase

class Message: NSObject {
    var message: String?
    var recipient: String?
    var sender: String?
    var time: NSNumber?
    
    func chatPartnerID() -> String? {
        return FIRAuth.auth()?.currentUser?.uid == recipient ? sender : recipient
    }
}
