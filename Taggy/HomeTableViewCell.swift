//
//  HomeTableViewCell.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var taggyNameLabel: UILabel!
    @IBOutlet weak var taggyLostStatusImageView: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
