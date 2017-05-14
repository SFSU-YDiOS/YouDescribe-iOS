//
//  SearchResultsTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/27/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

protocol SearchResultTableViewCellDelegate {
    func showCellDetailMenu(mediaId: String, author: String)
}

class SearchResultsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var durationLabel: UILabel!

    var delegate: SearchResultTableViewCellDelegate!
    var mediaId: String!
    var author: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.durationLabel.sizeToFit()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBAction func onMenuClicked(_ sender: Any) {
        self.delegate.showCellDetailMenu(mediaId: self.mediaId, author: self.author)
    }

}
