import UIKit
import AVKit
import AVFoundation
import Foundation
import Social

class ViewController: UIViewController, YTPlayerViewDelegate, DownloadAudioDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    let dvxApi = DvxApi()
    let audioIndexThreshold:Int = 3
    let skipButtonFrameCount:Float = 10

    var doPlay:Bool = true
    var currentAudioUrl = NSURL(string: "")
    var nextAudioUrl = NSURL(string: "")
    var downloadAudioUrls:[URL] = []
    var failedAudioUrls:[URL] = []
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var allAudioClips: [AnyObject] = []
    var audioClips: [AnyObject] = []
    var activeAudioIndex:Int = 0
    var allMovies : [AnyObject] = []
    var movieID : String?
    var currentAuthor: String?
    var isAudioPlaying: Bool = false
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

    @IBOutlet weak var youtubePlayer: YTPlayerView!
    //@IBOutlet weak var movieText: UITextField!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    //@IBOutlet weak var authorText: UITextField!
    @IBOutlet weak var nextClipAtLabel: UILabel!
    @IBOutlet weak var authorPickerView: UIPickerView!
    //@IBOutlet weak var detailView: UITextView!
    @IBOutlet weak var tabViewContainer: UIView!
    
    @IBOutlet weak var stackViewMain: UIStackView!
    var tester: Int = 0

    var playerLayer = AVPlayerLayer()
    @IBOutlet weak var duckingSwitch: UISwitch!
    @IBOutlet weak var volumeWrapperView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.youtubePlayer.delegate = self
        self.authorPickerView.delegate = self
        self.authorPickerView.dataSource = self
        //self.hideKeyboardOnTap()

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
        
        self.duckingSwitch.isOn = false
        // Audio duck if required.
        let control = VolumeControl()
        control.setVolume(0.0)
        
        // Make volume controller
        control.drawControl(self.volumeWrapperView)

        // select the right author in the pickerview
        var row: Int = 0
        print(self.authorMap)
        for author in self.authorIdList {
            print(author)
            if self.authorMap[author] == self.displayAuthor {
                break
            }
            row += 1
        }
        self.initialAuthorIndex = row
        //self.currentAuthorId = self.authorIdList[row1]
        authorPickerView.selectRow(self.initialAuthorIndex!, inComponent: 0, animated: false)
        authorPickerView.reloadAllComponents()
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

    // Functions to dismiss the keyboard on tapping outside
    func hideKeyboardOnTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }

    // Loads all the audio clips based on the selected MediaId
    func loadClips() {
        // get the movieID of the clip
        let selectedMovies = dvxApi.getMovies(["MediaId": movieID!])
        
        //For Youtube videos
        
        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"]
            self.currentMovie = selectedMovies[0]
            let clips = dvxApi.getClips(["Movie": (movieId!! as AnyObject).description])
            print(clips.description)
            self.allAudioClips = clips
            self.authorIdList = getAllAuthors()
            authorPickerView.reloadAllComponents()
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
            self.currentAuthorId = authorIds[0]
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
        let alertController = UIAlertController(title: "Warning!", message: "Cannot find any audio clip metadata for this video although it appears to have been described previously.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
        }
        
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func getAuthorMap() -> [String:String] {
        if (self.allAuthors.count > 0) {
            for author in self.allAuthors {
                self.authorMap[author["userId"] as! String] = author["userHandle"] as? String
            }
        }
        return self.authorMap
    }

    func loadAudio() {
        // play the audio link
        if self.failedAudioUrls.contains(currentAudioUrl! as URL) {
            let myUrl = URL(string: "https://dl.dropboxusercontent.com/u/57189163/point1sec.mp3")
            audioPlayerItem = AVPlayerItem(url: myUrl!)
        }
        else {
            audioPlayerItem = AVPlayerItem(url: currentAudioUrl! as URL)
        }
        audioPlayer?.replaceCurrentItem(with: audioPlayerItem)
    }
    
    // Play the audio - Also tries to precache the next audio clip as the current is playing
    func playAudio() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        audioPlayer?.play()
        self.isAudioPlaying = true

        // Pre-cache the next clip
        if self.audioClips.count > 0 && activeAudioIndex < self.audioClips.count-1 {
            self.nextAudioUrl = self.downloadAudioUrls[activeAudioIndex+1] as NSURL
        }
    }
    

    // Called when the audio clip finishes playing
    func playerDidFinishPlaying(_ note: Notification) {
        self.isAudioPlaying = false
        print("Resume video playing:")
        youtubePlayer.playVideo()
        activeAudioIndex = activeAudioIndex + 1
        showNextClipStartTime()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        if self.nextAudioUrl != self.currentAudioUrl {
            self.currentAudioUrl = self.nextAudioUrl
            loadAudio()
        }
    }

    func resetAudio() {
        self.isAudioPlaying = false
        youtubePlayer.playVideo()
        showNextClipStartTime()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
        if self.nextAudioUrl != self.currentAudioUrl {
            self.currentAudioUrl = self.nextAudioUrl
            loadAudio()
        }
    }

    func stopAudio() {
        audioPlayer?.pause()
    }

    // Called when the movie is loaded
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
    
    // Called on clicking the Play/Pause toggle button
    @IBAction func playPauseAction(_ sender: AnyObject) {
        self.startPlay()
    }

    func startPlay() {
        if(doPlay) {
            if self.didAuthorReset {
                self.filterAndDownloadAudioClips()
                self.didAuthorReset = false
            }
            youtubePlayer.playVideo()
        } else {
            youtubePlayer.pauseVideo()
        }
    }
    // Called on clicking the 'stop' button
    @IBAction func stopAction(_ sender: AnyObject) {
        reset()
    }

    // Resets the state of both the audio and video players
    func reset() {
        youtubePlayer.stopVideo()
        audioPlayer?.pause()
        loadAudio()
        activeAudioIndex = 0
        //self.audioClips = []
        doPlay = true
        resetActiveAudioIndex()
        showNextClipStartTime()
        self.nextClipAtLabel.text = ""
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
        if self.audioClips.count > 0 {
            // find the appropriate start index and assign it to activeAudioIndex.
            var index:Int = 0
            for _ in self.audioClips {
                if Float((self.audioClips[index]["clipStartTime"]!! as AnyObject).description)! >= Float(youtubePlayer.currentTime()) {
                    activeAudioIndex = index
                    showNextClipStartTime()
                    self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
                    loadAudio()
                    break
                }
                index = index + 1
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
        }
    }

    // Called periodically as the youtube-player plays the video.
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float)
    {
        if abs(self.previousTime - youtubePlayer.currentTime()) > 5 {
            print("DETECTED JUMP !!!")
            //self.stopAudio()
            self.resetAudio()
            resetActiveAudioIndex()

        }


        self.playerLabel.text = "\(playTime)"
        if !self.isAudioPlaying {
            // Check if we have reached the point in the video
            if(!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
                if (self.audioClips[activeAudioIndex]["clipFunction"]!! as! String) == "desc_extended" {
                    if Float(playTime) >= Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)! {
                        print("Starting audio at seconds:" + (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)
                        print("Pausing Video")
                        youtubePlayer.pauseVideo()
                        print("Playing Audio")
                        playAudio()
                    }
                }
                else {
                    if Float(playTime) >= Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)! {
                        print("Starting audio at seconds:" + (self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description)
                        playAudio()
                    }
                }
            }
        }
        self.previousTime = youtubePlayer.currentTime()
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
            self.startPlay()
        }
        else if (state.rawValue == 2) { // state is 'playing'
            //change the button to text
            playButton.setTitle("Pause", for: UIControlState())
            doPlay = false
        }
        else if (state.rawValue == 3) { // buffering
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
        }
        else if (state.rawValue == 5) { // stop
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
        }
        else if (state.rawValue == 0) {
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
            self.reset()
        }
        else if (state.rawValue == 1) { // movie ended
            playButton.setTitle("Play", for: UIControlState())
            doPlay = true
            self.reset()
        }
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
        self.currentAuthorId = self.authorIdList[row]
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
        NotificationCenter.default.post(name: NSNotification.Name("AuthorChangeNotification"), object: pickerLabel.text)
        return pickerLabel
    }
    // Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbeddedTabViewController" {
            let tabBarController = segue.destination as! TabBarViewController
            if (self.currentAuthorId != nil) {
                tabBarController.preferredAuthor = self.authorMap[self.currentAuthorId!]!
            }
            else {
                if self.displayAuthor != nil {
                    tabBarController.preferredAuthor = self.displayAuthor!
                }
                else {
                    tabBarController.preferredAuthor = "None"
                }
            }
            tabBarController.mediaId = self.movieID!
            tabBarController.myString = "Testing" // TODO: Remove this test
            tabBarController.movieTitle = self.currentMovieTitle!
        }
    }
    
    // TODO: Orientation change.
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Transitioning....")
    }

}

