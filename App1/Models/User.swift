//
//  User.swift
//  App1
//
//  Created by John Grese on 8/1/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

class User {
    var dbId: Int
    var userId: String
    var name: String
    var email: String

    init(dbId: Int, userId: String, name: String, email: String) {
        self.dbId = dbId
        self.userId = userId
        self.name = name
        self.email = email
    }
}
