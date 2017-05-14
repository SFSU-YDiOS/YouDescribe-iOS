//
//  VideoItemTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/26/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

protocol VideoItemTableViewCellDelegate {
    func showCellDetailMenu(mediaId: String, author: String)
}

class VideoItemTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var describerLabel: UILabel!
    @IBOutlet weak var btnDetail: UIButton!
    @IBOutlet weak var durationLabel: UILabel!

    var mediaId: String!
    var author: String!
    var movieId: String!
    var delegate: VideoItemTableViewCellDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.btnDetail.accessibilityLabel = "Menu"
        self.durationLabel.sizeToFit()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func showDetailAction(_ sender: Any) {
        self.delegate.showCellDetailMenu(mediaId: self.mediaId, author: self.author)
        print("Clicked here")
    }
}
