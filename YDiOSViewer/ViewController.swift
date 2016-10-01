//
//  ViewController.swift
//  YDiOSViewer
//
//  Created by Rupal Khilari on 9/27/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController, YTPlayerViewDelegate  {

    let dvxApi = DxvApi()
    var doPlay:Bool = true
    let audioUrl = NSURL(string: "https://dl.dropboxusercontent.com/u/57189163/testoutput.mp3")
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var audioClips: [AnyObject] = []
    var activeAudioIndex:Int = 0

    @IBOutlet weak var debugView: UITextView!
    @IBOutlet weak var youtubePlayer: YTPlayerView!
    @IBOutlet weak var movieText: UITextField!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var authorText: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var nextClipAtLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.youtubePlayer.delegate = self
        
        let allMovies = dvxApi.getMovies([:])

        //print(allMovies)
        debugView.text = allMovies.description
        loadAudio()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadClips() {
        // get the movieID of the clip
        let selectedMovies = dvxApi.getMovies(["MediaId": movieText.text!])
        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"];
            let clips = dvxApi.getClips(["Movie": movieId!!.description])
            print("The clips are")
            print(clips.description)
            debugView.text = debugView.text + clips.description
            self.audioClips = clips
        }
    }

    func loadAudio() {
        // play the audio link
        audioPlayerItem = AVPlayerItem(URL: audioUrl!)
        audioPlayer=AVPlayer(playerItem: audioPlayerItem!)
        let playerLayer=AVPlayerLayer(player: audioPlayer!)
        playerLayer.frame=CGRectMake(0, 0, 300, 50)
        self.view.layer.addSublayer(playerLayer)
    }
    func playAudio() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: audioPlayer?.currentItem)
        audioPlayer?.play()
    }
    func playerDidFinishPlaying(note: NSNotification) {
        print("Resume video playing:")
        youtubePlayer.playVideo()
        activeAudioIndex = activeAudioIndex + 1
        showNextClipStartTime()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: audioPlayer?.currentItem)
        loadAudio()

    }
    func stopAudio() {
        audioPlayer?.pause()
    }
    @IBAction func loadMovie(sender: AnyObject) {
        if((movieText.text) != nil) {
            let options = ["playsinline" : 1]
            youtubePlayer.loadWithVideoId(movieText.text!, playerVars: options)
            // load the clips for this video.
            loadClips()
        } else {
            print("Could not find a valid movie")
        }
    }
    @IBAction func playPauseAction(sender: AnyObject) {
        if(doPlay) {
            youtubePlayer.playVideo()
        } else {
            youtubePlayer.pauseVideo()
        }
    }

    @IBAction func stopAction(sender: AnyObject) {
        reset()
    }

    func reset() {
        youtubePlayer.stopVideo()
        audioPlayer?.pause()
        loadAudio()
        activeAudioIndex = 0
        doPlay = true
    }
    @IBAction func startAction(sender: AnyObject) {
        // filter the clips according to the authors
        var filteredClips:[AnyObject] = []
        for audioClip in self.audioClips {
            if (audioClip["clipAuthor"]!!.description == authorText.text) {
                filteredClips.append(audioClip)
            }
        }
        self.audioClips = filteredClips
        showNextClipStartTime()
        print("Filtered clips by Author")
    }
    func showNextClipStartTime() {
        if (!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
            self.nextClipAtLabel.text = self.audioClips[activeAudioIndex]["clipStartTime"]!!.description
        }
    }
    // from the YoutubePlayerDelegate TODO: Move to a separate component
    func playerView(playerView: YTPlayerView, didPlayTime playTime: Float)
    {
        self.playerLabel.text = "\(playTime)"
        /*if (Int(ceil(playTime)) > 2) {
            youtubePlayer.pauseVideo()
        }*/
        //youtubePlayer.seekToSeconds(2.2, allowSeekAhead: true);
        // Check if we have reached the point in the video
        if(!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
            print(self.audioClips[activeAudioIndex])
            print(Float(floor(playTime)))
            print(Float(self.audioClips[activeAudioIndex]["clipStartTime"]!!.description))
            if Float(floor(playTime)) == Float(self.audioClips[activeAudioIndex]["clipStartTime"]!!.description) {
                print("Starting audio at seconds:" + self.audioClips[activeAudioIndex]["clipStartTime"]!!.description)
                print("Pausing Video")
                youtubePlayer.pauseVideo()
                print("Playing Audio")
                playAudio()
            }
        }
    }
    func playerViewDidBecomeReady(playerView: YTPlayerView) {
        print("The video player is now ready")
    }
    
    func playerView(playerView: YTPlayerView, didChangeToState state: YTPlayerState) {
        // the player changed to state
        print(state.rawValue)
        if (state.rawValue == 2) { // state is 'playing'
            //change the button to text
            playButton.setTitle("Pause", forState: UIControlState.Normal)
            doPlay = false
        }
        else if (state.rawValue == 3) {
            playButton.setTitle("Play", forState: UIControlState.Normal)
            doPlay = true
        }
        else if (state.rawValue == 5) {
            playButton.setTitle("Play", forState: UIControlState.Normal)
            doPlay = true
        }
    }
}

