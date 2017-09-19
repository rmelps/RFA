//
//  ProfileViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/18/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet weak var bioTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tracksContainerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    
    // Profile specific fields
    var image: UIImage!
    var bio: String!
    var name: String!
    var tag: String!
    
    // Tracks related to profile
    var tracks: [Track]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign profile specific fields
        self.profileImageView.image = image
        self.nameLabel.text = name
        self.tagLabel.text = tag
        self.bioTextView.text = bio
        
        let contentHeight = bioTextView.contentSize.height
        let vertPadding: CGFloat = 20.0
        
        if contentHeight < bioTextViewHeightConstraint.constant - vertPadding {
            self.bioTextViewHeightConstraint.constant = contentHeight + vertPadding
        }
    }
}
