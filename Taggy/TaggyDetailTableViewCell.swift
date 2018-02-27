//
//  TaggyDetailTableViewCell.swift
//  Taggy
//
//  Created by Ross Hunter on 13/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class TaggyDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
