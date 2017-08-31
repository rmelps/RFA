//
//  WordsmithHomeViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/3/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class WordsmithHomeViewController: UIViewController, WordsmithPageViewControllerChild {
    var wordsmithPageVC: WordsmithPageViewController!
    
    
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var statView: UIScrollView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    // Elements from PageViewController
    var firstName: String!
    var image: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameLabel.text = firstName
        profilePicImageView.image = image
        
        for view in welcomeStackView.arrangedSubviews {
            view.layer.shadowOffset = CGSize(width: 0, height: 0)
            view.layer.shadowOpacity = 1.0
            view.layer.shadowRadius = 10.0
            view.layer.shadowColor = statView.backgroundColor?.cgColor
        }
    
        profilePicImageView.layer.borderWidth = 1
        profilePicImageView.layer.masksToBounds = false
        profilePicImageView.layer.borderColor = UIColor.black.cgColor
        profilePicImageView.layer.cornerRadius = profilePicImageView.frame.height / 2
        profilePicImageView.clipsToBounds = true
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in statView.subviews {
            view.removeFromSuperview()
        }
        
        statView.translatesAutoresizingMaskIntoConstraints = false
        scrollViewHeightConstraint.constant = self.view.frame.height / 4
        
        let user = wordsmithPageVC!.signedInUser!
        print(user)
        
        var awards = [Stat]()
        
        awards.append(user.knowledge)
        awards.append(user.crowns)
        awards.append(user.stars)
        awards.append(user.downloads)
        
        
        for (index, award) in awards.enumerated() {
            
            
            
            let views = Bundle.main.loadNibNamed("StatView", owner: nil, options: nil)
            let singleStatView = views?[0] as! StatView
            
            self.statView.addSubview(singleStatView)
            
            let vertSpaceInPoints: CGFloat = 10
            let horizSpaceInPoints: CGFloat = 20
            let size = CGSize(width: statView.bounds.width - horizSpaceInPoints, height: singleStatView.bounds.height)
            let viewOrigin = CGPoint(x: horizSpaceInPoints / 2, y: CGFloat(size.height * CGFloat(index) + vertSpaceInPoints))
            
            
            
            singleStatView.frame = CGRect(origin: viewOrigin, size: size)
            self.statView.contentSize = CGSize(width: self.statView.bounds.width, height: singleStatView.bounds.height * CGFloat(index) + 50.0)
            
            singleStatView.alpha = 0.95
            singleStatView.layer.borderWidth = 1.5
            singleStatView.layer.borderColor = UIColor.black.cgColor
            singleStatView.layer.cornerRadius = 25.0
            singleStatView.layer.masksToBounds = false
            singleStatView.countLabel.text = String(award.value)
            singleStatView.statLabel.text = award.description
            
        }
        
    }
    
}
