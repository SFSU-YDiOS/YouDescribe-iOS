//
//  YouTubeApi.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 3/2/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation
import SwiftyJSON

class YouTubeApi {
    
    var apiKey: String = "AIzaSyApPkoF9hjzHB6Wg7cGuOteLLGC3Cpj35s"
    
    func getInfo(mediaId: String, finished: @escaping (_ item: [String:String]) ->Void) {
        let newUrl = URL(string: "https://www.googleapis.com/youtube/v3/videos?id=\(mediaId)&part=statistics%2Csnippet&key=\(apiKey)")
        print("\n\nURL\n\n: ",newUrl)
        print("Item Details")
        var ytItem: [String:String] = [:]
        let task = URLSession.shared.dataTask(with: newUrl! as URL) { (data, response, error) in
            let json = JSON(data: data!)
            if let items = json["items"].array{
                for item in items {
                    ytItem["isYTResult"] = "1"
                    ytItem["movieDescription"] = item["snippet"]["description"].stringValue
                    ytItem["movieName"] = item["snippet"]["title"].stringValue
                    ytItem["movieCreator"] = item["snippet"]["channelTitle"].stringValue
                    ytItem["movieChannel"] = item["channelTitle"].stringValue
                    ytItem["movieStatViewCount"] = item["statistics"]["viewCount"].stringValue
                    ytItem["movieStatLikeCount"] = item["statistics"]["likeCount"].stringValue
                    ytItem["movieStatDislikeCount"] = item["statistics"]["dislikeCount"].stringValue
                }
            }
            finished(ytItem)
        }
        
        task.resume()
    }
}
