import UIKit
import AVKit
import AVFoundation
import Foundation

class ViewController: UIViewController, YTPlayerViewDelegate, DownloadAudioDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    let dvxApi = DxvApi()
    var doPlay:Bool = true
    var currentAudioUrl = NSURL(string: "")
    var nextAudioUrl = NSURL(string: "")
    var downloadAudioUrls:[URL] = []
    var audioPlayerItem:AVPlayerItem?
    var audioPlayer:AVPlayer?
    var allAudioClips: [AnyObject] = []
    var audioClips: [AnyObject] = []
    var activeAudioIndex:Int = 0
    var allMovies : [AnyObject] = []
    var movieID : String?
    var isAudioPlaying: Bool = false
    var authorIdList: [String] = []
    var allAuthors: [AnyObject] = []
    var authorMap: [String:String] = [:]
    var currentAuthorId: String?
    var currentMovie: AnyObject?

    @IBOutlet weak var debugView: UITextView!
    @IBOutlet weak var youtubePlayer: YTPlayerView!
    //@IBOutlet weak var movieText: UITextField!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    //@IBOutlet weak var authorText: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var nextClipAtLabel: UILabel!
    @IBOutlet weak var authorPickerView: UIPickerView!
    //@IBOutlet weak var detailView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.youtubePlayer.delegate = self
        self.authorPickerView.delegate = self
        self.authorPickerView.dataSource = self
        self.hideKeyboardOnTap()

        loadMovie(self)
        allMovies = dvxApi.getMovies([:])
        self.allAuthors = dvxApi.getUsers([:])
        self.authorMap = getAuthorMap()
        print(self.authorMap)
        //allMovies = dvxApi.getMovies([:])


        //print("all movies count =")
        print(allMovies)
        //print(allMovies.count)
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
        if(selectedMovies.count >= 1) {
            let movieId = selectedMovies[0]["movieId"];
            let clips = dvxApi.getClips(["Movie": (movieId!! as AnyObject).description])
            print("The clips are")
            print(clips.description)
            debugView.text = clips.description
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
        }
        return authorIds
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
        audioPlayerItem = AVPlayerItem(url: currentAudioUrl! as URL)
        audioPlayer=AVPlayer(playerItem: audioPlayerItem!)
        let playerLayer=AVPlayerLayer(player: audioPlayer!)
        playerLayer.frame=CGRect(x: 0, y: 0, width: 300, height: 50)
        self.view.layer.addSublayer(playerLayer)
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

    func stopAudio() {
        audioPlayer?.pause()
    }
    
    func loadMovieDescription() {
        var detailString:String = ""
        detailString = detailString + "Title:" + (self.currentMovie!["movieName"] as! String)
        detailString = detailString + "\nDescription: " + (self.currentMovie!["movieDescription"] as! String)
        //detailView.text = detailString
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
        if(doPlay) {
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
        self.audioClips = []
        doPlay = true
    }
    
    // Filters clips by Author
    @IBAction func startAction(_ sender: AnyObject) {
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
            DownloadAudio(delegate: self).prepareAllClipCache(clips: self.audioClips)
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
        self.playerLabel.text = "\(playTime)"
        if !self.isAudioPlaying {
            // Check if we have reached the point in the video
            if(!self.audioClips.isEmpty && activeAudioIndex < self.audioClips.count) {
                print(self.audioClips[activeAudioIndex])
                //print(Float(floor(playTime)))
                print(Float((self.audioClips[activeAudioIndex]["clipStartTime"]!! as AnyObject).description))
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
    }

    // Called when the youtube-player is ready to play the video
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        print("The video player is now ready")
    }
    
    // Called whenever the youtube-player changes its state.
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

    // Implementation for the DownloadAudioDelegate
    func readDownloadUrls(urls: [URL]) {
        self.downloadAudioUrls = urls
        print(urls)
    }
    
    func readTotalDownloaded(count: Int) {
        if count == self.audioClips.count {
            activeAudioIndex = 0
            self.currentAudioUrl = self.downloadAudioUrls[activeAudioIndex] as NSURL
            loadAudio()
            showNextClipStartTime()
        }
    }

    func registerNewDownload(url: URL) {
        print("Finished downloading URL : " + url.absoluteString)
    }

    // Author picker interface delegate methods
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.authorIdList.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.authorMap[self.authorIdList[row] as String]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.currentAuthorId = self.authorIdList[row]
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
}

