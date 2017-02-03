//
//  DetailShareViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 1/20/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class DetailShareViewController: UIViewController {


    var mediaId: String?
    var preferredAuthor: String?
    var movieTitle: String?

    @IBOutlet weak var embedCode: UITextView!
    @IBOutlet weak var shareVideo: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        embedCode.text = self.getEmbedCode()
        shareVideo.text = self.getShareCode()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onShareClicked(_ sender: Any) {
        //Set the default sharing message.
        let message = "Watch \(self.movieTitle!) with description on YouDescribe! "
        //Set the link to share.
        if let link = NSURL(string: self.getShareCode())
        {
            let objectsToShare = [message + link.absoluteString!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityType.airDrop,
            UIActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func getEmbedCode() -> String {
        return "<span itemscope='' itemtype='http://schema.org/VideoObject'> " +
        "<meta itemprop='accessibilityFeature' content='audioDescription'/>" +
        "<meta itemprop='name' content=\(self.movieTitle!) />" +
        "<iframe width='480' height='360' " +
        "src='http://youdescribe.org/player.php?w=480&h=360&v=\(self.mediaId!)&d=\(self.preferredAuthor!)&embed=true'> " +
        "</iframe>" +
        "</span>"
    }
    
    func getShareCode() -> String {
        return "http://youdescribe.org/player.php?v=\(self.mediaId!)&prefer_d=\(self.preferredAuthor!)"
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
