//
//  TrackTableViewCell.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var flagButton: UIButton!
    @IBOutlet weak var crownButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var trackDescriptionTextView: UITextView!
    @IBOutlet weak var profileImageWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        trackNameLabel.adjustsFontForContentSizeCategory = true
        userNameLabel.adjustsFontForContentSizeCategory = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        trackDescriptionTextView.backgroundColor = .black
    }

}
