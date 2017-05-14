//
//  AppExtensions.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/23/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation
import AVFoundation

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIImageView {
    public func imageFromServerURL(urlString: String) {
        
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in

            if error != nil {
                print(error!)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }
}


extension String {
    func matchPattern(patStr:String)->Bool {
        var isMatch:Bool = false
        do {
            let regex = try NSRegularExpression(pattern: patStr, options: [.caseInsensitive])
            let result = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, characters.count))
            
            if (result != nil)
            {
                isMatch = true
            }
        }
        catch {
            isMatch = false
        }
        return isMatch
    }
    
    func durationInSeconds() -> Float {
        let tokens = self.components(separatedBy: ":")
        var convertedTime: Float = 0.0
        var hours: Float = 0.0
        var minutes: Float = 0.0
        var seconds: Float = 0.0
        if tokens.count > 0{
            if tokens.count == 3 {
                hours = Float(tokens[0])! * 60 * 60
                minutes = Float(tokens[1])! * 60
                seconds = Float(tokens[2])!
            }
            else {
                minutes = Float(tokens[0])! * 60
                seconds = Float(tokens[1])!
            }
            convertedTime = hours + minutes + seconds
        }
        return convertedTime
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}


extension UITextField {
    class func connectFields(fields:[UITextField]) -> Void {
        guard let last = fields.last else {
            return
        }
        for i in 0 ..< fields.count - 1 {
            fields[i].returnKeyType = .next
            fields[i].addTarget(fields[i+1], action: #selector(UIResponder.becomeFirstResponder), for: .editingDidEndOnExit)
        }
        last.returnKeyType = .done
        last.addTarget(last, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)
    }
}

extension Float {
    func millisToFormattedString() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        if hours == 0 {
            return String(format:"%02i:%02i", minutes, seconds)
        }
        else {
            return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        }
    }
}

// FileManager extensions for documents and cache directories
extension FileManager {
    class func documentsDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
    
    class func cachesDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
}
