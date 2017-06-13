//
//  TestBedViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/23/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class TestBedViewController: UIViewController {

    @IBOutlet weak var mainView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // create the new control
        var extendedYouTubeControl: ExtendedYouTubeControl  = ExtendedYouTubeControl(frame: CGRect(x: 10, y: 10, width: UIScreen.main.bounds.width - 10, height: 100))
        extendedYouTubeControl.mediaId = "Fzn_AKN67oI"
        mainView.addSubview(extendedYouTubeControl)
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
