//
//  AuthorMoviesTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/25/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class AuthorMoviesTableViewCell: UITableViewCell {

    @IBOutlet weak var lblMovieName: UILabel!
    @IBOutlet weak var lblAuthorName: UILabel!
    @IBOutlet weak var imgViewThumbnail: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
