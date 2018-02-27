//
//  MessagesListTableViewCell.swift
//  Taggy
//
//  Created by Ross Hunter on 09/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class MessagesListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var newMessagesImageView: UIImageView!
    @IBOutlet weak var taggyImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
