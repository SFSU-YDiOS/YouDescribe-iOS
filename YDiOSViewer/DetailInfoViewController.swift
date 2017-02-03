//
//  DetailInfoViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 1/20/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import SwiftyJSON

class DetailInfoViewController: UIViewController {

    var mediaId: String = ""
    var apiKey: String = "AIzaSyApPkoF9hjzHB6Wg7cGuOteLLGC3Cpj35s"
    var ytItem:[String:String] = [:]

    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var descriptionContent: UILabel!
    @IBOutlet weak var videoAuthorName: UILabel!
    @IBOutlet weak var viewsCount: UILabel!
    @IBOutlet weak var likesCount: UILabel!
    @IBOutlet weak var dislikesCount: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("This is the video ID ")
        print(mediaId)
        //
        //
        //
        
        getInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getInfo() {
        let newUrl = URL(string: "https://www.googleapis.com/youtube/v3/videos?id=\(mediaId)&part=statistics%2Csnippet&key=\(apiKey)")
        print("\n\nURL\n\n: ",newUrl)
        print("Item Details")
        let task = URLSession.shared.dataTask(with: newUrl! as URL) {(data, response, error) in
            let json = JSON(data: data!)
            if let items = json["items"].array{
                for item in items{
                    print(item)
                    self.ytItem["isYTResult"] = "1"
                    self.ytItem["movieDescription"] = item["snippet"]["description"].stringValue
                    self.ytItem["movieName"] = item["snippet"]["title"].stringValue
                    self.ytItem["movieCreator"] = item["snippet"]["channelTitle"].stringValue
                    self.ytItem["movieChannel"] = item["channelTitle"].stringValue
                    self.ytItem["movieStatViewCount"] = item["statistics"]["viewCount"].stringValue
                    self.ytItem["movieStatLikeCount"] = item["statistics"]["likeCount"].stringValue
                    self.ytItem["movieStatDislikeCount"] = item["statistics"]["dislikeCount"].stringValue
                    DispatchQueue.main.async() {
                        self.titleName.text = self.ytItem["movieName"]
                        self.descriptionContent.text = self.ytItem["movieDescription"]
                        self.descriptionContent.lineBreakMode = .byWordWrapping
                        self.descriptionContent.numberOfLines = 0
                        self.descriptionContent.adjustsFontSizeToFitWidth = true
                        // self.descriptionContent.sizeToFit()
                        //self.descriptionTextView.text = self.ytItem["movieDescription"]
                        self.videoAuthorName.text = self.ytItem["movieCreator"]
                        self.viewsCount.text = self.ytItem["movieStatViewCount"]
                        self.likesCount.text = self.ytItem["movieStatLikeCount"]
                        self.dislikesCount.text = self.ytItem["movieStatDislikeCount"]
                    }
                    
                }
            }
        }
        task.resume()

    }
}


