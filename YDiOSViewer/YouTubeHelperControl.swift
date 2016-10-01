//
//  YouTubeHelperControl.swift
//  YDiOSViewer
//
//  Created by Rupal Khilari on 9/28/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class YouTubeHelperControl: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.backgroundColor = UIColor.redColor()
        addSubview(button)
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 560, height: 258)
    }
}   
