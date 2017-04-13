//
//  AuthorMoviesTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/25/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

protocol AuthorMoviesTableViewCellDelegate {
    func showCellDetailMenu(mediaId: String, author: String)
}

class AuthorMoviesTableViewCell: UITableViewCell {

    @IBOutlet weak var lblMovieName: UILabel!
    @IBOutlet weak var lblAuthorName: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var btnMenu: UIButton!

    var delegate: AuthorMoviesTableViewCellDelegate!
    var mediaId: String!
    var author: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onMenuClicked(_ sender: Any) {
        self.delegate.showCellDetailMenu(mediaId: self.mediaId, author: self.author)
    }
}
