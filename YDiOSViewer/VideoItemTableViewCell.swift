//
//  VideoItemTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/26/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class VideoItemTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var describerLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
