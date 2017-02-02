//
//  SearchResultsTableViewCell.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/27/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class SearchResultsTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var thumbnailView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
