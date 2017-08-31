//
//  TrackTableViewCell.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    @IBOutlet weak var toolbarStackView: UIStackView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var flagButton: UIButton!
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var trackDescriptionTextView: UITextView!
    @IBOutlet weak var profileImageWidthConstraint: NSLayoutConstraint!
    
    weak var tableView: UITableView!
    
    // Button Selection Status
    var isLiked: Bool = false
    var isSaved: Bool = false
    var isFlagged: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        trackNameLabel.adjustsFontForContentSizeCategory = true
        userNameLabel.adjustsFontForContentSizeCategory = true
        self.selectionStyle = .gray
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
       // self.setNeedsLayout()
    }
    
    func displayToolBar(on: Bool) {
        if on {
            for element in toolbarStackView.arrangedSubviews {
                element.alpha = 1
                if let button = element as? UIButton {
                    setButtonImage(button: button, image: button.currentImage!)
                }
            }
        } else {
            for element in toolbarStackView.arrangedSubviews {
                element.alpha = 0
            }
        }
    }
    
    func setButtonImage(button: UIButton, image: UIImage) {
        let tImage = image.withRenderingMode(.alwaysTemplate)
        button.setImage(tImage, for: .normal)
        button.tintColor = UIColor(displayP3Red: 96/255, green: 170/255, blue: 255/255, alpha: 1.0)
        button.titleLabel?.textColor = button.tintColor
    }
    
    @IBAction func likeButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        var image = UIImage()
        if isLiked {
            image = UIImage(named: "favorite")!
            isLiked = false
            increase = false
        } else {
            image = UIImage(named: "favoriteFilled")!
            isLiked = true
            increase = true
        }
        if let vc = tableView.delegate as? WordsmithFeedTableViewController {
            vc.modifyPostStat(statName: "stars", increase: increase)
        }
        setButtonImage(button: sender, image: image)
    }
    @IBAction func saveButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        
        var image = UIImage()
        if isSaved {
            image = UIImage(named: "saveFeed")!
            isSaved = false
            increase = false
        } else {
            image = UIImage(named: "saveFeedFilled")!
            isSaved = true
            increase = true
        }
        if let vc = tableView.delegate as? WordsmithFeedTableViewController {
            vc.modifyPostStat(statName: "downloads", increase: increase)
        }
        setButtonImage(button: sender, image: image)
    }
    
    @IBAction func flagButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        
        var image = UIImage()
        if isFlagged {
            image = UIImage(named: "flag")!
            isFlagged = false
            increase = false
        } else {
            image = UIImage(named: "flagFilled")!
            isFlagged = true
            increase = true
        }
        if let vc = tableView.delegate as? WordsmithFeedTableViewController {
            vc.modifyPostStat(statName: "flags", increase: increase)
        }
        setButtonImage(button: sender, image: image)
    }
}
