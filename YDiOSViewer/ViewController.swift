import UIKit
import AVKit
import AVFoundation
import Foundation
import Social

class ViewController: UIViewController, YTPlayerViewDelegate, DownloadAudioDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    let dvxApi = DvxApi()
    let youTubeApi = YouTubeApi()
    let audioIndexThreshold:Int = 3
    let skipButtonFrameCount:Float = 10

    var doPlay:Bool = true
    var currentAudioUrl = NSURL(string: "")
    var nextAudioUrl = NSURL(string: "")
    var downloadAudioUrls:[URL] = []
    var failedAudioUrls:[URL] = []
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var avAudioPlayer:AVAudioPlayer?
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
    var displayAuthorID: String = ""
    var initialAuthorIndex: Int?
    var currentClipType: Int?
    var movieIdLocal: String = ""
    var videoDurationInSeconds: Float =  0.0
    var videoDurationString: String = ""
    var isEmbedded: Bool = false
    var hasDescription: Bool = true
    var showTimeline: Bool = true
    var isControlSliderDown: Bool = false
    var markerPositions: [Float] = []
    var overrideAuthorId: String = ""

    @IBOutlet weak var youtubePlayer: YTPlayerView!
    //@IBOutlet weak var authorText: UITextField!
    @IBOutlet weak var nextClipAtLabel: UILabel!
    @IBOutlet weak var authorPickerView: UIPickerView!
    var tester: Int = 0

    var playerLayer = AVPlayerLayer()
    @IBOutlet weak var volumeWrapperView: UIView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var aboutButton: UIBarButtonItem!
    @IBOutlet weak var audioVolumeSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var clipCountLabel: UILabel!
    @IBOutlet weak var timelineContainer: UIView!
    @IBOutlet weak var currentClipIndexLabel: UILabel!
    @IBOutlet weak var timelineSliderImage: UIImageView!
    @IBOutlet weak var controlEndTimeLabel: UILabel!
    @IBOutlet weak var controlStartTimeLabel: UILabel!
    @IBOutlet weak var controlPlayPauseButton: UIButton!
    @IBOutlet weak var currentDescriptionInfo: UILabel!
    @IBOutlet weak var controlSlider: UISlider!
    @IBOutlet weak var toolbarControls: UIToolbar!
    @IBOutlet weak var describerLabel: UILabel!
    @IBOutlet weak var descriptionVolumeLabel: UILabel!

    @IBOutlet weak var createDescriptionButton: UIButton!
    @IBOutlet weak var createDescriptionView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.youtubePlayer.delegate = self
        self.authorPickerView.delegate = self
        self.authorPickerView.dataSource = self
        //self.hideKeyboardOnTap()

        // register notifications
        // Add notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.saveMarkerPositions(_:)), name: NSNotification.Name("MarkerPositionsNotification"), object: nil)

        //DownloadAudio(delegate: self).doSimpleDownload()
        loadMovie(self)
        self.allAuthors = dvxApi.getUsers([:])
        self.authorMap = getAuthorMap()
        self.doAsyncDownload = false
        self.isFirstDownloaded = false
        self.doShowMissingAudioWarning = false

        //audioPlayerItem = nil
        audioPlayer=AVPlayer()
        playerLayer=AVPlayerLayer(player: audioPlayer!)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        self.view.layer.addSublayer(playerLayer)

        // Audio duck if required.
        //let control = VolumeControl()
        //control.setVolume(0.0)
        
        // Make volume controller
        //control.drawControl(self.volumeWrapperView)

        // select the right author in the pickerview
        var row: Int = 0
        print(self.authorMap)
        for author in self.authorIdList {
            print(author)
            if self.authorMap[author] == self.displayAuthor {
                self.currentAuthorId = author
                break
            }
            row += 1
        }
        self.initialAuthorIndex = row
        authorPickerView.selectRow(self.initialAuthorIndex!, inComponent: 0, animated: false)
        authorPickerView.reloadAllComponents()
        
        // Remove the back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // setting the default playback quality to lowest
        youtubePlayer.setPlaybackQuality(YTPlaybackQuality.small)
        
        // Update the clips label after the author id is updated.
        self.updateClipCountFromAuthor()
        
        // Update the control slider maxrange and the end label
        self.updateSliderTimeInfo()
        
        // update the display for the player in embedded mode
        if self.isEmbedded {
            self.updateForEmbed()
        }
        
        if self.hasDescription {
            self.createDescriptionView.isHidden = true
        }
        else {
            self.createDescriptionView.isHidden = false
            self.timelineContainer.isHidden = true
            self.describerLabel.isHidden = true
            self.descriptionVolumeLabel.isHidden = true
            self.authorPickerView.isHidden = true
            self.audioVolumeSlider.isHidden = true
            self.timelineSliderImage.isHidden = true
        }
        
        // show/hide the timeline display depending on the requirement
        if !self.showTimeline {
            self.timelineContainer.isHidden = true
        }
        // Add tap gesture recognizer to the slider
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.sliderTapped(_:)))
        self.controlSlider.addGestureRecognizer(tapGesture)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController {
            self.reset()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Audio session control
    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.duckOthers)
            try session.setActive(true)
            audioPlayer?.play()
            audioPlayer?.volume = 10.0
        } catch let error as Error {
            print ("audio session error occured")
            print(error)
        }

    }
    
    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        }
        catch let error as Error {
            print("deactivate error")
            print(error)
        }
    }

    func reactivateSession() {
        audioPlayer?.pause()
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            //audioPlayer?.pause()
        } catch let error as Error {
            print ("audio session error occured")
            print(error)
        }
        
    }
    
    func updateSliderTimeInfo() {
        self.controlEndTimeLabel.text = self.videoDurationString
        self.controlSlider.maximumValue = self.videoDurationInSeconds * 1000
        self.timelineSliderImage.center.x = self.timelineContainer.subviews[0].subviews[1].frame.minX
    }

    // Hides the controls that are not necessary while embedding it in another controller
    func updateForEmbed() {
        self.authorPickerView.isHidden = true
        self.describerLabel.isHidden = true
        self.descriptionVolumeLabel.isHidden = true
        self.toolbarControls.isHidden = true
        self.audioVolumeSlider.isHidden = true
        self.createDescriptionView.isHidden = true
    }

    // Loads all the audio clips based on the selected MediaId
    func loadClips() {
        // get the movieID of the clip
        let selectedMovies = dvxApi.getMovies(["MediaId": movieID!])
        
        //For Youtube videos

        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"]
            self.titleLabel.text = selectedMovies[0]["movieName"] as? String
            self.currentMovie = selectedMovies[0]
            let clips = dvxApi.getClips(["Movie": (movieId!! as AnyObject).description])
            print(clips.description)
            self.allAudioClips = clips
            self.authorIdList = getAllAuthors()
            authorPickerView.reloadAllComponents()
        } else {
            self.titleLabel.text = self.currentMovieTitle
        }
    }

    func getAllAuthors() -> [String] {
        var authorIds:[String] = []
        if (self.allAudioClips.count > 0) {
            for audioClip in self.allAudioClips {
                let authorId:String = audioClip["clipAuthor"] as! String
                if !authorIds.contains(authorId) {
                    authorIds.append(authorId)
                }
            }
        }
        if (authorIds.count > 0) {
            if self.overrideAuthorId != "" {
                self.currentAuthorId = self.overrideAuthorId
            }
            else {
                self.currentAuthorId = authorIds[0]
            }
            self.currentAuthor = self.displayAuthor
        }
        else {
            if self.movieID != nil {
                self.showMissingAuthors()
            }
        }
        return authorIds
    }

    func showMissingAuthors() {
        /*let alertController = UIAlertController(title: "Warning!", message: "Cannot find any audio clip metadata for this video although it appears to have been described previously.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
        }
        
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)*/
    }

    func getAuthorMap() -> [String:String] {
        if (self.allAuthors.count > 0) {
            for author in self.allAuthors {
                self.authorMap[author["userId"] as! String] = author["userHandle"] as? String
            }
        }
        return self.authorMap
    }

    // Replaces the current audio player item with that in currentAudioUrl
    func loadAudio() {
        // play the audio link
        if self.failedAudioUrls.contains(currentAudioUrl! as URL) {
            let myUrl = URL(string: "https://www.dropbox.com/s/xr640am1tv564ob/point1sec.mp3?raw=1")
            audioPlayerItem = AVPlayerItem(url: myUrl!)
        }
        else {
            audioPlayerItem = AVPlayerItem(url: currentAudioUrl! as URL)
        }
        if audioPlayerItem != nil {
            audioPlayer?.replaceCurrentItem(with: audioPlayerItem)
        }
    }

    // Play the audio - Also tries to precache the next audio clip as the current is playing
    func playAudio() {
        print("The current item is \(audioPlayer?.currentItem)")
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerErrorTest(_:)), name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: audioPlayer?.currentItem)
        //self.activateAudioSession()
        print("The current time is \(audioPlayer?.currentItem?.currentTime())")
        audioPlayer?.play()
        self.isAudioPlaying = true
        self.isPlaybackActive = true
        // Pre-cache the next clip
        if self.audioClips.count > 0 && activeAudioIndex < self.audioClips.count-1 {
            self.nextAudioUrl = self.downloadAudioUrls[activeAudioIndex+1] as NSURL
            print("NEXT URL IS \(self.nextAudioUrl)")
        }
    }
    
    func updateClipCountFromAuthor() {
        var clipCount: Int = 0
        for clip in self.allAudioClips {
            let authorId:String = clip["clipAuthor"] as! String
            if authorId == self.currentAuthorId {
                clipCount += 1
            }
        }
        DispatchQueue.main.async {
            if clipCount == 1 {
                self.clipCountLabel.text = "\(clipCount)"
            }
            else {
                self.clipCountLabel.text = "\(clipCount)"
            }
        }
    }

    // Called when the audio clip finishes playing
    func playerDidFinishPlaying(_ note: Notification) {
        self.isAudioPlaying = false
        activeAudioIndex = activeAudioIndex + 1
        showNextClipStartTime()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        if self.nextAudioUrl != self.currentAudioUrl {
            self.currentAudioUrl = self.nextAudioUrl
            loadAudio()
        }
        
        // If the pause button was pressed, don't resume video.
        if self.isPlaybackActive {
            print("Resume video playing:")
            youtubePlayer.playVideo()
        }
    }

    func playerErrorTest(_ note: Notification) {
        print("ERRIR in playing")
    }
    func resetAudio() {
        self.isAudioPlaying = false
        //youtubePlayer.playVideo()
        showNextClipStartTime()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        if youtubePlayer.playerState().rawValue != 5 {
            if self.nextAudioUrl != self.currentAudioUrl {
                self.currentAudioUrl = self.nextAudioUrl
                loadAudio()
            }
        }
    }

    func stopAudio() {
        audioPlayer?.pause()
    }

    // Called when the movie is loaded
    @IBAction func loadMovie(_ sender: AnyObject) {
        if((movieID) != nil) {
            let options = ["playsinline" : 1, "controls" : 0]
            youtubePlayer.load(withVideoId: movieID!, playerVars: options)
            // load the clips for this video.
            loadClips()
            self.controlSlider.value = Float(self.youtubePlayer.duration())
        } else {
            print("Could not find a valid movie")
        }
    }

    // Called on clicking the Play/Pause toggle button
    @IBAction func playPauseAction(_ sender: AnyObject) {
        self.startPlay()
       /* let timelineViewController = TimelineViewController()
        // Get the YouTube Info for this video, and the movie ID
        youTubeApi.getInfo(mediaId: self.movieID!, finished: { item in
            timelineViewController.youTubeInfo = item
            let clipData = self.dvxApi.getClips(["Movie": self.currentMovie!["movieId"] as! String, "UserId": self.currentAuthorId!])
            timelineViewController.clipData = clipData
            timelineViewController.videoDuration = Float(self.youtubePlayer.duration())
            self.timelineContainer.addSubview(timelineViewController.view)
        })*/
    }

    func playPreStartAudio() {
        // Check if there is any audio that might not be triggered by the player's events.
        
    }
    func startPlay() {
        if(doPlay) {
            if self.didAuthorReset {
                self.filterAndDownloadAudioClips()
                self.didAuthorReset = false
            }
            youtubePlayer.playVideo()
            self.isPlaybackActive = true
        } else {
            // Stop video and audio atomically
            youtubePlayer.pauseVideo()
            print("Pausing audio")
            audioPlayer?.pause()
            self.isAudioPlaying = false
            self.isPlaybackActive = false
        }
        self.applyPlayPauseLabel()
    }

    func startAnimating() {
        UIView.animate(withDuration: 0.75, delay: 0, options: .curveLinear, animations: {
            // this will change Y position of your imageView center
            // by 1 every time you press button
            self.timelineSliderImage.center.x += 0.1
        }, completion: nil)
    }
    
    func drawUpdatedMarker() {
        if self.hasDescription {
        let markerIndex: Int = Int(youtubePlayer.currentTime())
            if self.timelineContainer.subviews[0].subviews.count > 1 {
                self.timelineSliderImage.center.x = self.timelineContainer.subviews[0].subviews[1].frame.minX + CGFloat(self.markerPositions[markerIndex])
            }
        }
    }

    // Apply the play/pause label depending on the current state 
    // of the audio and video player
    func applyPlayPauseLabel() {
        if self.isPlaybackActive == true {
            //playButton.setTitle("Pause", for: UIControlState())
            playButton.setImage(#imageLiteral(resourceName: "Pause") , for: UIControlState())
            controlPlayPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: UIControlState())
            self.doPlay = false
        }
        else {
            //playButton.setTitle("Play", for: UIControlState())
            playButton.setImage(#imageLiteral(resourceName: "Play"), for: UIControlState())
            controlPlayPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: UIControlState())
            self.doPlay = true
        }
    }
    // Called on clicking the 'stop' button
    @IBAction func stopAction(_ sender: AnyObject) {
        self.reset()
        self.isPlaybackActive = false
    }

    // Resets the state of both the audio and video players
    func reset() {
        youtubePlayer.stopVideo()
        activeAudioIndex = 0
        if self.downloadAudioUrls.count >= 1 {
            self.audioPlayer?.replaceCurrentItem(with: nil)
            self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
        }
        loadAudio()
        doPlay = true
        resetActiveAudioIndex()
        showNextClipStartTime()
        self.nextClipAtLabel.text = ""
        audioPlayer?.pause()
    }

    @IBAction func skipBackAction(_ sender: AnyObject) {

        // Seek to 0
        if (youtubePlayer.currentTime() - skipButtonFrameCount < 0) {
            youtubePlayer.seek(toSeconds: 0, allowSeekAhead: true)
        }
        else if (youtubePlayer.currentTime() >= 0) {
            youtubePlayer.seek(toSeconds: youtubePlayer.currentTime() - skipButtonFrameCount, allowSeekAhead: true)
        }

        self.stopAudio()
        if self.downloadAudioUrls.count == 0 {
            filterAndDownloadAudioClips()
        }
        youtubePlayer?.playVideo()
    }
    
    @IBAction func skipForwardAction(_ sender: AnyObject) {
        youtubePlayer.seek(toSeconds: youtubePlayer.currentTime() + skipButtonFrameCount, allowSeekAhead: true)
        youtubePlayer?.playVideo()
        resetActiveAudioIndex()
        self.stopAudio()
    }
    
    // Re-calculate the activeAudioIndex based on the current frame playing
    func resetActiveAudioIndex() {
        var foundIndex: Bool = false
        if self.audioClips.count > 0 {
            // find the appropriate start index and assign it to activeAudioIndex.
            var index:Int = 0
            for _ in self.audioClips {
                if Float((self.audioClips[index]["clipStartTime"]!! as AnyObject).description)! >= Float(youtubePlayer.currentTime()) {
                    activeAudioIndex = index
                    print("Assigned as activeaudioindex \(self.activeAudioIndex)")
                    showNextClipStartTime()
                    self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
                    loadAudio()
                    foundIndex = true
                    break
                }
                index = index + 1
            }
            if !foundIndex {
                activeAudioIndex = self.audioClips.count
                self.showNextClipStartTime()
            }
        }
    }

    func filterAndDownloadAudioClips() {
        // filter the clips according to the authors
        var filteredClips:[AnyObject] = []
        for audioClip in self.allAudioClips {
            if ((audioClip["clipAuthor"]!! as AnyObject).description == self.currentAuthorId) {
                filteredClips.append(audioClip)
            }
        }

        self.audioClips = filteredClips
        doPlay = true
        // Load the first clip content of the set of clips
        if self.audioClips.count > 0 {
            print("Starting to download all clips from Author:" + self.currentAuthorId!)
            self.failedAudioUrls = []
            if self.doAsyncDownload {
                DownloadAudio(delegate: self).prepareAllClipCache(clips: self.audioClips)
            }
            else {
                print("Downloading file...")
                self.downloadAudioUrls = []
                self.downloadAudioUrls.append(DownloadAudio(delegate: self).getDownloadUrl(metadata: self.audioClips[0]))
                let audioUrl:String = DownloadAudio(delegate: self).prepareClipCache(clips: self.audioClips, index: 0)
                print(audioUrl)
                self.isFirstDownloaded = true
                self.currentDownloadIndex = 0
            }
        }
        print("Filtered clips by Author")
    }

    // Displays the start time of the next audio clip
    func showNextClipStartTime() {
        if (!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
            self.nextClipAtLabel.text = (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description
            self.currentDescriptionInfo.text = "\(activeAudioIndex) of \(self.clipCountLabel.text!) "
            if self.clipCountLabel.text! == "1" {
                self.currentDescriptionInfo.text = "\(String(describing: self.currentDescriptionInfo.text!)) description"
            }
            else {
                self.currentDescriptionInfo.text = "\(String(describing: self.currentDescriptionInfo.text!)) descriptions"
            }
        }
        else {
            self.currentDescriptionInfo.text = "\(activeAudioIndex) of \(self.clipCountLabel.text!) "
            if self.clipCountLabel.text! == "1" {
                self.currentDescriptionInfo.text = "\(String(describing: self.currentDescriptionInfo.text!)) description"
            }
            else {
                self.currentDescriptionInfo.text = "\(String(describing: self.currentDescriptionInfo.text!)) descriptions"
            }
        }
    }
    
    private func updateSlider(_ currentTime: Float) {
        // update the start time
        self.controlStartTimeLabel.text =  currentTime.millisToFormattedString()
        // update the slider
        self.controlSlider.value = currentTime * 1000
    }

    @IBAction func controlSliderChanged(_ sender: Any) {
        //youtubePlayer.seek(toSeconds: self.controlSlider.value/1000.0, allowSeekAhead: true)
        self.isControlSliderDown = true
    }
    
    @IBAction func controlSliderTouchUpOutsideAction(_ sender: Any) {
        print("Outside classed")
    }
    
    @IBAction func controlSliderTouchUpInsideAction(_ sender: Any) {
        self.isControlSliderDown = false
        youtubePlayer.seek(toSeconds: self.controlSlider.value/1000.0, allowSeekAhead: true)
        resetActiveAudioIndex()
        self.stopAudio()
    }
    
    @IBAction func controlSliderTouchDown(_ sender: Any) {
        youtubePlayer.seek(toSeconds: self.controlSlider.value/1000.0, allowSeekAhead: true)
    }
    
    @IBAction func controlSliderTouchDragEnter(_ sender: Any) {
        print("TD Enter")
    }

    // Called periodically as the youtube-player plays the video.
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float)
    {
        // if the control slider is being moved, pause the video and return
        if self.isControlSliderDown {
            return
        }

        if abs(self.previousTime - youtubePlayer.currentTime()) > 5 {
            print("DETECTED JUMP !!!")
            self.resetAudio()
            resetActiveAudioIndex()
        }

        self.drawUpdatedMarker()

        self.updateSlider(youtubePlayer.currentTime())
        //self.playerLabel.text = "\(playTime)"
        if !self.isAudioPlaying {
            // Check if we have reached the point in the video
            if(!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
                if (self.audioClips[activeAudioIndex]["clipFunction"]!! as! String) == "desc_extended" {
                    if Float(playTime) >= Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)! {
                        print("Starting audio at seconds:" + (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)
                        // Pause the video if it isn't already paused
                        if youtubePlayer.playerState().rawValue != 3 {
                            print("Pausing Video")
                            youtubePlayer.pauseVideo()
                        }
                        self.currentClipType = 0
                        if youtubePlayer.playerState().rawValue != 5 {
                            print("Playing Audio")
                            playAudio()
                        }
                    }
                }
                else {
                    if Float(playTime) >= Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)! {
                        print("Starting audio at seconds:" + (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)
                        self.currentClipType = 1
                        if self.isPlaybackActive == true {
                            if youtubePlayer.playerState().rawValue != 5 {
                                playAudio()
                            }
                        }
                    }
                }
            }
        }
        self.previousTime = youtubePlayer.currentTime()
        
        // Make sure we have the right player labels
        /*if self.isPlaybackActive == true && playButton.titleLabel?.text != "Pause" {
            playButton.setTitle("Pause", for: UIControlState())
        }
        else if self.isPlaybackActive == false && playButton.titleLabel?.text != "Play"{
            playButton.setTitle("Play", for: UIControlState())
        }*/
    }
    
    // Called when the youtube-player is ready to play the video
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        print("The video player is now ready")
    }

    // Called whenever the youtube-player changes its state.
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        // the player changed to state
        print(state.rawValue)
        if (state.rawValue == 4) {
            // Toggle isPlaybackActive
            if !self.isPlaybackActive {
                self.isPlaybackActive = true
                self.startPlay()
            }
            self.doPlay = true
            self.isPlaybackActive = true
        }
        else if (state.rawValue == 2) { // state is 'playing'
            self.isPlaybackActive = true
        }
        else if (state.rawValue == 3) { // paused
            // This could be caused by an extended audio description 
            // so consider that playback is still active
            if !self.isPlaybackActive {
                // This is a user induced pause
                print("This is a user induced pause")
            }
        }
        else if (state.rawValue == 5) { // stop
            self.isPlaybackActive = false
            // Prepare by loading the first clip
            self.previousTime = 0.0
            self.updateSlider(0.0)
            self.drawUpdatedMarker()
            self.resetAudio()
            if self.downloadAudioUrls.count > 0 {
                self.activeAudioIndex = 0
                self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
                self.loadAudio()
                self.showNextClipStartTime()
            }
        }
        else if (state.rawValue == 0) {
            self.isPlaybackActive = false
            self.reset()
        }
        else if (state.rawValue == 1) { // movie ended
            self.isPlaybackActive = false
            self.reset()
        }
        
        self.applyPlayPauseLabel()
    }

    // Implementation for the DownloadAudioDelegate
    func readDownloadUrls(urls: [URL]) {
        self.downloadAudioUrls = urls
        //print(urls)
    }
    
    func readTotalDownloaded(count: Int) {
        if count == self.audioClips.count {
            activeAudioIndex = 0
            self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
            loadAudio()
            showNextClipStartTime()
        } else {
            // Attempt to serially download the others
            if !self.doAsyncDownload {
                if self.currentDownloadIndex < self.audioClips.count-1 {
                    print("Downloading the next one ")
                    print(self.currentDownloadIndex)
                    self.currentDownloadIndex = self.currentDownloadIndex + 1
                    print(self.currentDownloadIndex)
                    self.downloadAudioUrls.append(DownloadAudio(delegate: self).getDownloadUrl(metadata: self.audioClips[self.currentDownloadIndex]))
                    let audioUrl:String = DownloadAudio(delegate: self).prepareClipCache(clips: self.audioClips, index: self.currentDownloadIndex)
                    print(audioUrl)
                    if (self.isFirstDownloaded) {
                        activeAudioIndex = 0
                        self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
                        loadAudio()
                        showNextClipStartTime()
                        self.isFirstDownloaded = false
                    }
                }
                else {
                    print("Finally finished downloading all audio clips sequencially")
                    if self.failedAudioUrls.count > 0 {
                        showMissingAudioWarning()
                    }
                }
            }
        }
    }

    func showMissingAudioWarning() {
        let alertController = UIAlertController(title: "Warning!", message: "One or more audio descriptions for this video are corrupt or missing. These will be skipped during playback.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            self.youtubePlayer.playVideo()
            self.showNextClipStartTime()
        }
        
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
        self.youtubePlayer.pauseVideo()
    }

    func registerNewDownload(url: URL, success: Int) {
        print("Finished downloading URL : " + url.absoluteString)
        if success != 0 && !failedAudioUrls.contains(url) {
            print("Found a bad URL :", url.absoluteString)
            self.failedAudioUrls.append(url)
            self.loadAudio()
        }
    }

    // Author picker interface delegate methods
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.authorIdList.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.authorMap[self.authorIdList[row] as String]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.didAuthorReset = true
        if self.overrideAuthorId != "" {
            self.currentAuthorId = self.overrideAuthorId
        }
        else {
            self.currentAuthorId = self.authorIdList[row]
        }
        self.updateClipCountFromAuthor()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        pickerLabel.text = self.authorMap[self.authorIdList[row] as String]
        pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        //pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 15) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.center
        
        // Post about the author change.
        //NotificationCenter.default.post(name: NSNotification.Name("AuthorChangeNotification"), object: pickerLabel.text)
        return pickerLabel
    }

    // Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAboutSegue" {
            let aboutController = segue.destination as! DetailInfoTableViewController
            aboutController.mediaId = self.movieID!
            aboutController.audioClips = self.allAudioClips
            aboutController.videoDuration = Float(youtubePlayer.duration())
            if self.currentAuthorId != nil {
                aboutController.currentAuthor = self.currentAuthorId!
            }
            else {
                aboutController.currentAuthor = "None"
            }
        }
        else if segue.identifier == "EmbedTimelineSegue" {
            let timelineViewController = segue.destination as! TimelineViewController
            // Get the YouTube Info for this video, and the movie ID
            timelineViewController.mediaId = self.movieID!
            timelineViewController.movieId = self.movieIdLocal
            timelineViewController.authorId = self.displayAuthorID
            timelineViewController.videoDuration = self.videoDurationInSeconds
            print("The data is \(self.movieIdLocal)")
            print("The user is \(self.displayAuthorID)")
        }
        else if segue.identifier == "ShowCreateDescriptionSegue" {
            let createDescriptionViewController = segue.destination as! CreateDescriptionViewController
            createDescriptionViewController.mediaId = self.movieID!
            createDescriptionViewController.allMovies = self.allMovies
            createDescriptionViewController.isEditMode = false
            createDescriptionViewController.movieName = self.currentMovieTitle!
            createDescriptionViewController.movieId = self.movieIdLocal
            createDescriptionViewController.videoDurationInSeconds = self.videoDurationInSeconds
            createDescriptionViewController.videoDurationString = self.videoDurationString
        }
    }

    // TODO: Orientation change.
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Transitioning....")
        let device = UIDevice.current
        if device.orientation == UIDeviceOrientation.portrait {
            self.describerLabel.isHidden = false
            self.descriptionVolumeLabel.isHidden = false
            self.authorPickerView.isHidden = false
            self.audioVolumeSlider.isHidden = false
        } else if device.orientation == UIDeviceOrientation.landscapeLeft {
            self.describerLabel.isHidden = true
            self.descriptionVolumeLabel.isHidden = true
            self.authorPickerView.isHidden = true
            self.audioVolumeSlider.isHidden = true
        }
        else if device.orientation == UIDeviceOrientation.landscapeRight {
            self.describerLabel.isHidden = true
            self.descriptionVolumeLabel.isHidden = true
            self.authorPickerView.isHidden = true
            self.audioVolumeSlider.isHidden = true
        }
        
    }

    @IBAction func onShareButtonClicked(_ sender: Any) {
        self.showShareMenu()
    }
    
    @IBAction func onAboutButtonClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowAboutSegue", sender: nil)
        
    }

    @IBAction func audioVolumeSliderChanged(_ sender: Any) {
        audioPlayer?.volume = self.audioVolumeSlider.value
    }


    func showShareMenu() {
        let socialHelper = SocialHelper(mediaId: self.movieID!, author: self.displayAuthor!, movieTitle: self.currentMovieTitle!)
        let optionMenu = UIAlertController(title: nil, message: "Choose action", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: {
                (alert: UIAlertAction) -> Void in
        })

        let shareVideoAction = UIAlertAction(
            title: "Share video",
            style: .default,
            handler: {
                (alert: UIAlertAction) -> Void in
                let objectsToShare = socialHelper.getShareOnSocialMediaObject()
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityType.airDrop,
                                                    UIActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
        })

        var addWord = "a "
        if self.authorIdList.count > 0 {
            addWord = "another "
        }
        let requestDescriptionAction = UIAlertAction(
            title: "Request \(addWord)description",
            style: .default,
            handler: {
            (alert: UIAlertAction) -> Void in
            let objectsToShare = socialHelper.getRequestDescriptionObject()
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityType.airDrop,
                                                UIActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        })

        let copyLinkAction = UIAlertAction(
            title: "Copy link to clipboard",
            style: .default,
            handler: {
                (alert: UIAlertAction) -> Void in
                socialHelper.copyLinkToClipboard()
        })

        let copyCodeAction = UIAlertAction(
            title: "Copy embedable code to clipboard",
            style: .default,
            handler: {
                (alert: UIAlertAction) -> Void in
                socialHelper.copyEmbedCodeToClipboard()
        })
        optionMenu.addAction(cancelAction)
        optionMenu.addAction(shareVideoAction)
        optionMenu.addAction(requestDescriptionAction)
        optionMenu.addAction(copyLinkAction)
        optionMenu.addAction(copyCodeAction)
        self.present(optionMenu, animated: true, completion: nil)
    }

    
    @IBAction func controlPlayButtonAction(_ sender: Any) {
        playPauseControl()
    }
    
    func sliderTapped(_ gestureRecognizer: UIGestureRecognizer) {
        print("A")
        let pointTapped: CGPoint = gestureRecognizer.location(in: self.view)
        
        let positionOfSlider: CGPoint = controlSlider.frame.origin
        let widthOfSlider: CGFloat = controlSlider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(controlSlider.maximumValue) / widthOfSlider)
        self.updateSlider(Float(newValue)/1000.0)
        self.youtubePlayer.seek(toSeconds: Float(newValue)/1000.0, allowSeekAhead: true)
        self.isControlSliderDown = false
    }

    
    @IBAction func createDescriptionAction(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowCreateDescriptionSegue", sender: nil)
    }
    
    // for marker positions
    func saveMarkerPositions(_ notification: Notification) {
        if let args = notification.object as? [String:AnyObject] {
            if let positions:[Float] = args["positions"] as? [Float] {
                print("The marker positions from the viewcontroller are ")
                print(positions)
                markerPositions = positions
            }
        }
    }

    func reloadForAuthoring() {
        print("These are the existing clips")
        self.loadClips()
            let vc = self.childViewControllers[0] as! TimelineViewController
            vc.reloadForAuthoring()
            vc.audioView.setNeedsDisplay()
            vc.videoView.setNeedsDisplay()
        var filteredClips:[AnyObject] = []
        for audioClip in self.allAudioClips {
            if ((audioClip["clipAuthor"]!! as AnyObject).description == self.currentAuthorId) {
                filteredClips.append(audioClip)
            }
        }
        
        self.audioClips = filteredClips
        print("UPdating downloaded URLs")
        self.updateDownloadedUrls()
        self.clipCountLabel.text = "\(audioClips.count)"
        //self.resetAudio()
        self.resetActiveAudioIndex()
        self.showNextClipStartTime()
        print("Calling the reloadForAuthoring")
    }
    
    private func updateDownloadedUrls() {
        self.downloadAudioUrls = []
        for clip in self.audioClips {
            self.downloadAudioUrls.append(DownloadAudio(delegate: self).getDownloadUrl(metadata: clip))
        }
    }

    // MARK - Accessibility
    override func accessibilityPerformMagicTap() -> Bool {
        // Toggle isPlaybackActive
        if self.isPlaybackActive {
            self.isPlaybackActive = false
        }
        else {
            self.isPlaybackActive = true
        }
        self.startPlay()
        return true
    }
    func playPauseControl() {
        if self.isPlaybackActive {
            self.isPlaybackActive = false
        }
        else {
            self.isPlaybackActive = true
        }
        self.startPlay()
    }
}

