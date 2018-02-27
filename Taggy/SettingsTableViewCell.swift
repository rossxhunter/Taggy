//
//  SettingsTableViewCell.swift
//  Taggy
//
//  Created by Ross Hunter on 10/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var settingsIconImageView: UIImageView!
    @IBOutlet weak var settingsTextLabel: UILabel!
    @IBOutlet weak var settingsValueLabel: UILabel!

    @IBOutlet weak var passwordTextField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
