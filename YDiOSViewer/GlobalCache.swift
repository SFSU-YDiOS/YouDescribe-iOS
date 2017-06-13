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
    static let durationCacheKey: NSString = "duration"

    /*static func getCacheDuration(_ durationMap: [String:String]) -> AnyObject {
        if let cachedVersion = cache.object(forKey: "duration") {
            return cache.object(forKey: "duration")!
        }
        return AnyObject()
    }*/
}
