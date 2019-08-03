//
//  Utils.swift
//  App1
//
//  Created by John Grese on 8/2/19.
//  Copyright © 2019 Sara Cassidy. All rights reserved.
//

import Foundation

class Utils {
    static func ISO8601Timestamp() -> String {
        return ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: NSDate().timeIntervalSince1970))
    }
}
