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
    //let audioUrl = NSURL(string: "https://dl.dropboxusercontent.com/u/57189163/testoutput.mp3")
    let audioUrl = URL(string: "http://www.wavsource.com/snds_2016-09-25_6739387469794827/tv/game_of_thrones/got_s1e3_easier_war.wav")
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var audioClips: [AnyObject] = []
    var activeAudioIndex:Int = 0
    var allMovies : [AnyObject] = []
    var movieID : String?

    //@IBOutlet weak var debugView: UITextView!
    @IBOutlet weak var youtubePlayer: YTPlayerView!
    //@IBOutlet weak var movieText: UITextField!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var authorText: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var nextClipAtLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.youtubePlayer.delegate = self
        
        allMovies = dvxApi.getMovies([:])

        print("all movies count =")
        print(allMovies)
        print(allMovies.count)
        //debugView.text = allMovies.description
        loadAudio()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadClips() {
        // get the movieID of the clip
        let selectedMovies = dvxApi.getMovies(["MediaId": movieID!])
        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"];
            let clips = dvxApi.getClips(["Movie": (movieId!! as AnyObject).description])
            print("The clips are")
            print(clips.description)
            //debugView.text = debugView.text + clips.description
            self.audioClips = clips
        }
    }

    func loadAudio() {
        // play the audio link
        audioPlayerItem = AVPlayerItem(url: audioUrl!)
        audioPlayer=AVPlayer(playerItem: audioPlayerItem!)
        let playerLayer=AVPlayerLayer(player: audioPlayer!)
        playerLayer.frame=CGRect(x: 0, y: 0, width: 300, height: 50)
        self.view.layer.addSublayer(playerLayer)
    }
    func playAudio() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        audioPlayer?.play()
    }
    func playerDidFinishPlaying(_ note: Notification) {
        print("Resume video playing:")
        youtubePlayer.playVideo()
        activeAudioIndex = activeAudioIndex + 1
        showNextClipStartTime()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        loadAudio()

    }
    func stopAudio() {
        audioPlayer?.pause()
    }
    @IBAction func loadMovie(_ sender: AnyObject) {
        if((movieID) != nil) {
            let options = ["playsinline" : 1]
            youtubePlayer.load(withVideoId: movieID!, playerVars: options)
            // load the clips for this video.
            loadClips()
        } else {
            print("Could not find a valid movie")
        }
    }
    @IBAction func playPauseAction(_ sender: AnyObject) {
        if(doPlay) {
            youtubePlayer.playVideo()
        } else {
            youtubePlayer.pauseVideo()
        }
    }

    @IBAction func stopAction(_ sender: AnyObject) {
        reset()
    }

    func reset() {
        youtubePlayer.stopVideo()
        audioPlayer?.pause()
        loadAudio()
        activeAudioIndex = 0
        doPlay = true
    }
    @IBAction func startAction(_ sender: AnyObject) {
        // filter the clips according to the authors
        var filteredClips:[AnyObject] = []
        for audioClip in self.audioClips {
            if ((audioClip["clipAuthor"]!! as AnyObject).description == authorText.text) {
                filteredClips.append(audioClip)
            }
        }
        self.audioClips = filteredClips
        showNextClipStartTime()
        print("Filtered clips by Author")
    }
    func showNextClipStartTime() {
        if (!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
            self.nextClipAtLabel.text = (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description
        }
    }
    // from the YoutubePlayerDelegate TODO: Move to a separate component
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float)
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
            print(Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description))
            if Float(floor(playTime)) == Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description) {
                print("Starting audio at seconds:" + (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)
                print("Pausing Video")
                youtubePlayer.pauseVideo()
                print("Playing Audio")
                playAudio()
            }
        }
    }
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        print("The video player is now ready")
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        // the player changed to state
        print(state.rawValue)
        if (state.rawValue == 2) { // state is 'playing'
            //change the button to text
            playButton.setTitle("Pause", for: UIControlState())
            doPlay = false
        }
        else if (state.rawValue == 3) {
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
        }
        else if (state.rawValue == 5) {
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
        }
    }
    
}

