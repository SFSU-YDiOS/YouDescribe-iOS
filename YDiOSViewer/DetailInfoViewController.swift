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
    var currentAuthor: String = ""
    var audioClips: [AnyObject] = []
    var videoDuration: Float = 0.0
    var apiKey: String = "AIzaSyApPkoF9hjzHB6Wg7cGuOteLLGC3Cpj35s"
    var ytItem:[String:String] = [:]

    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var descriptionContent: UILabel!
    @IBOutlet weak var videoAuthorName: UILabel!
    @IBOutlet weak var viewsCount: UILabel!
    @IBOutlet weak var likesCount: UILabel!
    @IBOutlet weak var dislikesCount: UILabel!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var completenessLabel: UILabel!
    @IBOutlet weak var viewsYDCount: UILabel!
    @IBOutlet var mainView: UIView!

    @IBOutlet weak var mainScrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(self.audioClips)
        print(self.videoDuration)
        self.mainView.isAccessibilityElement = false
        self.mainScrollView.isAccessibilityElement = false
        self.scrollableView.isAccessibilityElement = false
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
                        self.videoAuthorName.text = self.ytItem["movieCreator"]
                        self.viewsCount.text = self.ytItem["movieStatViewCount"]
                        self.likesCount.text = self.ytItem["movieStatLikeCount"]
                        self.dislikesCount.text = self.ytItem["movieStatDislikeCount"]
                        self.completenessLabel.text = self.getDescriptionCompleteness()
                        self.viewsYDCount.text = "\(self.getMaxViewCount())"
                        self.heightConstraint.constant = self.heightConstraint.constant + CGFloat((self.descriptionContent.text?.characters.count)!)
                            self.updateViewConstraints()
                    }
                }
            }
        }
        task.resume()
    }

    func getDescriptionCompleteness() -> String {
        let effort = self.getDescriptionEffort()
        if effort < 0 {
            return "Unavailable"
        }
        else if effort < 0.25 {
            return "Incomplete"
        }
        else if effort < 0.75 {
            return "Underdescribed"
        }
        else {
            return "Well Described"
        }
    }

    // returns the greatest clip download count from among all the clips.
    func getMaxViewCount() -> Int {
        var count: Int = 0
        for clip in self.audioClips {
            if clip["clipAuthor"] as! String == self.currentAuthor {
                if Int(clip["clipDownloadCount"] as! String)! > count {
                    count = Int(clip["clipDownloadCount"] as! String)!
                }
            }
        }
        return count
    }

    // returns a description density to determine the quality
    func getDescriptionEffort() -> Float {

        var numberOfClips: Float = 0
        var firstClipStartTime: Float = -1
        var lastClipStartTime: Float = -1
        var totalVideoDuration: Float = -1

        for clip in self.audioClips {
            if clip["clipAuthor"] as! String == self.currentAuthor {
                numberOfClips += 1
                if firstClipStartTime < 0 {
                    firstClipStartTime = Float(clip["clipStartTime"] as! String)!
                }
                lastClipStartTime = Float(clip["clipStartTime"] as! String)!
            }
        }
        totalVideoDuration = self.videoDuration

        if numberOfClips > 0 && firstClipStartTime >= 0 && lastClipStartTime >= 0 && totalVideoDuration > 0 {
            return ((lastClipStartTime - firstClipStartTime) / totalVideoDuration) * ( numberOfClips / ( totalVideoDuration / 60.0 ))
        }
        else {
            return -1
        }
    }
}


