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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        let gradientColor = UIColor(red: 79/255, green: 199/255, blue: 113/255, alpha: 1.0).cgColor
        
        gradient.frame = self.view.bounds
        gradient.colors = [UIColor.white.cgColor, gradientColor]
        
        self.view.layer.insertSublayer(gradient, at: 0)
        
        createMusicNoteParticles()
        
        logInWithFacebookButton.layer.cornerRadius = 3.0
        //logInWithFacebookButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        logInWithGoogleButton.layer.cornerRadius = 3.0
        //logInWithGoogleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
    }

    @IBAction func loginWithFacebookButtonTapped(_ sender: UIButton) {
        let loginManager = LoginManager()
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
                            self.resizeAndMoveLogInButton(button: sender, type: .facebook)
                            
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
    @IBAction func logInWithGoogleButtonTapped(_ sender: UIButton) {
        if isSignedIn {
            GIDSignIn.sharedInstance().signOut()
            isSignedIn = false
            let firebaseAuth = FIRAuth.auth()
            
            do {
                try firebaseAuth?.signOut()
                print("signed out of firebase")
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
           GIDSignIn.sharedInstance().signIn()
            isSignedIn = true
        }
    }
    
    func createMusicNoteParticles() {
        
        particleEmitter.emitterPosition = CGPoint(x: view.frame.width + 50, y: view.frame.height / 2)
        particleEmitter.emitterShape = kCAEmitterLayerRectangle
        particleEmitter.emitterSize = CGSize(width: 1, height: view.frame.height)
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
        
        gradient.addSublayer(particleEmitter)
        
    }
    
    func resizeAndMoveLogInButton(button: UIButton, type: SignInButtonType) {
        
        if type == .facebook {
            
            self.logInButtonCenterXAlignment.constant = -self.view.bounds.width / 2 + button.bounds.width / 4 + 15
            self.logInButtonCenterYAlignment.constant = -self.view.bounds.height / 2 + button.bounds.height / 2 + 20
            self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant / 2
        }
        
        if type == .google {
            
            self.googleButtonCenterXAlignment.constant = -self.view.bounds.width / 2 + button.bounds.width / 4 + 15
            self.googleButtonCenterYAlignment.constant = -self.view.bounds.height / 2 + button.bounds.height / 2 + 20
            self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant / 2
        }
        
        UIView.animateKeyframes(withDuration: 0.8, delay: 0.0, options: .calculationModeCubicPaced, animations: {
            
            self.view.layoutIfNeeded()
            
            var otherButton = UIButton()
            
            if type == .facebook {
                otherButton = self.logInWithGoogleButton
            }
            if type == .google {
                otherButton = self.logInWithFacebookButton
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.1, animations: { 
                otherButton.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.0, animations: { 
                button.setTitle("Log Out", for: .normal)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.3, animations: {
                button.titleLabel?.alpha = 1
            })
            
        }, completion: {
            (_) in
            button.layoutIfNeeded()
            button.setTitle("Log Out", for: .normal)
            
            
            UIView.animate(withDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 1
            })
            
        })
 
    }
}
