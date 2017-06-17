//
//  MainViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import FacebookCore
import GoogleSignIn

enum SignInButtonType {
    case google
    case facebook
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

    @IBAction func loginWithFacebookButtonTapped(_ sender: UIButton) {
        
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
            
        } else {
            loginManager.logIn([.publicProfile], viewController: self) { (result: LoginResult) in
                
                switch result {
                case .failed(let error):
                    print(error.localizedDescription)
                case .cancelled:
                    print("cancelled")
                default:
                    if let token = AccessToken.current {
                        let credential = FIRFacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
                        FIRAuth.auth()?.signIn(with: credential, completion: { (user:FIRUser?, error:Error?) in
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                self.resizeAndMoveLogInButton(button: sender, type: .facebook, signingIn: true)
                                
                                for profile in user!.providerData {
                                    let photoUrl = profile.photoURL?.absoluteString
                                    print(photoUrl ?? "no photoURL")
                                }
                            }
                        })
                    } else {
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
        
        if dirIn {
            otherButtonAlpha = 0
            thisButtonTitle = "Sign Out"
            mainButtonTransform = CGAffineTransform.identity
            mainButtonAlpha = 1
        } else {
            otherButtonAlpha = 1
            mainButtonTransform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
            mainButtonAlpha = 0
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
        
        
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .calculationModeCubicPaced, animations: {
            
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
            
            UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.3, initialSpringVelocity: 6, options: .curveEaseInOut, animations: {
                self.producerPortalButton.alpha = mainButtonAlpha
                self.wordsmithPortalButton.alpha = mainButtonAlpha
                self.producerPortalButton.transform = mainButtonTransform
                self.wordsmithPortalButton.transform = mainButtonTransform
            }, completion: nil)
            
            self.isSignedIn = dirIn
            
            UIView.animate(withDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 1
            })
            
        })
 
    }
}
