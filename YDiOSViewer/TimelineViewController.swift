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
            if self.movieId != "" && self.authorId != "" {
                self.clipData = self.dvxApi.getClips(["Movie": self.movieId, "UserId": self.authorId])
                print("The movie ID is \(self.movieId)")
                print("The author id is \(self.authorId)")
                print(self.youTubeInfo)
                print(self.clipData)
                print("Making audio clip data")
                self.makeAudioClipData(self.clipData)
                print("Doing download")
                if !self.clipData.isEmpty {
                    usleep(useconds_t(1500))
                    self.doDownload()
                }
                else {
                    usleep(useconds_t(1500))
                    print("Coming to the minimal section")
                    self.findClipDuration()
                    self.postMarkerPositions(self.getMarkerPositions())
                }
            }
            else {
                usleep(useconds_t(1500))
                print("Coming to the minimal section")
                self.makeAudioClipData([])
                self.findClipDuration()
                self.postMarkerPositions(self.getMarkerPositions())
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
            self.postMarkerPositions(self.getMarkerPositions())
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

    func postMarkerPositions(_ positions: [Float]) {
        NotificationCenter.default.post(name: NSNotification.Name("MarkerPositionsNotification"), object: ["positions": positions])
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
        DispatchQueue.main.async {
        self.videoView.subviews.forEach({ $0.removeFromSuperview() })
        self.audioView.subviews.forEach({ $0.removeFromSuperview() })
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
        var prevOffset: Float = 0.0
        for clip in self.audioClips {
            let scaledStartTime:Float = ((clip.startTime * maxWidth) / videoExtendedDuration) + prevOffset
            let scaledDuration:Float = (clip.duration * maxWidth) / videoExtendedDuration
            let k = AudioView(frame: CGRect(
                origin: CGPoint(x: Int(scaledStartTime), y: self.yStart),
                size: CGSize(width: Int(scaledDuration), height: 10)))
            // Add the view to the view hierarchy so that it shows up on screen
            self.audioView.addSubview(k)
            
            // store points at which video should not be drawn
            if !clip.isInline {
                videoBreaks[scaledStartTime] = scaledDuration
                prevOffset += scaledDuration
            }
        }

            // Draw the last video
            let k = VideoView(frame: CGRect(
                origin: CGPoint(x: Int(0), y: self.yStart),
                size: CGSize(width: Int(maxWidth), height: 10)))
            self.videoView.addSubview(k)
            // We have extended clips
            if !videoBreaks.isEmpty {
            var lastBreak:Float = 0.0
                for (scaledSTime, scaledDuration) in videoBreaks {
                    // draw from last break to scaledStartTime
                    let k = VideoView(frame: CGRect(
                        origin: CGPoint(x: Int(scaledSTime), y: self.yStart),
                        size: CGSize(width: Int(scaledDuration), height: 10)))
                    k.color = UIColor.groupTableViewBackground
                    // Add the view to the view hierarchy so that it shows up on screen
                    self.videoView.addSubview(k)
                    lastBreak = scaledSTime + scaledDuration
                }
            }
            self.videoView.setNeedsDisplay()
            self.audioView.setNeedsDisplay()
        }
    }

    func getMarkerPositions() -> [Float] {
        var positions: [Float] = []
        let maxWidth: Float = Float(self.videoView.frame.width - 4.0)
        var videoExtendedDuration: Float = self.videoDuration
        for clip in self.audioClips {
            if !clip.isInline {
                videoExtendedDuration += clip.duration
            }
        }

        let stepSize: Float = maxWidth / videoExtendedDuration

        print("Step size is \(stepSize)")
        var second: Int = 0
        var viewUnit: Float = 0.0
        while second <= Int(self.videoDuration) {
            positions.append(viewUnit)
            second += 1
            viewUnit += stepSize
        }

        var extendedStartTimes: [Float] = []
        var prevOffset: Float = 0.0
        for clip in self.audioClips {
            extendedStartTimes.append(clip.startTime)
            if !clip.isInline {
                prevOffset += clip.duration
            }
        }
        // offset all the positions
        if self.audioClips.count > 0 {
            for clipIndex in 0...self.audioClips.count-1 {
                if !self.audioClips[clipIndex].isInline {
                    // offset all the subsequent positions
                    var positionIndex: Int = Int(extendedStartTimes[clipIndex]) + 1
                    while positionIndex < positions.count {
                        positions[positionIndex] += ((stepSize) * self.audioClips[clipIndex].duration)
                        positionIndex += 1
                    }
                }
            }
        }
        print("The positions are ")
        print(positions)
        return positions
    }
    
    
    func reloadForAuthoring() {
        youTubeApi.getInfo(mediaId: self.mediaId, finished: { item in
            self.youTubeInfo = item
            if self.movieId != "" {
                let oldAudioClips: [AudioClip] = self.audioClips
                self.clipData = self.dvxApi.getClips(["Movie": self.movieId, "UserId": self.authorId])
                print("The movie ID is \(self.movieId)")
                print("The author id is \(self.authorId)")
                print(self.youTubeInfo)
                print(self.clipData)
                print("Making audio clip data")
                self.makeAudioClipData(self.clipData)
                print("Doing download")
                self.doDownload()
                
                self.findClipDuration()
                self.postMarkerPositions(self.getMarkerPositions())
            }
        })
    }
}
