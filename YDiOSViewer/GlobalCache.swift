//
//  GlobalCache.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 3/16/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation

class GlobalCache {
    
    private init() {}

    static let cache:NSCache = NSCache<NSString, AnyObject>()

}
