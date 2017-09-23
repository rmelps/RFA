//
//  WordsmithHomeViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/3/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseDatabase

class WordsmithHomeViewController: UIViewController, WordsmithPageViewControllerChild {
    weak var wordsmithPageVC: WordsmithPageViewController!
    
    
    @IBOutlet weak var publicProfButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var menuBarIconView: UIImageView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var statView: UIScrollView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    
    // Stat view div sizes
    var size: CGSize!
    
    // Elements from PageViewController
    var firstName: String!
    var image: UIImage?
    
    var awards = [Stat]()
    var loadLatch: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .currentContext
        
        userNameLabel.text = firstName
        profilePicImageView.image = image
        scrollViewHeightConstraint.constant = topBar.bounds.height
        menuBarIconView.tintColor = .white
        menuBarIconView.image = UIImage(named: "popUp")?.withRenderingMode(.alwaysTemplate)
        topBar.layer.cornerRadius = 7.0
        statView.layer.cornerRadius = 7.0
        
        publicProfButton.layer.cornerRadius = 3.0
        
        
        for view in welcomeStackView.arrangedSubviews {
            view.layer.shadowOffset = CGSize(width: 0, height: 0)
            view.layer.shadowOpacity = 1.0
            view.layer.shadowRadius = 10.0
            view.layer.shadowColor = statView.backgroundColor?.cgColor
        }
    
        profilePicImageView.layer.borderWidth = 3.0
        profilePicImageView.layer.masksToBounds = false
        profilePicImageView.layer.borderColor = UIColor.white.cgColor
        profilePicImageView.layer.cornerRadius = 8.0
        profilePicImageView.clipsToBounds = true
        
        addStatObserver()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let user = AppDelegate.signedInUser {
            userNameLabel.text = wordsmithPageVC.getFirstName(user: user)
            profilePicImageView.image = AppDelegate.signedInProfileImage
        }
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
       
        awards.append(user.knowledge)
        awards.append(user.crowns)
        awards.append(user.stars)
        awards.append(user.downloads)
        
        
        for (index, award) in awards.enumerated() {
            
            
            
            let views = Bundle.main.loadNibNamed("StatView", owner: nil, options: nil)
            let singleStatView = views?[0] as! StatView
            singleStatView.accessibilityIdentifier = award.description
            
            self.statView.addSubview(singleStatView)
            
            let leftPadding: CGFloat = 5
            let horizInterPadding: CGFloat = 3
            let vertInterPadding: CGFloat = 3
            let topPadding: CGFloat = 5
            
            let width = (statView.bounds.width / 2) - (horizInterPadding / 2) - leftPadding
            let height = width * 0.75
            
            size = CGSize(width: width , height: height)
            
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
    @IBAction func settingsButtonDidTouchUp(_ sender: UIButton) {
        self.performSegue(withIdentifier: "presentSettingsSegue", sender: self)
    }
    
    @IBAction func publicProfButtonDidTouchUp(_ sender: UIButton) {
        self.performSegue(withIdentifier: "presentProfileSegue", sender: self)
    }
    
    @IBAction func topBarDidPan(_ sender: UIPanGestureRecognizer) {
        let yTouch = sender.location(in: self.view).y
        let topHeight = size.height * 2 + topBar.bounds.height * 2
        let minAlpha: CGFloat = 0.6
        let maxAlpha: CGFloat = 0.95
        let alphaDiff = maxAlpha - minAlpha
        let ratioToFullHeight = scrollViewHeightConstraint.constant / topHeight
        
        switch sender.state {
        case .began, .possible, .changed:
            var atMax: Bool = false
            
            //Configure alpha for height
            statView.alpha = (ratioToFullHeight * alphaDiff) / (alphaDiff * 2) + minAlpha
            
            let yView = statView.frame.origin.y
            let diff = yView - yTouch
            scrollViewHeightConstraint.constant += diff
            
            if scrollViewHeightConstraint.constant >= topHeight + 25 {
                atMax = true
                sender.state = .ended
            }
            if scrollViewHeightConstraint.constant <= topBar.frame.height {
                atMax = true
                scrollViewHeightConstraint.constant = topBar.frame.height
            }
            if !atMax {
                for view in statView.subviews {
                    if view is StatView {
                        view.frame.origin.y += diff
                    }
                }
            }
            self.view.layoutIfNeeded()
        case .ended, .cancelled :
            let velY = sender.velocity(in: self.view).y
            let inTopHalf: Bool = scrollViewHeightConstraint.constant > (topHeight / 2)
            let dirUp: Bool = velY < 0
            let minUpVel: CGFloat = -500.0
            let minDownVel = -minUpVel
            
            if velY < minUpVel || scrollViewHeightConstraint.constant > topHeight || (inTopHalf && dirUp) {
                scrollViewHeightConstraint.constant = topHeight
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
                    self.statView.alpha = maxAlpha
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else if velY > minDownVel || (!inTopHalf && !dirUp) {
                scrollViewHeightConstraint.constant = topBar.frame.height
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                    self.statView.alpha = minAlpha
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        default:
            break
        }
        
       
    }
    
    func addStatObserver() {
        let userDBRef = FIRDatabase.database().reference().child("users").child(wordsmithPageVC.signedInUser.uid)
        userDBRef.observe(.value) { (snapshot: FIRDataSnapshot) in
            if let val = snapshot.value as? [String:Any] {
                for view in self.statView.subviews {
                    if let statView = view as? StatView, let id = view.accessibilityIdentifier, let stat = val[id.lowercased()] as? Int {
                        if let text = statView.countLabel.text, stat != Int(text) {
                            statView.countLabel.text = String(stat)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let user = wordsmithPageVC.signedInUser else {
            fatalError("The application has crashed; could not access signed in user")
        }
        
        switch segue.identifier!{
        case "presentSettingsSegue":
            let vc = segue.destination as! SettingsViewController
            if let image = self.profilePicImageView.image {
                vc.profileImage = image
            }
            vc.userName = user.name
            vc.tag = user.tagLine
            vc.bio = user.biography
            vc.user = user
        case "presentProfileSegue":
            let vc = segue.destination as! ProfileViewController
            if let image = self.profilePicImageView.image {
                vc.image = image
            }
            vc.user = user
            vc.name = user.name
            vc.tag = user.tagLine
            vc.bio = user.biography
            vc.delegate = self
        default:
            break
        }
    }
    
}
