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
    

    func getInfo(mediaId: String, finished: @escaping (_ item: [String:String]) ->Void) {
        let newUrl = URL(string: "https://www.googleapis.com/youtube/v3/videos?id=\(mediaId)&part=statistics%2Csnippet&key=\(Constants.YOUTUBE_API_KEY)")
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

    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // Function courtesy: http://stackoverflow.com/questions/37048139/how-to-convert-duration-form-youtube-api-in-swift
    func getYoutubeFormattedDuration(_ durationYT: String) -> String {
        let formattedDuration = durationYT.replacingOccurrences(of: "PT", with: "").replacingOccurrences(of: "H", with:":").replacingOccurrences(of: "M", with: ":").replacingOccurrences(of: "S", with: "")
        
        let components = formattedDuration.components(separatedBy: ":")
        var duration = ""
        for component in components {
            duration = duration.characters.count > 0 ? duration + ":" : duration
            if component.characters.count < 2 {
                duration += "0" + component
                continue
            }
            duration += component
        }
        
        return duration
        
    }
    func getContentDetails(mediaId: String, finished: @escaping (_ item: [String:String]) ->Void) {
        let newUrl = URL(string: "https://www.googleapis.com/youtube/v3/videos?id=\(mediaId)&part=contentDetails&key=\(Constants.YOUTUBE_API_KEY)")
        print("\n\nURL\n\n: ",newUrl)
        print("Item Details")
        var ytItem: [String:String] = [:]
        let task = URLSession.shared.dataTask(with: newUrl! as URL) { (data, response, error) in
            let json = JSON(data: data!)
            if let items = json["items"].array{
                for item in items {
                    ytItem["isYTResult"] = "1"
                    ytItem["duration"] = self.getYoutubeFormattedDuration(item["contentDetails"]["duration"].stringValue)
                    ytItem["liscencedContent"] = item["contentDetails"]["liscencedContent"].stringValue
                }
            }
            finished(ytItem)
        }
        task.resume()
    }
}
