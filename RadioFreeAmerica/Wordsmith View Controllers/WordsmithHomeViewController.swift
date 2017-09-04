//
//  WordsmithHomeViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/3/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class WordsmithHomeViewController: UIViewController, WordsmithPageViewControllerChild {
    weak var wordsmithPageVC: WordsmithPageViewController!
    
    
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var statView: UIScrollView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    // Elements from PageViewController
    var firstName: String!
    var image: UIImage?
    
    var awards = [Stat]()
    var loadLatch: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameLabel.text = firstName
        profilePicImageView.image = image
        scrollViewHeightConstraint.constant = topBar.bounds.height
        
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
        
        guard !loadLatch else {
            return
        }
        
        for view in statView.subviews {
            if view is StatView {
                view.removeFromSuperview()
            }
        }
 
        statView.translatesAutoresizingMaskIntoConstraints = false
        
        let user = wordsmithPageVC!.signedInUser!
        print(user)
        
       
        
        awards.append(user.knowledge)
        awards.append(user.crowns)
        awards.append(user.stars)
        awards.append(user.downloads)
        
        
        for (index, award) in awards.enumerated() {
            
            
            
            let views = Bundle.main.loadNibNamed("StatView", owner: nil, options: nil)
            let singleStatView = views?[0] as! StatView
            
            self.statView.addSubview(singleStatView)
            
            let leftPadding: CGFloat = 5
            let horizInterPadding: CGFloat = 3
            let vertInterPadding: CGFloat = 3
            let topPadding: CGFloat = 5
            
            let width = (statView.bounds.width / 2) - (horizInterPadding / 2) - leftPadding
            let height = width * 0.75
            
            let size = CGSize(width: width , height: height)
            
            var x = CGFloat()
            var y = CGFloat()
            
            if index % 2 == 0 {
                x = leftPadding
            } else {
                x = statView.bounds.width - leftPadding - size.width
            }
            if index < 2 {
                y = topPadding
            } else {
                y = topPadding + size.height + vertInterPadding
            }
            
            let viewOrigin = CGPoint(x: x, y: y)
            
            singleStatView.frame = CGRect(origin: viewOrigin, size: size)
            
            singleStatView.translatesAutoresizingMaskIntoConstraints = false
            singleStatView.heightAnchor.constraint(equalToConstant: height).isActive = true
            singleStatView.widthAnchor.constraint(equalToConstant: width).isActive = true
            singleStatView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: y).isActive = true
            singleStatView.leftAnchor.constraint(equalTo: statView.leftAnchor, constant: x).isActive = true
            
            
            self.statView.contentSize = CGSize(width: self.statView.bounds.width, height: size.height * 2 + vertInterPadding + (topPadding * 2))
            
            singleStatView.layer.borderWidth = 1.5
            singleStatView.layer.borderColor = UIColor.white.cgColor
            singleStatView.layer.cornerRadius = 5.0
            singleStatView.layer.masksToBounds = false
            
            let image = UIImage(named: award.description.lowercased())?.withRenderingMode(.alwaysTemplate)
            
            singleStatView.iconImageView.image = image
            singleStatView.tintColor = .white
            singleStatView.countLabel.text = String(award.value)
            singleStatView.statLabel.text = award.description
        }
        loadLatch = true
    }
    @IBAction func topBarDidPan(_ sender: UIPanGestureRecognizer) {
        let yTouch = sender.location(in: self.view).y
        let yView = statView.frame.origin.y
        let diff = yView - yTouch
        scrollViewHeightConstraint.constant += diff
        
        for view in statView.subviews {
            if view is StatView {
                view.frame.origin.y += diff
            }
        }
        print(scrollViewHeightConstraint.constant)
        self.view.layoutIfNeeded()
    }
    
}
