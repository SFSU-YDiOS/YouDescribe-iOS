//
//  TimelineViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/13/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import AVFoundation

class TimelineViewController: UIViewController, DownloadAudioDelegate {

    var youTubeInfo: [String:String] = [:]
    var clipData: [AnyObject] = []
    var videoDuration: Float = 0.0
    var audioClips: [AudioClip] = []
    var totalDownloaded: Int = 0
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var audioView: UIView!

    var movieId: String = ""
    var mediaId: String = ""
    var authorId: String = ""
    var youTubeApi = YouTubeApi()
    var dvxApi = DvxApi()
    let yStart:Int = 7
    let barHeight:Int = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // make sure we have all the required data
        youTubeApi.getInfo(mediaId: self.mediaId, finished: { item in
            self.youTubeInfo = item
            if self.movieId != "" {
                self.clipData = self.dvxApi.getClips(["Movie": self.movieId, "UserId": self.authorId])
                print("The movie ID is \(self.movieId)")
                print("The author id is \(self.authorId)")
                print(self.youTubeInfo)
                print(self.clipData)
                print("Making audio clip data")
                self.makeAudioClipData(self.clipData)
                print("Doing download")
                self.doDownload()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func doDownload() {
        var counter: Int = 0
        for clip in clipData {
            let url: URL = DownloadAudio(delegate: self).getDownloadUrl(metadata: clip)
            print("The URL is \(url.path)")
            let audioUrl:String = DownloadAudio(delegate: self).prepareClipCache(clips: [clip], index: 0)
            print("Returned \(audioUrl)")
            counter += 1
            // Find the appropriate AudioClip to populate (not very efficient by ok for now)
            for audioClip in self.audioClips {
                if audioClip.startTime == Float(clip["clipStartTime"] as! String) {
                    audioClip.audioFile = url
                }
            }
        }
    }
    
    // DownloadAudio Delegate
    func readTotalDownloaded(count: Int) {
    }
    
    // Implementation for the DownloadAudioDelegate
    func readDownloadUrls(urls: [URL]) {
    }
    
    func registerNewDownload(url: URL, success: Int) {
        print("Finished downloading URL : " + url.absoluteString)
        print(url)
        totalDownloaded += 1
        if totalDownloaded == self.audioClips.count {
            sleep(1) // To make sure all the data is saved.
            print("Finding the clip durations since all clips have downloaded")
            self.findClipDuration()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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

    func makeAudioClipData(_ clipData: [AnyObject]) {
        var counter: Int = 0
        self.audioClips = []
        for clip in clipData {
            var audioClip: AudioClip!
            audioClip = AudioClip()
            let clip1: [String: AnyObject] = clip as! [String : AnyObject]
            audioClip.startTime = Float(clip1["clipStartTime"] as! String)
            let timeObject:[String:AnyObject] = self.getTimeComponents(audioClip.startTime)
            audioClip.startHour = timeObject["hours"] as! Int
            audioClip.startMinutes = timeObject["minutes"] as! Int
            audioClip.startSeconds = timeObject["seconds"] as! Float
            let milli:Float = timeObject["milliseconds"] as! Float
            audioClip.startSeconds = audioClip.startSeconds + milli
            audioClip.id = clip1["clipId"] as! String
            audioClip.index = counter
            audioClip.data = clip
            if clip1["clipFunction"] as! String == "desc_inline" {
                audioClip.isInline = true
            }
            else {
                audioClip.isInline = false
            }
            counter += 1
            self.audioClips.append(audioClip)
        }

        func sortFilter(this:AudioClip, that:AudioClip) -> Bool {
            return this.startTime < that.startTime
        }
        self.audioClips.sort(by: sortFilter)
    }

    func findClipDuration() {
        for clip in self.audioClips {
            let asset = AVURLAsset(url: clip.audioFile)
            print("Duration of \(clip.audioFile.absoluteString) is ")
            print(Float(CMTimeGetSeconds(asset.duration)))
            clip.duration = Float(CMTimeGetSeconds(asset.duration))
        }
        // now we can draw them on the canvas
        // duration corresponds to the width of the screen.
        self.drawTimeline()
    }

    func drawTimeline() {
        var videoExtendedDuration: Float = self.videoDuration
        var videoBreakPoints: [Float:Float] = [:]
        var totalOffset: Float = 0.0
        var lastVideoClipStart: Float = 0.0
        var extendedClips: [AudioClip] = []
        for clip in self.audioClips {
            if !clip.isInline {
                videoExtendedDuration += clip.duration
                videoBreakPoints[clip.startTime + totalOffset] = 0.0
                totalOffset += clip.duration
                extendedClips.append(clip)
            }
        }

        print("Video extended duration \(videoExtendedDuration)")
        let maxWidth: Float = Float(self.videoView.frame.width - 4.0)
        print("The max width is \(maxWidth)")

        
        /////////////
        var videoBreaks: [Float:Float] = [:]
        // Draw the audio sub views
        lastVideoClipStart = 0.0
        for clip in self.audioClips {
            let scaledStartTime:Float = (clip.startTime * maxWidth) / videoExtendedDuration
            let scaledDuration:Float = (clip.duration * maxWidth) / videoExtendedDuration
            let k = AudioView(frame: CGRect(
                origin: CGPoint(x: Int(scaledStartTime), y: yStart),
                size: CGSize(width: Int(scaledDuration), height: 10)))
            // Add the view to the view hierarchy so that it shows up on screen
            self.audioView.addSubview(k)
            
            // store points at which video should not be drawn
            if !clip.isInline {
                videoBreaks[scaledStartTime] = scaledDuration
            }
        }
        
        if videoBreaks.isEmpty {
            // No extended clips - draw from 0 to end
            let k = VideoView(frame: CGRect(
                origin: CGPoint(x: Int(0.0), y: yStart),
                size: CGSize(width: Int(maxWidth), height: 10)))
            // Add the view to the view hierarchy so that it shows up on screen
            self.videoView.addSubview(k)
        }
        else {
            // Draw the last video
            let k = VideoView(frame: CGRect(
                origin: CGPoint(x: Int(0), y: yStart),
                size: CGSize(width: Int(maxWidth), height: 10)))
            self.videoView.addSubview(k)
            // We have extended clips
            var lastBreak:Float = 0.0
            for (scaledSTime, scaledDuration) in videoBreaks {
                // draw from last break to scaledStartTime
                let k = VideoView(frame: CGRect(
                    origin: CGPoint(x: Int(scaledSTime), y: yStart),
                    size: CGSize(width: Int(scaledDuration), height: 10)))
                k.color = UIColor.groupTableViewBackground
                // Add the view to the view hierarchy so that it shows up on screen
                self.videoView.addSubview(k)
                lastBreak = scaledSTime + scaledDuration
            }
        }
    }
    
}
