//
//  MainViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import FacebookLogin
import FacebookCore
import GoogleSignIn

enum SignInButtonType {
    case google
    case facebook
}

enum PortalType {
    case producer
    case wordsmith
}

class MainViewController: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var wordsmithPortalButtonYConstraint: NSLayoutConstraint!
    @IBOutlet weak var wordsmithPortalButton: MenuButton!
    @IBOutlet weak var producerPortalButtonYConstraint: NSLayoutConstraint!
    @IBOutlet weak var producerPortalButton: MenuButton!
    @IBOutlet weak var googleButtonCenterXAlignment: NSLayoutConstraint!
    @IBOutlet weak var googleButtonCenterYAlignment: NSLayoutConstraint!
    @IBOutlet weak var logInButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var logInWithFacebookButton: UIButton!
    @IBOutlet weak var logInWithGoogleButton: UIButton!
    @IBOutlet weak var logInButtonCenterXAlignment: NSLayoutConstraint!
    @IBOutlet weak var logInButtonCenterYAlignment: NSLayoutConstraint!
    
    // Create label for when user enters portal
    let portalLabel = UILabel()
    
    // Music Note particle emitter
    let particleEmitter = CAEmitterLayer()
    
    // Background Color Gradient
    let gradient = CAGradientLayer()
    
    // Button states
    var isSignedIn: Bool = false
    
    // Original Constraint Constants
    var googleOrigXConst: CGFloat!
    var googleOrigYConst: CGFloat!
    var facebookOrigXConst: CGFloat!
    var facebookOrigYConst: CGFloat!
    
    // Firebase Database references
    var userDBRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        let gradientColor = UIColor(red: 79/255, green: 199/255, blue: 113/255, alpha: 1.0).cgColor
        
        gradient.frame = self.view.bounds
        gradient.colors = [UIColor.white.cgColor, gradientColor]
        
        self.view.layer.insertSublayer(gradient, at: 0)
        
        createMusicNoteParticles()
        
        logInWithFacebookButton.layer.cornerRadius = 3.0
        logInWithGoogleButton.layer.cornerRadius = 3.0
        
        // Set original constraint constants
        googleOrigXConst = googleButtonCenterXAlignment.constant
        googleOrigYConst = googleButtonCenterYAlignment.constant
        facebookOrigXConst = logInButtonCenterXAlignment.constant
        facebookOrigYConst = logInButtonCenterYAlignment.constant
        
        // Configure portal label
        portalLabel.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.width * 0.75, height: 500.0))
        portalLabel.textAlignment = .center
        portalLabel.adjustsFontSizeToFitWidth = true
        portalLabel.adjustsFontForContentSizeCategory = true
        portalLabel.center = view.center
        portalLabel.minimumScaleFactor = 0.05
        portalLabel.alpha = 0
        
        // Configure FIRDatabaseReferences
        userDBRef = FIRDatabase.database().reference().child("users")
        
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure Producer button
        let pImage = UIImage(named: "cassette")
        let tintedPImage = pImage?.withRenderingMode(.alwaysTemplate)
        producerPortalButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
        producerPortalButton.setImage(tintedPImage, for: .normal)
        producerPortalButton.tintColor = .white
        producerPortalButton.alpha = 0
        producerPortalButton.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        
        producerPortalButtonYConstraint.constant = self.view.bounds.height / 4 - 60
        
        // Configure Wordsmith button
        let wImage = UIImage(named: "microphone")
        let tintedWImage = wImage?.withRenderingMode(.alwaysTemplate)
        wordsmithPortalButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
        wordsmithPortalButton.setImage(tintedWImage, for: .normal)
        wordsmithPortalButton.tintColor = .white
        wordsmithPortalButton.alpha = 0
        wordsmithPortalButton.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        
        wordsmithPortalButtonYConstraint.constant = self.view.bounds.height / 4 - 40
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "chooseGenreSegue":
            let vc = segue.destination as! GenreChoiceViewController
            vc.gradient = self.gradient
            vc.gradientColor = wordsmithPortalButton.buttonColor.cgColor
            
        default:
            break
        }
    }

    @IBAction func loginWithFacebookButtonTapped(_ sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.hidesWhenStopped = true
        
        let loginManager = LoginManager()
        
        if isSignedIn {
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                loginManager.logOut()
                self.resizeAndMoveLogInButton(button: logInWithFacebookButton, type: .facebook, signingIn: false)
            } catch let error {
                print(error.localizedDescription)
            }
            
        } else if let accessToken = AccessToken.current {
            activityIndicator.center = self.wordsmithPortalButton.center
            self.view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            sender.isEnabled = false
            
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
            FIRAuth.auth()?.signIn(with: credential, completion: { (user:FIRUser?, error:Error?) in
                activityIndicator.stopAnimating()
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                self.resizeAndMoveLogInButton(button: sender, type: .facebook, signingIn: true)
                
                if let firUser = user {
                    
                    let userDBRef = FIRDatabase.database().reference().child("users")
                    let profPicStorRef = FIRStorage.storage().reference().child("profilePics")
                    
                    let thisUserDBRef = userDBRef.child(firUser.uid)
                    
                    for profile in firUser.providerData {
                        
                        let profPic = String(describing: profile.photoURL!)
                        
                        userDBRef.observeSingleEvent(of: .value, with: { (snapShot) in
                            
                            
                            if snapShot.hasChild(firUser.uid) {
                                let snap = snapShot.childSnapshot(forPath: firUser.uid)
                                let snapVal = snap.value as? [String: Any]
                                
                                let userProf = User(userData: firUser, snapShot: snap, picURL: profPic, nameFromProvider: profile.displayName)
                                appDelegate.signedInUser = userProf
                                
                                if let url = snapVal?["photoPath"] as? String {
                                    print("found URL")
                                    
                                    
                                    if url != profPic {
                                        print("url's are not the same")
                                        appDelegate.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                    } else {
                                        
                                        let thisProfPicStoreRef = profPicStorRef.child(firUser.uid)
                                        
                                        thisProfPicStoreRef.data(withMaxSize: 5 * 1024 * 1024, completion: { (data, error) in
                                            print("finished grabbing data from storage...")
                                            
                                            if let error = error {
                                                print(error.localizedDescription)
                                            }
                                            
                                            if error == nil, data != nil {
                                                print("retrieved image data")
                                                appDelegate.signedInProfileImage = UIImage(data: data!)
                                            }
                                        })
                                    }
                                    
                                    thisUserDBRef.setValue(userProf.toAny())
                                }
                            } else {
                                let userProf = User(uid: firUser.uid, name: profile.displayName!, photoPath: profPic)
                                appDelegate.signedInUser = userProf
                                appDelegate.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                thisUserDBRef.setValue(userProf.toAny())
                            }
                            
                        })
                        
                    }
                    
                }
            })

        } else {
            
            loginManager.logIn([.publicProfile], viewController: self) { (result: LoginResult) in
                
                switch result {
                case .failed(let error):
                    print(error.localizedDescription)
                case .cancelled:
                    print("cancelled")
                case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                    
                    print(grantedPermissions)
                    print(declinedPermissions)
                    print(accessToken)
                    
                    activityIndicator.center = self.wordsmithPortalButton.center
                    self.view.addSubview(activityIndicator)
                    activityIndicator.startAnimating()
                    
                    if let token = AccessToken.current {
                        let credential = FIRFacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
                        FIRAuth.auth()?.signIn(with: credential, completion: { (user:FIRUser?, error:Error?) in
                            activityIndicator.stopAnimating()
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                            
                            self.resizeAndMoveLogInButton(button: sender, type: .facebook, signingIn: true)
                            
                            if let firUser = user {
                                
                                let thisUserDBRef = self.userDBRef.child(firUser.uid)
                                let profPicStorRef = FIRStorage.storage().reference().child("profilePics")
                                
                                for profile in firUser.providerData {
                                    
                                    let profPic = profile.photoURL!
                                    let userProf = User(uid: firUser.uid, name: profile.displayName!, photoPath: String(describing: profile.photoURL!))
                                    appDelegate.signedInUser = userProf
                                    
                                    self.userDBRef.observeSingleEvent(of: .value, with: { (snapShot) in
                                        
                                        if snapShot.hasChild(firUser.uid) {
                                            let snapVal = snapShot.childSnapshot(forPath: firUser.uid).value as? [String: Any]
                                            print("observing user database...")
                                            
                                            if let url = snapVal?["photoPath"] as? String {
                                                print("found URL")
                                                
                                                let providerURL = String(describing:profPic)
                                                
                                                if url != providerURL {
                                                    print("url's are not the same")
                                                    appDelegate.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                                } else {
                                                    
                                                    let thisProfPicStoreRef = profPicStorRef.child(firUser.uid)
                                                    
                                                    thisProfPicStoreRef.data(withMaxSize: 5 * 1024 * 1024, completion: { (data, error) in
                                                        print("finished grabbing data from storage...")
                                                        
                                                        if let error = error {
                                                            print(error.localizedDescription)
                                                        }
                                                        
                                                        if error == nil, data != nil {
                                                            print("retrieved image data")
                                                            appDelegate.signedInProfileImage = UIImage(data: data!)
                                                        }
                                                    })
                                                }
                                                
                                                thisUserDBRef.setValue(userProf.toAny())
                                            }
                                        } else {
                                            appDelegate.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                            thisUserDBRef.setValue(userProf.toAny())
                                        }
                                        
                                    })
                                    
                                }
                            }
                            
                            
                            
                        })
                    } else {
                        activityIndicator.stopAnimating()
                        print("No access token could be found...")
                    }
                }
                
            }
        }
        
        
    }
    @IBAction func logInWithGoogleButtonTapped(_ sender: UIButton) {
        if isSignedIn {
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                GIDSignIn.sharedInstance().signOut()
                self.resizeAndMoveLogInButton(button: logInWithGoogleButton, type: .google, signingIn: false)
                print("signed out of firebase")
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
           GIDSignIn.sharedInstance().signIn()
        }
    }
    @IBAction func wordsmithPortalButtonTapped(_ sender: MenuButton) {
        
        portalLabel.font = UIFont(name: "GillSans-BoldItalic", size: 45)
        
        portalLabel.text = "Entering the Wordsmith Portal"
        
        self.view.addSubview(portalLabel)
        
        UIView.animate(withDuration: 1.5, animations: { 
            self.portalLabel.alpha = 1
        }) { (_) in
            self.performSegue(withIdentifier: "chooseGenreSegue", sender: self)
        }
        
        
    }
    @IBAction func producerPortalButtonTapped(_ sender: MenuButton) {
    }
    
    func createMusicNoteParticles() {
        
        particleEmitter.emitterPosition = CGPoint(x: view.frame.width + 50, y: view.frame.height / 2)
        particleEmitter.emitterShape = kCAEmitterLayerCuboid
        particleEmitter.emitterSize = CGSize(width: 1, height: view.frame.height)
        particleEmitter.emitterDepth = 50
        particleEmitter.zPosition = -1
        particleEmitter.renderMode = kCAEmitterLayerAdditive
        
        let cell = CAEmitterCell()
        cell.birthRate = 15
        cell.lifetime = 17.75
        cell.velocity = 100
        cell.velocityRange = 50
        cell.emissionLongitude = -CGFloat.pi
        cell.spinRange = 0.78
        cell.scale = 0.05
        cell.scaleRange = 0.1
        cell.alphaSpeed = -0.1
        cell.contents = UIImage(named: "noteSprite")?.cgImage
        
        particleEmitter.emitterCells = [cell]
        
        
        let label = CATextLayer()
        label.alignmentMode = kCAAlignmentCenter
        label.string = "TEST"
        label.frame = CGRect(x: 50, y: 50, width: 400, height: 100)
        label.zPosition = -60
        
        //TODO: Add label in between particle emitter cells and display the cell...
        
        gradient.addSublayer(particleEmitter)
        
        
    }
    
    func resizeAndMoveLogInButton(button: UIButton, type: SignInButtonType, signingIn dirIn: Bool) {
        
        var otherButtonAlpha = CGFloat()
        var thisButtonTitle = String()
        var mainButtonTransform = CGAffineTransform()
        var mainButtonAlpha = CGFloat()
        var mainDelay: Double = 0.0
        var logDelay: Double = 0.0
        
        if dirIn {
            otherButtonAlpha = 0
            thisButtonTitle = "Sign Out"
            mainButtonTransform = CGAffineTransform.identity
            mainButtonAlpha = 1
            mainDelay = 0.5
        } else {
            otherButtonAlpha = 1
            mainButtonTransform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
            mainButtonAlpha = 0
            logDelay = 0.5
        }
        
        if type == .facebook {
            
            if dirIn {
                self.logInButtonCenterXAlignment.constant = -self.view.bounds.width / 2 + button.bounds.width / 4 + 15
                self.logInButtonCenterYAlignment.constant = -self.view.bounds.height / 2 + button.bounds.height / 2 + 20
                self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant / 2
            } else {
                thisButtonTitle = "Sign In With Facebook"
                self.logInButtonCenterXAlignment.constant = self.facebookOrigXConst
                self.logInButtonCenterYAlignment.constant = self.facebookOrigYConst
                self.logInButtonWidthConstraint.constant = logInButtonWidthConstraint.constant * 2
            }
        }
        
        if type == .google {
            
            if dirIn {
                self.googleButtonCenterXAlignment.constant = -self.view.bounds.width / 2 + button.bounds.width / 4 + 15
                self.googleButtonCenterYAlignment.constant = -self.view.bounds.height / 2 + button.bounds.height / 2 + 20
                self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant / 2
            } else {
                thisButtonTitle = "Sign In With Google"
                self.googleButtonCenterXAlignment.constant = self.googleOrigXConst
                self.googleButtonCenterYAlignment.constant = self.googleOrigYConst
                self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant * 2
            }
            
        }
        
        UIView.animate(withDuration: 0.4, delay: mainDelay, usingSpringWithDamping: 0.3, initialSpringVelocity: 6, options: .curveEaseInOut, animations: {
            self.producerPortalButton.alpha = mainButtonAlpha
            self.wordsmithPortalButton.alpha = mainButtonAlpha
            self.producerPortalButton.transform = mainButtonTransform
            self.wordsmithPortalButton.transform = mainButtonTransform
        }, completion: nil)
        
        UIView.animateKeyframes(withDuration: 0.5, delay: logDelay, options: .calculationModeCubicPaced, animations: {
            
            self.view.layoutIfNeeded()
            
            var otherButton = UIButton()
            
            if type == .facebook {
                otherButton = self.logInWithGoogleButton
            }
            if type == .google {
                otherButton = self.logInWithFacebookButton
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1, animations: { 
                otherButton.alpha = otherButtonAlpha
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 0
            })
            
        }, completion: {
            (_) in
            button.layoutIfNeeded()
            button.setTitle(thisButtonTitle, for: .normal)
            
            self.isSignedIn = dirIn
            button.isEnabled = true
            
            UIView.animate(withDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 1
            })
            
        })
 
    }
}
