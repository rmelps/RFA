//
//  ViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import FacebookCore

class ViewController: UIViewController {
    
    @IBOutlet weak var logInButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var logInWithFacebookButton: UIButton!
    @IBOutlet weak var logInButtonCenterXAlignment: NSLayoutConstraint!
    @IBOutlet weak var logInButtonCenterYAlignment: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logInWithFacebookButton.layer.cornerRadius = 3.0
        logInWithFacebookButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        /*
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email, .userFriends])
        loginButton.delegate = self
        
        loginButton.center = view.center
        
        view.addSubview(loginButton)
        */
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
                            self.resizeAndMoveLogInButton(button: sender)
                            
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
    
    func resizeAndMoveLogInButton(button: UIButton) {
        
        self.logInButtonCenterXAlignment.constant = -self.view.bounds.width / 2 + button.bounds.width / 4 + 15
        self.logInButtonCenterYAlignment.constant = -self.view.bounds.height / 2 + button.bounds.height / 2 + 20
        self.logInButtonWidthConstraint.constant = self.logInButtonWidthConstraint.constant / 2
        
        UIView.animateKeyframes(withDuration: 0.8, delay: 0.0, options: .calculationModeCubicPaced, animations: {
            
            self.view.layoutIfNeeded()
             
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3, animations: { 
                button.titleLabel?.alpha = 0
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
/*
extension ViewController: LoginButtonDelegate {
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
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
                        self.resizeAndMoveLogInButton(button: loginButton)
                        
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
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("logged out")
    }
}
*/

