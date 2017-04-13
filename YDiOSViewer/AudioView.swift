//
//  AudioView.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/13/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class AudioView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.blue.cgColor)
        context?.addRect(rect)
        context?.strokePath()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(rect)
    }

}
