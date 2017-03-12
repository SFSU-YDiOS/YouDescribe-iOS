//
//  VolumeControl.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/23/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation
import MediaPlayer

class VolumeControl {
    
    let volumeViewer = MPVolumeView()

    func setVolume(_ volume: Float) {
        /*let volumeView = MPVolumeView()
        if let view = volumeView.subviews.first as? UISlider {
            print("Setting this volume")
            view.value = 0
        }*/

        do{
            let audioSession = AVAudioSession.sharedInstance()
            do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient, with: .duckOthers)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            print("Ducked the audio")
            try audioSession.setActive(true)
            let audioVolume =  audioSession.outputVolume
            let audioVolumePercentage = audioVolume * 100
            print ("The volume is \(audioVolumePercentage)")
            //return Int(audioVolumePercentage)
        }catch{
            print("Error while getting volume level \(error)")
        }
        
        /*(MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(0, animated: false)*/
    }
    func drawControl(_ testview: UIView) {
        let volumeView = MPVolumeView(frame: testview.bounds)
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = true
        testview.addSubview(volumeView)
        /*let myButton = UIButton(frame: testview.bounds)

        print("The bounds are ")
        print (testview.bounds)
        myButton.setTitle("Hello", for: UIControlState())
        testview.addSubview(myButton)*/
    }
}
