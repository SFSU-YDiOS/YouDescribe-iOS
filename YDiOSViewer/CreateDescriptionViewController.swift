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

    var mediaId: String!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var currentAudioFileDirectory: URL!
    var currentAudioFileName: String = "TestRecording.m4a"
    var sessionRecordingName: String!
    var totalUploadedClips: Int!
    var yPos: Int!
    var audioClips: [AudioClip]!

    @IBOutlet weak var youtubePlayer: YTPlayerView!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnUpload: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        youtubePlayer.load(withVideoId: mediaId)
        // Do any additional setup after loading the view.
        
        audioPlayer?.delegate = self
        audioRecorder?.delegate = self
        self.sessionRecordingName = self.generateUniqueId()
        self.totalUploadedClips = 0
        self.currentAudioFileDirectory =  FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        // Set up the audio recorder
        setUpAudioRecord()
        self.yPos = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                btnPlayPause.setTitle("Play", for: UIControlState())
                return
            }
        }
        
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                    btnPlayPause.setTitle("Play", for: UIControlState()) // Change this when we listen for events
                    print("Playing the audio url")
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    // to be called when the cancel button is pressed.
    func cancel() {
        // stop the audio recorder
        audioRecorder?.stop()
        
        // deactivate the audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch let error {
            print(error)
        }
    }
    
    // to be called when the record button is pressed.
    func record() {
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
    
    @IBAction func uploadAction(_ sender: Any) {
        var newClip: AudioClip!
        newClip = AudioClip()
        newClip.startTime? = 45.56
        newClip.audioFilePath? = self.currentAudioFileDirectory.appendingPathComponent(self.sessionRecordingName).absoluteString
        newClip.index = self.totalUploadedClips
        self.audioClips.append(newClip)

        // create a new view
        //let clipView = UIStackView(frame: CGRect(x: 5, y: self.yPos, width: 480, height: 50))
        let clipView = UIView(frame: CGRect(x: 5, y: self.yPos, width: 400, height: 50))
        clipView.backgroundColor = UIColor.lightGray
        clipView.contentMode = .left


        // create the play button
        let playButton = UIButton(frame: CGRect(x:5, y:15, width:50, height:20))
        playButton.backgroundColor = UIColor.darkGray
        playButton.setTitle("Play", for: .normal)
        playButton.tag = self.totalUploadedClips
        playButton.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
        clipView.addSubview(playButton)

        // create the nudge buttons
        let btnNudgeLeftSecs = UIButton(frame: CGRect(x:65, y:15, width:30, height:20))
        btnNudgeLeftSecs.backgroundColor = UIColor.darkGray
        btnNudgeLeftSecs.setTitle("<<", for: .normal)
        btnNudgeLeftSecs.tag = self.totalUploadedClips
        btnNudgeLeftSecs.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeLeftSecs)

        // create the nudge buttons
        let btnNudgeLeftMillisecs = UIButton(frame: CGRect(x:95, y:15, width:20, height:20))
        btnNudgeLeftMillisecs.backgroundColor = UIColor.darkGray
        btnNudgeLeftMillisecs.setTitle("<", for: .normal)
        btnNudgeLeftMillisecs.tag = self.totalUploadedClips
        btnNudgeLeftMillisecs.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeLeftMillisecs)

        // create the time label
        let timeLabel = UILabel(frame: CGRect(x:115, y:15, width:100, height:20))
        let currentMarkerTime: Float = youtubePlayer.currentTime()
        let hours = (Int(currentMarkerTime)) / (3600) as Int
        let mins = (Int(currentMarkerTime) / 60) % 60
        let secs:Float = (currentMarkerTime.truncatingRemainder(dividingBy: 60)).truncatingRemainder(dividingBy: 60)
        let millisecs:Float = (currentMarkerTime) - floor(currentMarkerTime)
        timeLabel.text = "\(hours):\(mins):\(secs+millisecs)"

        // create the nudge right buttons
        let btnNudgeRightMillisecs = UIButton(frame: CGRect(x:200, y:15, width:20, height:20))
        btnNudgeRightMillisecs.backgroundColor = UIColor.darkGray
        btnNudgeRightMillisecs.setTitle(">", for: .normal)
        btnNudgeRightMillisecs.tag = self.totalUploadedClips
        btnNudgeRightMillisecs.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
        clipView.addSubview(btnNudgeRightMillisecs)

        // create the nudge right buttons
        let btnNudgeRightSecs = UIButton(frame: CGRect(x:230, y:15, width:30, height:20))
        btnNudgeRightSecs.backgroundColor = UIColor.darkGray
        btnNudgeRightSecs.setTitle(">>", for: .normal)
        btnNudgeRightSecs.tag = self.totalUploadedClips
        btnNudgeRightSecs.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
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
        btnDeleteClip.tag = self.totalUploadedClips
        btnDeleteClip.addTarget(self, action: #selector(CreateDescriptionViewController.action(_:)), for: .touchDown)
        clipView.addSubview(btnDeleteClip)

        self.scrollView.addSubview(clipView)
        self.totalUploadedClips = self.totalUploadedClips + 1
        self.yPos = self.yPos + 50 + 5
        print("total clips are \(self.totalUploadedClips)")
        
        scrollView.contentSize = CGSize(width: 400, height: CGFloat((clipView.frame.height + 10) * CGFloat(self.totalUploadedClips)))
        clipView.addSubview(timeLabel)
    }
 
    func stateChanged(_ switchview: UISwitch!) {
        print("The state is \(switchview.isOn)")
    }

    //then make a action method
    func action(_ button: UIButton!) {
        print("Play the video associated with this clip")
    }

    func saveClipLocally(_ recording: AudioClip) {
        let sourceURL = self.currentAudioFileDirectory.appendingPathComponent(self.currentAudioFileName)
        let destURL = self.currentAudioFileDirectory.appendingPathComponent("\(self.sessionRecordingName)_\(recording.index)")
        self.copyFile(
            sourcePath: sourceURL,
            destPath: destURL)
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
