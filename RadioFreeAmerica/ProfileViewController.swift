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
    
    // Check whether the signed in user is following this user
    var isFollowed = false
    
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
        if let image = self.image {
            self.profileImageView.image = image
        }
        self.nameLabel.text = name
        self.tagLabel.text = tag
        self.bioTextView.text = bio
        
        let contentHeight = bioTextView.contentSize.height
        let vertPadding: CGFloat = 20.0
        
        if contentHeight < bioTextViewHeightConstraint.constant - vertPadding {
            self.bioTextViewHeightConstraint.constant = contentHeight + vertPadding
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navCon = self.navigationController {
            print("found navcon")
            // Make navigation bar appear
            navCon.navigationBar.isHidden = false
            
            // Add a right bar button item to follow this guy
            let image = UIImage(named: "addFriend")
            let followItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ProfileViewController.followThisUser(_:)))
            self.navigationItem.rightBarButtonItem = followItem
        }
    }
    @IBAction func goBackButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func followThisUser(_ sender: Any) {
        print("following...")
        
        if isFollowed {
            self.navigationItem.rightBarButtonItem?.image = UIImage(named: "addFriend")
            isFollowed = false
        } else {
            self.navigationItem.rightBarButtonItem?.image = UIImage(named: "addFriendFilled")
            isFollowed = true
        }
    }
}
