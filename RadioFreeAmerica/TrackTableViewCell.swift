//
//  TrackTableViewCell.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    @IBOutlet weak var profileButton: UIButton!
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
    weak var track: Track!
    var user: User!
    
    // Button Selection Status
    var isLiked: Bool = false {
        didSet{
            if isLiked {
                setButtonImage(button: likeButton, image: UIImage(named: "favoriteFilled")!)
            } else {
                setButtonImage(button: likeButton, image: UIImage(named: "favorite")!)
            }
        }
    }
    var isSaved: Bool = false {
        didSet {
            if isSaved {
                setButtonImage(button: saveButton, image: UIImage(named: "saveFeedFilled")!)
            } else {
                setButtonImage(button: saveButton, image: UIImage(named: "saveFeed")!)
            }
        }
    }
    var isFlagged: Bool = false {
        didSet {
            if isFlagged {
                setButtonImage(button: flagButton, image: UIImage(named: "flagFilled")!)
            } else {
                setButtonImage(button: flagButton, image: UIImage(named: "flag")!)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        trackNameLabel.adjustsFontForContentSizeCategory = true
        userNameLabel.adjustsFontForContentSizeCategory = true
        
        self.setButtonImage(button: profileButton, image: UIImage(named: "user")!)
        self.selectionStyle = .gray
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
    
    func refreshButtonStyle(forTrack track: Track, forUser uid: String) {
        let downloads = SavedTrackManager.savedTracks
        let stars = Set(track.stars)
        let flags = Set(track.flags)
        
        for download in downloads {
            if let key = download.key {
                if track.key == key {
                    self.isSaved = true
                    break
                } else {
                    self.isSaved = false
                }
            }
        }
        if stars.contains(uid) {
            self.isLiked = true
        } else {
            self.isLiked = false
        }
        if flags.contains(uid) {
            self.isFlagged = true
        } else {
            self.isFlagged = false
        }
    }
    @IBAction func profileButtonDidTouchUp(_ sender: UIButton) {
        let tableVC = tableView.delegate as! WordsmithFeedTableViewController
        let activityIndicator = ActivityIndicatorView(withProgress: false)
        let parent = tableVC.parentVC
        parent!.view.addSubview(activityIndicator)
        tableVC.retrieveUserProfile(forTrack: track) { (user: User?) in
            activityIndicator.removeFromSuperview()
            if let user = user {
                self.user = user
                tableVC.performSegue(withIdentifier: "showProfileFromTableSegue", sender: self)
            } else {
                AppDelegate.presentErrorAlert(withMessage: "Could not load profile!", fromViewController: parent!)
            }
        }
    }
    
    @IBAction func likeButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        if isLiked {
            isLiked = false
            increase = false
        } else {
            isLiked = true
            increase = true
        }
        if let vc = tableView.delegate as? WordsmithFeedTableViewController {
            FireAudioManager.modifyPostStat(statName: "stars", increase: increase, forTrack: self.track, inGenre: vc.genre)
        }
    }
    @IBAction func saveButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        let vc = tableView.delegate as? WordsmithFeedTableViewController
        
        if isSaved {
            if let vc = vc {
              AppDelegate.presentErrorAlert(withMessage: "File has already been saved!", fromViewController: vc)
            }
            return
        } else {
            isSaved = true
            increase = true
        }
        if let vc = vc {
            FireAudioManager.modifyPostStat(statName: "downloads", increase: increase, forTrack: self.track, inGenre: vc.genre)
        }
    }
    
    @IBAction func flagButtonDidTouchUp(_ sender: UIButton) {
        var increase: Bool!
        
        if isFlagged {
            isFlagged = false
            increase = false
        } else {
            isFlagged = true
            increase = true
        }
        if let vc = tableView.delegate as? WordsmithFeedTableViewController {
            FireAudioManager.modifyPostStat(statName: "flags", increase: increase, forTrack: self.track, inGenre: vc.genre)
        }
    }
}
