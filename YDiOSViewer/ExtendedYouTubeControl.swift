//
//  ExtendedYouTubeControl.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/23/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import AVFoundation

class TBSlider: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.minX, y:bounds.minY + 10, width: bounds.size.width, height:10)
    }
}

class ExtendedYouTubeControl: UIStackView, UIPickerViewDelegate, YTPlayerViewDelegate {

    var mediaId: String = ""
    let dvxApi = DvxApi()

    var youtubePlayer: YTPlayerView = YTPlayerView()
    var controlStack: UIStackView = UIStackView()
    var dvGroupStack: UIStackView = UIStackView()

    var playPauseButton: UIButton = UIButton()
    var timeSlider: UISlider = TBSlider()
    var startTimeLabel: UILabel = UILabel()
    var endTimeLabel: UILabel = UILabel()
    var volumeSlider: UISlider = UISlider()
    var describerPickerView: UIPickerView = UIPickerView()
    var authors:[String] = ["Rupal", "Sonal", "Mummy"]
    
    // Audio-related controls
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var avAudioPlayer:AVAudioPlayer?
    var playerLayer = AVPlayerLayer()

    // Variables to keep track of player state
    let audioIndexThreshold:Int = 3
    let skipButtonFrameCount:Float = 10
    var doPlay:Bool = true
    var currentAudioUrl = NSURL(string: "")
    var nextAudioUrl = NSURL(string: "")
    var downloadAudioUrls:[URL] = []
    var failedAudioUrls:[URL] = []
    var allAudioClips: [AnyObject] = []
    var audioClips: [AnyObject] = []
    var activeAudioIndex:Int = 0
    var allMovies : [AnyObject] = []
    var movieID : String?
    var currentAuthor: String?
    var isAudioPlaying: Bool = false
    var isPlaybackActive: Bool = false // Keeps track of user induced pause vs pause for extended descriptions.
    var authorIdList: [String] = []
    var allAuthors: [AnyObject] = []
    var authorMap: [String:String] = [:]
    var currentAuthorId: String?
    var currentMovieTitle: String?
    var currentMovie: AnyObject?
    var doAsyncDownload: Bool = false
    var isFirstDownloaded: Bool = false
    var currentDownloadIndex: Int = 0
    var didAuthorReset: Bool = true
    var doShowMissingAudioWarning: Bool = false
    var previousTime: Float = 0
    var displayAuthor: String?
    var displayAuthorID: String?
    var initialAuthorIndex: Int?
    var currentClipType: Int?

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        self.axis = UILayoutConstraintAxis.vertical
        self.setupPlayer()
        self.setupControlBar()
        self.setupVolumeDescriberControl()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        describerPickerView.delegate = self
        print(frame)

        // Initialize the audio related controls
        audioPlayer=AVPlayer()
        playerLayer=AVPlayerLayer(player: audioPlayer!)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        self.layer.addSublayer(playerLayer)
    }

    private func setupPlayer() {
        youtubePlayer.setPlaybackQuality(YTPlaybackQuality.small)
        if((mediaId) != nil) {
            let options = ["playsinline" : 1, "controls": 0]
            youtubePlayer.load(withVideoId: mediaId, playerVars: options)
            // load the clips for this video.
            //loadClips()
        } else {
            print("Could not find a valid movie")
        }
        addArrangedSubview(youtubePlayer)
    }

    private func setupControlBar() {
        controlStack.axis = UILayoutConstraintAxis.horizontal
        _setupPlayPause()
        controlStack.addArrangedSubview(playPauseButton)
        _setupStartTimeLabel()
        controlStack.addArrangedSubview(startTimeLabel)
        _setupTimeSlider()
        controlStack.addArrangedSubview(timeSlider)
        _setupEndTimeLabel()
        controlStack.addArrangedSubview(endTimeLabel)
        addArrangedSubview(controlStack)
    }

    private func setupVolumeDescriberControl() {
        dvGroupStack.axis = UILayoutConstraintAxis.horizontal
        dvGroupStack.distribution = .fillEqually
        let describerStack = UIStackView()
        describerStack.axis = .vertical
        let describerTitleLabel = UILabel()
        describerTitleLabel.text = "Describer"
        describerTitleLabel.backgroundColor = UIColor.red
        describerStack.distribution = .fillEqually
        describerStack.addArrangedSubview(describerTitleLabel)

        
        let volumeStack = UIStackView()
        volumeStack.axis = .vertical
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 10
        volumeSlider.value = 5
        volumeSlider.backgroundColor = UIColor.blue
        let volumeSliderLabel = UILabel()
        volumeSliderLabel.text = "Audio Volume"
        volumeStack.distribution = .fillEqually
        volumeStack.addArrangedSubview(volumeSliderLabel)
        volumeStack.addArrangedSubview(volumeSlider)
        describerStack.addArrangedSubview(describerPickerView)

        dvGroupStack.addArrangedSubview(volumeStack)
        dvGroupStack.addArrangedSubview(describerStack)
        addArrangedSubview(dvGroupStack)
    }
    
    private func _setupPlayPause() {
        // playPauseButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        playPauseButton.setTitle("Play", for: UIControlState.normal)
        playPauseButton.setTitleColor(UIColor.blue, for: .normal)
        playPauseButton.addTarget(self, action: #selector(ExtendedYouTubeControl.sayHello(button:)), for: .touchUpInside)
    }
    
    private func _setupTimeSlider() {
        timeSlider.maximumValue = 100
        timeSlider.minimumValue = 10
        timeSlider.value = 50
    }

    private func _setupStartTimeLabel() {
        startTimeLabel.text = "0.0"
    }
    private func _setupEndTimeLabel() {
        endTimeLabel.text = "0.0"
    }

    func sayHello(button: UIButton) {
        print("Hello!")
    }
    // Loads all the audio clips based on the selected MediaId
    func loadClips() {
        // get the movieID of the clip
        let selectedMovies = dvxApi.getMovies(["MediaId": mediaId])
        
        //For Youtube videos
        
        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"]
            //self.titleLabel.text = selectedMovies[0]["movieName"] as? String
            //self.currentMovie = selectedMovies[0]
            print("The movie ID is \(movieId)")
            let clips = dvxApi.getClips(["Movie": (movieId!! as AnyObject).description])
            print(clips.description)
            //self.allAudioClips = clips
            //self.authorIdList = getAllAuthors()
            //authorPickerView.reloadAllComponents()
        }
    }
    
    // PICKERView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return authors.count
    }
    // Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return authors[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Pringing this ")
        
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        pickerLabel.text = "HEllo" ///self.authorMap[self.authorIdList[row] as String]
        pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }
    

}
