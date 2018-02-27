//
//  UnactivatedTableViewCell.swift
//  Taggy
//
//  Created by Ross Hunter on 09/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class UnactivatedTableViewCell: UITableViewCell {

    @IBOutlet weak var activationDateLabel: UILabel!
    @IBOutlet weak var taggyImageView: UIImageView!
    @IBOutlet weak var downloadTaggyButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        downloadTaggyButton.setBackgroundImage(UIImage(named:"downloadTaggyHighlighted"), for: .highlighted)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
