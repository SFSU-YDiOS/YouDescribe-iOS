//
//  CreateDescriptionTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 3/10/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class CreateDescriptionTableViewCell: UITableViewCell, DownloadAudioDelegate {

    
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblTag: UILabel!
    @IBOutlet weak var lblPath: UILabel!
    @IBOutlet weak var sliderInline: UISwitch!
    var index:Int = 0
    var startTime: Float = 0
    var videoDuration: Float = 0
    var clipId:String = ""
    var clipData: AnyObject!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
    }

    func getTimeComponents(_ currentMarkerTime: Float) -> [String:AnyObject] {
        let hours = (Int(currentMarkerTime)) / (3600) as Int
        let mins = (Int(currentMarkerTime) / 60) % 60
        let secs:Float = Float(Int(Int(currentMarkerTime) % 60) % 60)
        var millisecs:Float = (currentMarkerTime) - floor(currentMarkerTime)
        millisecs = Float(String(format: "%.2f", millisecs))!
        var timeObject: [String: AnyObject] = [:]
        timeObject["hours"] = hours as AnyObject
        timeObject["minutes"] = mins as AnyObject
        timeObject["seconds"] = secs as AnyObject
        timeObject["milliseconds"] = millisecs as AnyObject
        return timeObject
    }
    
    func redrawTimeLabel() {
        let timeObject:[String:AnyObject] = self.getTimeComponents(self.startTime)
        let hours:Int = timeObject["hours"] as! Int
        let mins:Int = timeObject["minutes"] as! Int
        let seconds: Float = timeObject["seconds"] as! Float
        let millisecs: Float = timeObject["milliseconds"] as! Float
        let startTimeString: String = String(format: "%02d:%02d:%05.2f", hours, mins, seconds+millisecs )
        self.lblStartTime.text = startTimeString
        
    }

    @IBAction func onPlayClick(_ sender: Any) {
        print("Clicked on play")
        self.doDownload()
    }

    @IBAction func onDeleteClick(_ sender: Any) {
        print("Clicked on delete")
        NotificationCenter.default.post(name: NSNotification.Name("DeleteClipNotification"), object: ["index":self.index, "startTime": self.startTime, "clipId": self.clipId])
    }

    @IBAction func onNudgeLeftMinClick(_ sender: Any) {
        print("Clicked on nudge left min")
        if self.startTime >= 1.0 {
            self.startTime -= 1.0
            self.redrawTimeLabel()
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":0, "startTime": self.startTime, "clipId": self.clipId])
        }
    }

    @IBAction func onNudgeRightMinClick(_ sender: Any) {
        print("Clicked on nudge right min")
        print("\(self.videoDuration)")
        //if self.startTime < self.videoDuration - 1 { // TODO: Add after querying the youtube api
            self.startTime += 1.0
            self.redrawTimeLabel()
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":0, "startTime": self.startTime, "clipId": self.clipId])
        //}
    }
    
    @IBAction func onNudgeLeftSecClick(_ sender: Any) {
        print("Clicked on nudge left sec")
        if self.startTime >= 0.1 {
            self.startTime -= 0.1
            self.redrawTimeLabel()
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":0, "startTime": self.startTime, "clipId": self.clipId])
        }
    }
    
    @IBAction func onNudgeRightSecClick(_ sender: Any) {
        print("Clicked on nudge right sec")
        //if self.startTime < self.videoDuration - 0.1 { // TODO: Add after querying the youtube
            self.startTime += 0.1
            self.redrawTimeLabel()
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":0, "startTime": self.startTime, "clipId": self.clipId])
        //}
    }

    @IBAction func onSliderToggle(_ sender: Any) {
        if self.sliderInline.isOn {
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":1, "function": "desc_inline", "clipId": self.clipId])
        }
        else {
            NotificationCenter.default.post(name: NSNotification.Name("UpdateClipNotification"), object: ["index":self.index, "operation":1, "function": "desc_extended", "clipId": self.clipId])
        }
    }
    
    func doDownload() {
        print("The download url is ")
        let url: URL = DownloadAudio(delegate: self).getDownloadUrl(metadata: self.clipData)
        print("The URL is \(url.path)")
        let audioUrl:String = DownloadAudio(delegate: self).prepareClipCache(clips: [self.clipData], index: 0)
        print("Returned \(audioUrl)")
    }

    // DownloadAudio Delegate
    func readTotalDownloaded(count: Int) {
    }
    
    // Implementation for the DownloadAudioDelegate
    func readDownloadUrls(urls: [URL]) {
    }

    func registerNewDownload(url: URL, success: Int) {
        print("Finished downloading URL : " + url.absoluteString)
        NotificationCenter.default.post(name: NSNotification.Name("PlayClipNotification"), object: ["index":self.index, "startTime": self.startTime, "path": url])
    }
}
