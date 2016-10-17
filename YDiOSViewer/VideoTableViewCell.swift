//
//  VideoTableViewCell.swift
//  YDiOSViewer
//
//  Created by Madhura Patil on 10/16/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class VideoTableViewCell: UITableViewCell {
    @IBOutlet var videoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
