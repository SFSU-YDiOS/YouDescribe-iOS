import UIKit

class YouTubeHelperControl: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.backgroundColor = UIColor.red
        addSubview(button)
    }

    override var intrinsicContentSize : CGSize {
        return CGSize(width: 560, height: 258)
    }
}   
