//
//  CreateDescriptionViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/9/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import AVFoundation

class CreateDescriptionViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    let dvxApi = DvxApi()
    let youTubeApi = YouTubeApi()
    var mediaId: String!
    var movieId: String!
    var youTubeInfo: [String:String] = [:]
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var currentAudioFileDirectory: URL!
    var currentAudioFileName: String = "TestRecording.m4a"
    var sessionRecordingName: String!
    var totalUploadedClips: Int!
    var yPos: Int!
    var audioClips: [AudioClip]!
    var allMovies: [AnyObject] = []
    var userId: String = ""
    var userToken: String = ""

    @IBOutlet weak var youtubePlayer: YTPlayerView!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var btnQueue: UIButton!
    @IBOutlet weak var btnUpload: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let options = ["playsinline" : 1]
        youtubePlayer.load(withVideoId: mediaId, playerVars: options)
        // Do any additional setup after loading the view.
        
        audioPlayer?.delegate = self
        audioRecorder?.delegate = self
        self.sessionRecordingName = self.generateUniqueId()
        self.totalUploadedClips = 0
        self.currentAudioFileDirectory =  FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        // Set up the audio recorder
        setUpAudioRecord()
        self.yPos = 0
        self.audioClips = []

        // Set the user ID
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            let user = dvxApi.getUsers(["LoginName": preferences.object(forKey: "username") as! String ])[0]
            self.userId = user["userId"] as! String
            self.userToken = preferences.object(forKey: "session") as! String
        }
        else {
            // TODO: Handle the case where the user's session has expired and might need to login again.
        }

        // Get the YouTube Info for this video, and the movie ID
        youTubeApi.getInfo(mediaId: self.mediaId, finished: { item in
            self.youTubeInfo = item
            // Call this only once we have all the info
            self.setOrCreateMovie()
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Returns the movie ID. If one already exists,
    func setOrCreateMovie() {
        self.movieId = dvxApi.getMovieIdFromMediaId(allMovies: self.allMovies, mediaId: self.mediaId)
        print("Returning an existing movie ID: \(self.movieId)")
        if self.movieId == "" {
            // Create a new movie and return the movie Id
            let request = dvxApi.prepareForAddMovie(["AppId": Constants.APP_ID,
                                                     "MediaId": self.mediaId,
                                                     "Title": self.youTubeInfo["movieName"]!,
                                                     "Language": "English",
                                                     "Summary": "",
                                                     "Token": self.userToken,
                                                     "UserId": self.userId])
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) in
                let result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                if let httpResponse = response as? HTTPURLResponse
                {
                    if httpResponse.statusCode != 200 || result != "OK" {
                        print("Error: Failed creating a movie object: returned status \(httpResponse.statusCode)")
                        print(error ?? "Unknown error")
                    }
                    else {
                        // Re-read all the movies
                        self.allMovies = self.dvxApi.getMovies([:])
                        self.movieId = self.dvxApi.getMovieIdFromMediaId(allMovies: self.allMovies, mediaId: self.mediaId)
                        print("Created a new Movie Id: \(self.movieId)")
                    }
                }
            })
            task.resume()
        }
    }

    func setUpAudioRecord()
    {
        // set up the audio file
        let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        self.currentAudioFileDirectory = directoryURL
        let audioFileURL = directoryURL.appendingPathComponent(self.currentAudioFileName)
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        } catch let error {
            print(error)
        }

        // define the recorder setting
        let recorderSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey : 44100.0, AVNumberOfChannelsKey : 2 as NSNumber] as [String : Any]
        
        // initiate and prepare the recorder
        do {
            audioRecorder  = try AVAudioRecorder(url: audioFileURL, settings: recorderSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            print("The URL is \(audioRecorder.url)")
        } catch let error {
            print(error)
        }
    }

    // to be called when the play button is pressed.
    func play() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                return
            }
        }
        
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    print("Playing the audio url")
                } catch let error {
                    print(error)
                }
            }
        }
    }

    // to be called when the cancel button is pressed.
    func cancel() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                return
            }
        }
    }
    
    // to be called when the record button is pressed.
    func record() {
        // pause the video if it is playing
        youtubePlayer.pauseVideo()
        // stop the audio player before recording
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                btnPlayPause.setTitle("Play", for: UIControlState())
            }
        }

        // if we are not recording then start recording!
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setActive(true)    // make the recorder work
                    // start recording
                    // giving time for video to stop
                    sleep(1)
                    recorder.record()
                    btnRecord.setTitle("Stop", for: UIControlState())
                    print("Started recording..")
                } catch let error {
                    print(error)
                }
            } else {
                // pause the recording
                recorder.stop()
                btnRecord.setTitle("Record", for: UIControlState())
                print("Stopped recording...")
                // deactivate the audio session
                do {
                    try AVAudioSession.sharedInstance().setActive(false)
                } catch let error {
                    print(error)
                }
            }
        }
    }

    func uploadClips() {
        // send the required audio clips to the upload module
        for audioClip in self.audioClips {
            if !audioClip.isDeleted {
                print("Uploading clip: \(audioClip.index)")
            }
        }
    }

    @IBAction func playPauseAction(_ sender: Any) {
        self.play()
    }
    
    @IBAction func stopAction(_ sender: Any) {
        self.cancel()
    }
    
    @IBAction func recordAction(_ sender: Any) {
        self.record()
    }
    
    @IBAction func queueAction(_ sender: Any) {
        self.queueClip()
    }
    @IBAction func uploadAction(_ sender: Any) {
        self.uploadClips()
    }
    
    func queueClip() {
        // prepare the AudioClip object
        var newClip: AudioClip!
        newClip = AudioClip()
        newClip.startTime? = 45.56
        newClip.index = self.totalUploadedClips
        newClip.audioFile = self.saveClipLocally(newClip)
        
        // create a new view
        //let clipView = UIStackView(frame: CGRect(x: 5, y: self.yPos, width: 480, height: 50))
        let clipView = UIView(frame: CGRect(x: 5, y: self.yPos, width: 370, height: 50))
        clipView.backgroundColor = UIColor.lightGray
        clipView.contentMode = .left
        
        
        // create the play button
        let playButton = UIButton(frame: CGRect(x:5, y:15, width:50, height:20))
        playButton.backgroundColor = UIColor.darkGray
        playButton.setTitle("Play", for: .normal)
        playButton.tag = newClip.index
        playButton.addTarget(self, action: #selector(CreateDescriptionViewController.playClip(_:)), for: .touchDown)
        clipView.addSubview(playButton)
        
        // create the nudge buttons
        let btnNudgeLeftSecs = UIButton(frame: CGRect(x:65, y:15, width:30, height:20))
        btnNudgeLeftSecs.backgroundColor = UIColor.darkGray
        btnNudgeLeftSecs.setTitle("<<", for: .normal)
        btnNudgeLeftSecs.tag = newClip.index
        btnNudgeLeftSecs.addTarget(self, action: #selector(CreateDescriptionViewController.nudgeLeftSecClip(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeLeftSecs)
        
        // create the nudge buttons
        let btnNudgeLeftMillisecs = UIButton(frame: CGRect(x:105, y:15, width:15, height:20))
        btnNudgeLeftMillisecs.backgroundColor = UIColor.darkGray
        btnNudgeLeftMillisecs.setTitle("<", for: .normal)
        btnNudgeLeftMillisecs.tag = newClip.index
        btnNudgeLeftMillisecs.addTarget(self, action: #selector(CreateDescriptionViewController.nudgeLeftMillisecClip(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeLeftMillisecs)
        
        // create the time label
        let timeLabel = UILabel(frame: CGRect(x:115, y:15, width:100, height:20))
        let currentMarkerTime: Float = youtubePlayer.currentTime()
        let hours = (Int(currentMarkerTime)) / (3600) as Int
        let mins = (Int(currentMarkerTime) / 60) % 60
        let secs:Float = Float(Int(Int(currentMarkerTime) % 60) % 60)
        var millisecs:Float = (currentMarkerTime) - floor(currentMarkerTime)
        millisecs = Float(String(format: "%.2f", millisecs))!
        timeLabel.textAlignment = .center
        timeLabel.text = "\(hours):\(mins):\(secs+millisecs)"
        newClip.startHour = hours
        newClip.startMinutes = mins
        newClip.startSeconds = secs + millisecs
        newClip.timeLabelView = timeLabel
        
        // create the nudge right buttons
        let btnNudgeRightMillisecs = UIButton(frame: CGRect(x:200, y:15, width:20, height:20))
        btnNudgeRightMillisecs.backgroundColor = UIColor.darkGray
        btnNudgeRightMillisecs.setTitle(">", for: .normal)
        btnNudgeRightMillisecs.tag = newClip.index
        btnNudgeRightMillisecs.addTarget(self, action: #selector(CreateDescriptionViewController.nudgeRightMillisecClip(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeRightMillisecs)
        
        // create the nudge right buttons
        let btnNudgeRightSecs = UIButton(frame: CGRect(x:230, y:15, width:30, height:20))
        btnNudgeRightSecs.backgroundColor = UIColor.darkGray
        btnNudgeRightSecs.setTitle(">>", for: .normal)
        btnNudgeRightSecs.tag = newClip.index
        btnNudgeRightSecs.addTarget(self, action: #selector(CreateDescriptionViewController.nudgeRightSecClip(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeRightSecs)
        
        let switchInline = UISwitch(frame: CGRect(x:260, y:15, width:35, height:20))
        switchInline.isOn = false
        switchInline.sizeThatFits(CGSize(width: 150, height: 20))
        switchInline.addTarget(self, action: #selector(CreateDescriptionViewController.stateChanged(_: )), for: .valueChanged )
        clipView.addSubview(switchInline)
        
        // create the delete clip button
        let btnDeleteClip = UIButton(frame: CGRect(x:320, y:15, width:35, height:20))
        btnDeleteClip.backgroundColor = UIColor.darkGray
        btnDeleteClip.setTitle("X", for: .normal)
        btnDeleteClip.tag = newClip.index
        btnDeleteClip.addTarget(self, action: #selector(CreateDescriptionViewController.deleteClip(_:)), for: .touchDown)
        clipView.addSubview(btnDeleteClip)
        
        self.scrollView.addSubview(clipView)
        self.totalUploadedClips = self.totalUploadedClips + 1
        self.yPos = self.yPos + 50 + 5
        print("total clips are \(self.totalUploadedClips)")
        
        scrollView.contentSize = CGSize(width: 400, height: CGFloat((clipView.frame.height + 5) * CGFloat(self.totalUploadedClips)))
        clipView.addSubview(timeLabel)
        newClip.clipView = clipView // Hold a reference to this clipView
        self.audioClips.append(newClip)
    }
    func stateChanged(_ switchview: UISwitch!) {
        if switchview.isOn {
            self.audioClips[switchview.tag].isInline = true
        }
        else {
            self.audioClips[switchview.tag].isInline = false
        }
    }

    func action(_ button: UIButton!) {
        
    }
    //then make a action method
    func playClip(_ button: UIButton!) {
        print("Play the video associated with this clip: \(self.audioClips[button.tag].audioFile.absoluteString)")
        
        // Play the audio clip
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                return
            }
        }
        
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: self.audioClips[button.tag].audioFile)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                } catch let error {
                    print(error)
                }
            }
        }
    }

    func deleteClip(_ button: UIButton!) {
        self.confirmDeleteClip(index: button.tag)
    }

    func nudgeLeftSecClip(_ button: UIButton!) {
        let audioClip = self.audioClips[button.tag]
        if audioClip.startSeconds > 0 {
           audioClip.startSeconds = audioClip.startSeconds - 1
           // update the label
            audioClip.timeLabelView.text = "\(audioClip.startHour!):\(audioClip.startMinutes!):\(audioClip.startSeconds!)"
        }
    }

    func nudgeLeftMillisecClip(_ button: UIButton!) {
        let audioClip = self.audioClips[button.tag]
        if audioClip.startSeconds > 0 {
            audioClip.startSeconds = audioClip.startSeconds - 0.1
            // update the label
            audioClip.timeLabelView.text = "\(audioClip.startHour!):\(audioClip.startMinutes!):\(audioClip.startSeconds!)"
        }
    }

    func nudgeRightSecClip(_ button: UIButton!) {
        let audioClip = self.audioClips[button.tag]
        if audioClip.startSeconds >= 0 { // TODO: Change this to max duration of the clip
            audioClip.startSeconds = audioClip.startSeconds + 1
            // update the label
            audioClip.timeLabelView.text = "\(audioClip.startHour!):\(audioClip.startMinutes!):\(audioClip.startSeconds!)"
        }
    }

    func nudgeRightMillisecClip(_ button: UIButton!) {
        let audioClip = self.audioClips[button.tag]
        if audioClip.startSeconds >= 0 { // TODO: Change this to max duration of the clip
            audioClip.startSeconds = audioClip.startSeconds + 0.1
            // update the label
            audioClip.timeLabelView.text = "\(audioClip.startHour!):\(audioClip.startMinutes!):\(audioClip.startSeconds!)"
        }
    }

    func redrawClips(deletedIndex: Int) {
        var yPos = CGFloat(0)
        for clip in self.audioClips {
            if clip.index != deletedIndex {
                clip.clipView.frame.origin.y = yPos
                yPos = yPos + 50 + 5
            }
        }
        self.yPos = Int(yPos)
    }

    func confirmDeleteClip(index: Int) {
        let alertController = UIAlertController(title: "Alert", message: "Are you sure you want to delete this clip?", preferredStyle: .alert)
        
        // Initialize Actions
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
            print("The clip to be deleted has index: \(index)")
            self.audioClips[index].isDeleted = true
            self.audioClips[index].clipView.removeFromSuperview()
            self.redrawClips(deletedIndex: index)
        }
        
        let noAction = UIAlertAction(title: "No", style: .default) { (action) -> Void in
        }

        alertController.addAction(noAction)
        alertController.addAction(yesAction)

        // Present Alert Controller
        self.present(alertController, animated: true, completion: nil)
    }

    func saveClipLocally(_ clip: AudioClip) -> URL {
        let sourceURL = self.currentAudioFileDirectory.appendingPathComponent(self.currentAudioFileName)
        let destURL = self.currentAudioFileDirectory.appendingPathComponent("\(self.sessionRecordingName!)_\(clip.index!).m4a")
        self.copyFile(
            sourcePath: sourceURL,
            destPath: destURL
        )
        return destURL
    }

    private func generateUniqueId() -> String {
        return UUID().uuidString
    }

    // Move this to Utils
    private func copyFile(sourcePath: URL, destPath:URL) {
        let fileManager = FileManager.default

        do {
            try fileManager.copyItem(at: sourcePath, to: destPath)
        }
        catch let error as NSError {
            print("Failed to copy file: \(error)")
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

}
