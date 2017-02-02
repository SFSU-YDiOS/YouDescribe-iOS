//
//  TabBarViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 1/24/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    var myString: String = ""
    var preferredAuthor: String = ""
    var mediaId: String = ""
    var movieTitle: String = ""
    var detailInfo: DetailInfoViewController?
    var detailShare: DetailShareViewController?
    var detailRequest: DetailRequestViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let barViewControllers = self.viewControllers
        
        // Get all YouTube datat about a video.
        detailInfo = barViewControllers?[0] as? DetailInfoViewController
        detailShare = barViewControllers?[1] as? DetailShareViewController
        detailRequest = barViewControllers?[2] as? DetailRequestViewController
        print(self.preferredAuthor)
        print(self.mediaId)
        
        // assign the mediaId
        detailInfo?.mediaId = self.mediaId
        detailRequest?.mediaId = self.mediaId
        detailRequest?.preferredAuthor = self.preferredAuthor
        detailRequest?.movieTitle = self.movieTitle
        detailShare?.mediaId = self.mediaId
        detailShare?.preferredAuthor = self.preferredAuthor
        detailShare?.movieTitle = self.movieTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
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
