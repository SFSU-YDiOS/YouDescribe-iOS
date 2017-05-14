//
//  CreateDescriptionViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/9/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class CreateDescriptionViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {

    let dvxApi = DvxApi()
    let youTubeApi = YouTubeApi()
    let audioHelper = AudioHelper()
    var mediaId: String = ""
    var movieId: String = ""
    var youTubeInfo: [String:String] = [:]
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var audioPlayerItem:AVPlayerItem?
    var currentAudioFileDirectory: URL!
    var currentAudioFileName: String = "TestRecording.mp3"
    var currentAudioTempURL: URL!
    var sessionRecordingName: String!
    var totalUploadedClips: Int!
    var yPos: Int!
    var audioClips: [AudioClip]!
    var allMovies: [AnyObject] = []
    var userId: String = ""
    var userToken: String = ""
    var isEditMode: Bool  = false
    var doPlay: Bool = true
    var doRecord: Bool = false
    var movieName: String = ""
    var youtubePlayer: YTPlayerView!
    var videoDetailViewController: ViewController!
    var videoDurationInSeconds: Float = 0.0
    var videoDurationString: String = ""

    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var btnQueue: UIButton!
    @IBOutlet weak var audioClipsTableView: UITableView!
    @IBOutlet weak var btnPreview: UIButton!
    @IBOutlet weak var btnPlayVideo: UIButton!
    @IBOutlet weak var btnPreviewTimeline: UIButton!
    @IBOutlet weak var playerContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let options = ["playsinline" : 1]
        //youtubePlayer.load(withVideoId: mediaId, playerVars: options)
        // Do any additional setup after loading the view.
        audioPlayer?.delegate = self
        audioRecorder?.delegate = self
        audioClipsTableView.delegate = self
        audioClipsTableView.dataSource = self
        //youtubePlayer.delegate = self

        self.sessionRecordingName = self.generateUniqueId()
        self.totalUploadedClips = 0
        self.currentAudioFileDirectory =  FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!

        // Set up the audio recorder
        setUpAudioRecord()
        self.yPos = 0
        self.audioClips = []

        //youtubePlayer.setPlaybackQuality(YTPlaybackQuality.small)
        // Set the user ID
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            let user = dvxApi.getUsers(["LoginName": preferences.object(forKey: "username") as! String ])[0]
            self.userId = dvxApi.getUserId(["LoginName": preferences.object(forKey: "username") as! String ])
            // self.userId = user["userId"] as! String
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
            // Lay out the authors previous clips if this is edit mode
            if self.isEditMode {
                // Query for existing clips here
                let clipData = self.dvxApi.getClips(["Movie": self.movieId,
                                                "UserId": self.userId])
                print("The clip Data is ")
                print(clipData)
                self.layoutClips(clipData)
            }
        })

        // initialize lame for audio recording
        audioHelper.initializeLame()
        
        // Register notification observers
        self.registerObservers()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func layoutClips(_ clipData: [AnyObject]) {
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
        if self.audioClips.count > 0 {
            //self.redrawClips(deletedIndex: -1)
        }
        func sortFilter(this:AudioClip, that:AudioClip) -> Bool {
            return this.startTime < that.startTime
        }
        self.audioClips.sort(by: sortFilter)

        DispatchQueue.main.async {
            self.audioClipsTableView.reloadData()
        }

    }
    
    func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playTableClip(_:)), name: NSNotification.Name("PlayClipNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteTableClip(_:)), name: NSNotification.Name("DeleteClipNotification"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTableClip(_:)), name: NSNotification.Name("UpdateClipNotification"), object: nil)
    }

    func playTableClip(_ notification: Notification) {
        if let args = notification.object as? [String:AnyObject] {
            print ("The argument is ")
            print(args)
            // load the path in the audioPlayer
            if let player = audioPlayer {
                if player.isPlaying {
                    player.stop()
                    return
                }
            }
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: args["path"] as! URL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch let error {
                print(error)
            }
        }
    }

    func deleteTableClip(_ notification: Notification) {
        let alertController = UIAlertController(title: "Confirm deletion", message: "Are you sure you want to delete this audio clip permanently?", preferredStyle: .alert)

        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
            if let args = notification.object as? [String:AnyObject] {
                let index = args["index"] as! Int
                print("Deleting record at index \(index)")
                // Delete the record from the database.
                let clipId: String = args["clipId"] as! String
                print("The deleting clip ID is \(clipId)")
                print("The deleting movie ID is \(self.movieId)")
                let request = self.dvxApi.prepareForDeleteClip(["AppId": Constants.APP_ID,
                                                       "Token": self.userToken,
                                                       "UserId": self.userId,
                                                       "ClipId": clipId,
                                                       "Movie": self.movieId
                ])
                // run the request here.
                let session = URLSession.shared
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) in
                    let result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    if let httpResponse = response as? HTTPURLResponse
                    {
                        print("The result is ")
                        print(result ?? "Undefined")
                        if httpResponse.statusCode != 200 {
                            print("Error: Failed to delete the audio clip: returned status \(httpResponse.statusCode)")
                            print(error ?? "Unknown error")
                        }
                        else {
                            print("Successfully deleted the clip")
                            DispatchQueue.main.async {
                                self.audioClips.remove(at: index)
                                self.audioClipsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                                self.audioClipsTableView.reloadData()
                            }
                        }
                    }
                })
                task.resume()
            }
        }

        let noAction = UIAlertAction(title: "No", style: .default) { (action) -> Void in
        }
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        // Present Alert Controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Updates a clip as soon as it is changed in the UI
    func updateTableClip(_ notification: Notification) {
        if let args = notification.object as? [String:AnyObject] {
            if let operation:Int = args["operation"] as? Int {
                var request: NSMutableURLRequest!
                let clipId: String = args["clipId"] as! String
                switch operation {
                case 0:
                    let startTime = args["startTime"] as! Float
                    print("The clip ID is \(clipId)")
                    request = dvxApi.prepareForUpdateClip(["AppId": Constants.APP_ID,
                                                           "Token": self.userToken,
                                                           "UserId": self.userId,
                                                           "ClipId": clipId,
                                                           "Time": "\(startTime)"
                        ])
                    break
                case 1:
                    let function = args["function"] as! String
                    request = dvxApi.prepareForUpdateClip(["AppId": Constants.APP_ID,
                                                           "Token": self.userToken,
                                                           "UserId": self.userId,
                                                           "ClipId": clipId,
                                                           "Function": function
                        ])
                    break
                default: break
                }
                
                // run the request here.
                if request != nil {
                    let session = URLSession.shared
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {
                        (data, response, error) in
                        let result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                        if let httpResponse = response as? HTTPURLResponse
                        {
                            print("The result is ")
                            print(result ?? "Undefined")
                            if httpResponse.statusCode != 200 {
                                print("Error: Failed updating the clip object: returned status \(httpResponse.statusCode)")
                                print(error ?? "Unknown error")
                            }
                            else {
                                print("Successfully updated the clip")
                            }
                        }
                    })
                    task.resume()
                }
            }
        }
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
            print(request)
            print("\(Constants.APP_ID) , \(self.mediaId), \(self.youTubeInfo["movieName"]!), \(self.userToken), \(self.userId)")
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
                        // invalidate the cache to refresh the back screen
                        GlobalCache.cache.removeObject(forKey: "allMoviesSearch")
                        GlobalCache.cache.removeObject(forKey: "allMovies")
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
        self.currentAudioTempURL = self.currentAudioFileDirectory.appendingPathComponent(self.currentAudioFileName)
        
    }

    // to be called when the play button is pressed.
    func play() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
                return
            }
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: self.currentAudioTempURL)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Playing the audio url")
        } catch let error {
            print(error)
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
                    btnRecord.setImage(#imageLiteral(resourceName: "Stop"), for: UIControlState())
                    print("Started recording..")
                } catch let error {
                    print(error)
                }
            } else {
                // pause the recording
                recorder.stop()
                btnRecord.setImage(#imageLiteral(resourceName: "Record"), for: UIControlState())
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

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing")
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            print("Deactivating the session")
            //session.setActive(false, with: AVAudioSessionCategoryOptions.duckOthers)
        }
        catch let error as Error {
            print("deactivate error")
            print(error)
        }
    }

    @IBAction func playPauseAction(_ sender: Any) {
        self.play()
    }
    
    @IBAction func previewDetailAction(_ sender: Any) {
        self.performSegue(withIdentifier: "PreviewDescriptionSegue", sender: nil)
    }

    @IBAction func recordAction(_ sender: Any) {
        if audioHelper.isRecording {
            audioHelper.stopRecording(self.currentAudioTempURL)
            //btnRecord.setTitle("Record", for: UIControlState())
            btnRecord.setImage(#imageLiteral(resourceName: "Record"), for: UIControlState())
            audioHelper.isRecording = false
            self.doRecord = false
        }
        else {
            videoDetailViewController.youtubePlayer.pauseVideo()
            if videoDetailViewController.youtubePlayer.playerState() != YTPlayerState.playing {
                audioHelper.startRecording()
            }
            else {
                self.doRecord = true
            }
            btnRecord.setTitle("Stop", for: UIControlState())
            audioHelper.isRecording = true
        }
    }

    @IBAction func queueAction(_ sender: Any) {
        print("Coming here")
        self.queueClip()
    }

    @IBAction func playVideoAction(_ sender: Any) {
        // Play action here
        if(doPlay) {
            videoDetailViewController.playPauseControl()
        } else {
            videoDetailViewController.playPauseControl()
        }
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

    func queueClip() {
        // Create a clip request
        self.createClip(startTime: videoDetailViewController.youtubePlayer.currentTime())
    }

    func createClip(startTime: Float) {
        // Create a clip request
        let dvxUpload = DvxUpload()
        print("The request is ")
        do {
            print("The starttime was \(startTime)")
            let request = try dvxUpload.createRequest(["AppId": Constants.APP_ID,
                                               "UserId": self.userId,
                                               "Movie": self.movieId,
                                               "MediaId": self.mediaId,
                                               "Time": "\(startTime)",
                                               "Chapter": "0",
                                               "Language": "English",
                                               "Token": self.userToken,
                                               "Function": "desc_extended"],
                                                      uploadURL: self.currentAudioTempURL)
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) in
                let result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("Data is ")
                print(data ?? "Undefined data")
                print ("Result is ")
                print(result ?? "Undefined result")
                print("Response is ")
                print (response ?? "Undefined response")
                print("Error is ")
                print(error ?? "Undefined error")
                
                if let httpResponse = response as? HTTPURLResponse
                {
                    if httpResponse.statusCode == 200  {
                        print("Looks good!")

                        //DispatchQueue.main.async {
                            let clipData = self.dvxApi.getClips(["Movie": self.movieId,
                                                                 "UserId": self.userId])
                            print("The clip Data is ")
                            print(clipData)
                            // Relayout the clips, since we need the new clip ID
                            self.layoutClips(clipData)
                        //}
                    }
                    else {
                        print("Encountered an error while attempting to add a clip")
                        print(error ?? "Undefined error")
                        print(httpResponse.statusCode)
                        DispatchQueue.main.async {
                            self.showNotification(
                                title: "Operation failed",
                                message: "Failed to create a new audio clip: \(error)"
                            )
                        }
                    }
                }
            })
            task.resume()
        } catch let error {
            print("An error occured \(error)")
        }
    }

    func showNotification(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
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

    // Audio session control
    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers)
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
            //session.setActive(false, with: AVAudioSessionCategoryOptions.duckOthers)
        }
        catch let error as Error {
            print("deactivate error")
            print(error)
        }
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
                    // activate the audio session
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
        let destURL = self.currentAudioFileDirectory.appendingPathComponent("\(self.sessionRecordingName!)_\(clip.index!).mp3")
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "PreviewDescriptionSegue" {
            let videoDetailViewController = segue.destination as! ViewController
            videoDetailViewController.movieID =  self.mediaId
            videoDetailViewController.currentMovieTitle = "Testing" // TODO: Change this
            let preferences = UserDefaults.standard
            if preferences.object(forKey: "session") != nil {
                 videoDetailViewController.displayAuthor = preferences.object(forKey: "username") as? String
            }
            videoDetailViewController.displayAuthorID = self.userId
        }
        else if segue.identifier == "EmbedPlayerSegue" {
            print("Calling this !!!!!!")
            videoDetailViewController = segue.destination as! ViewController
            videoDetailViewController.movieID =  self.mediaId
            print("The movie id is \(self.movieId)")
            videoDetailViewController.movieIdLocal = self.movieId
            videoDetailViewController.videoDurationInSeconds = self.videoDurationInSeconds
            videoDetailViewController.videoDurationString = self.videoDurationString
            videoDetailViewController.currentMovieTitle = self.movieName
            videoDetailViewController.displayAuthor = ""
            videoDetailViewController.displayAuthorID = self.userId
            videoDetailViewController.isEmbedded = true
        }
    }


    // TableView method implementation
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.audioClips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CreateDescriptionCellIdentifier"
        let cell:CreateDescriptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CreateDescriptionTableViewCell
        let clipItem  = self.audioClips[indexPath.row] as AudioClip
        let startTimeString: String = String(format: "%02d:%02d:%05.2f", clipItem.startHour, clipItem.startMinutes, clipItem.startSeconds )
        cell.lblStartTime.text = startTimeString
        cell.index = indexPath.row
        cell.startTime = clipItem.startTime
        //cell.videoDuration = Float(youtubePlayer.duration())
        cell.clipId = clipItem.id
        cell.clipData = clipItem.data
        if clipItem.isInline == true {
            cell.sliderInline.setOn(true, animated: false)
        }
        else {
            cell.sliderInline.setOn(false, animated: false)
        }
        return cell
    }
    
    func startPlay() {
        if(doPlay) {
            youtubePlayer.playVideo()
        } else {
            youtubePlayer.pauseVideo()
        }
    }
    
    func reset() {
        youtubePlayer.stopVideo()
    }

    // YouTubeDelegate methods
    // Called whenever the youtube-player changes its state.
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        // the player changed to state
        print(state.rawValue)
        if (state.rawValue == 4) {
            self.startPlay()
        }
        else if (state.rawValue == 2) { // state is 'playing'
            //change the button to text
            btnPlayVideo.setTitle("Pause", for: UIControlState())
            doPlay = false
        }
        else if (state.rawValue == 3) { // buffering / paused
            btnPlayVideo.setTitle("Play", for: UIControlState())
            doPlay = true
            if doRecord {
                audioHelper.startRecording()
            }
        }
        else if (state.rawValue == 5) { // stop
            btnPlayVideo.setTitle("Play", for: UIControlState())
            doPlay = true
        }
        else if (state.rawValue == 0) {
            btnPlayVideo.setTitle("Play", for: UIControlState())
            doPlay = true
            self.reset()
        }
        else if (state.rawValue == 1) { // movie ended
            btnPlayVideo.setTitle("Play", for: UIControlState())
            doPlay = true
            self.reset()
        }
    }


}
