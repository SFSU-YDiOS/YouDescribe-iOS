//
//  DetailRequestViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 1/20/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit
import Social

class DetailRequestViewController: UIViewController {

    var mediaId:String?
    var preferredAuthor:String?
    var movieTitle:String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func postToTwitter() {
        let vc = SLComposeViewController(forServiceType:SLServiceTypeTwitter)
        vc?.setInitialText("Requesting a description of \"\(self.movieTitle!)\" at http://youdescribe.org/addCreate.php?v=\(self.mediaId!) .\n #YouDescribe #ydrequest #ViDesc")
        self.present(vc!, animated: true, completion: nil)
    }
    
    @IBAction func onClickTweet(_ sender: Any) {
        postToTwitter()
    }
}

