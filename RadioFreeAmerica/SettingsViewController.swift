//
//  SettingsViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/9/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class SettingsViewController: UIViewController {
    // View containers
    @IBOutlet weak var fullContentView: UIView!
    @IBOutlet weak var profileSettingsView: UIView!
    @IBOutlet weak var localSettingsView: UIView!
    
    // Profile Settings stack view contents
    @IBOutlet weak var profileSettingsStackView: UIStackView!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var changePictureButton: UIButton!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var taglineTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    
    weak var profileImage: UIImage!
    var userName: String!
    var tag: String!
    var bio: String!
    var user: User!
    
    // Local Settings stack view contents
    @IBOutlet weak var localSettingsStackView: UIStackView!
    @IBOutlet weak var localLabel: UILabel!
    @IBOutlet weak var flagsSwitch: UISwitch!
    @IBOutlet weak var thresholdStackView: UIStackView!
    @IBOutlet weak var thresholdStepper: UIStepper!
    @IBOutlet weak var thresholdNumberLabel: UILabel!
    
    @IBOutlet weak var profPicWidthCon: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check the current system settings
        if let settings = Settings.currentSettings {
            // Configure all fields reliant upon current settings
            flagsSwitch.isOn = settings.isBlocking
            thresholdStepper.value = Double(settings.flagThresh)
            thresholdNumberLabel.text = String(thresholdStepper.value)
        } else {
            print("User has not configured settings")
        }
        
        
        profPicWidthCon.constant = profileSettingsStackView.bounds.width / 3
        
        //Configure profile settings with existing fields
        profilePictureImageView.image = profileImage
        userNameTextField.placeholder = userName
        taglineTextField.placeholder = tag
        bioTextView.text = bio
        
        //Fit views to stackviews
        profileSettingsView.frame = profileSettingsStackView.frame
        localSettingsView.frame = localSettingsStackView.frame
        profileSettingsView.clipsToBounds = true
        localSettingsView.clipsToBounds = true
        
        // Gradient Layer to Apply to section headings
        let labels = [profileLabel, localLabel]
        
        for label in labels {
            label!.backgroundColor = .clear
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [UIColor.white.cgColor, UIColor.gray.cgColor]
            gradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
            gradientLayer.frame = label!.bounds
            gradientLayer.masksToBounds = true
            label!.superview?.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        // Determine if threshold Stack View should be displayed
        if flagsSwitch.isOn {
            thresholdStackView.isHidden = false
        } else {
            thresholdStackView.isHidden = true
        }
    }
    
    //MARK: - View actions
    
    @IBAction func changePictureButtonDidTapUp(_ sender: UIButton) {
        
    }
    @IBAction func flagSwitchDidChangeValue(_ sender: UISwitch) {
        if flagsSwitch.isOn {
            thresholdStackView.isHidden = false
        } else {
            thresholdStackView.isHidden = true
        }
    }
    @IBAction func thresholdStepperDidChangeValue(_ sender: UIStepper) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        let number = NSNumber(value: sender.value)
        let string = formatter.string(from: number)
        thresholdNumberLabel.text = string
    }
    
    //MARK: - Bar button actions
    
    @IBAction func cancelBarButtonTapped(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneBarButtonTapped(_ sender: UIBarButtonItem) {
        var newName = self.userName!
        let newBio = self.bioTextView.text!
        var newTag = self.tag!
        let newImage = self.profileImage!
        
        // Verify basic user name config before submitting changes, then update newName if passes. Else, leave new name as current username
        if let text = userNameTextField.text, !text.isEmpty {
            guard Set(text.characters).count > 1 else {
                AppDelegate.presentErrorAlert(withMessage: "You must enter a valid user name!", fromViewController: self)
                return
            }
            newName = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let text = taglineTextField.text, !text.isEmpty {
            newTag = text
        }
        
        AppDelegate.nameDBRef.observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
            
            // Ensure that no one has already claimed this userName
            let value = snapshot.value as? [String: String]
            let claimedUID = value?[newName]
            
            if let claimed = claimedUID, claimed != self.user.uid {
                AppDelegate.presentErrorAlert(withMessage: "This user name is already taken!", fromViewController: self)
                return
            }
            // Update the names dictionary first
            AppDelegate.nameDBRef.updateChildValues([newName: self.user.uid] as [AnyHashable : Any])
            AppDelegate.nameDBRef.updateChildValues([self.user.name: nil] as [AnyHashable : Any?])
            
            
            // Now update the profile picture, if neccesary.
            self.updateProfilePicture(withImage: newImage, compressionRatio: 0.65, completion: { (error: Error?) in
                if let error = error {
                    AppDelegate.presentErrorAlert(withMessage: "There was an error updating the profile picture: \(error.localizedDescription)", fromViewController: self)
                    return
                }
                // Finally, update the user profile
                AppDelegate.userDBRef.child(self.user.uid).observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
                    if var value = snapshot.value as? [String: Any] {
                        value["name"] = newName
                        value["tagLine"] = newTag
                        value["biography"] = newBio
                        
                        AppDelegate.userDBRef.child(self.user.uid).setValue(value as Any)
                        let appDel = UIApplication.shared.delegate as! AppDelegate
                        if let firUser = FIRAuth.auth()?.currentUser {
                            appDel.signedInUser = User(userData: firUser, snapShot: snapshot, picURL: value["photoUrl"] as? String, nameFromProvider: nil)
                        }
                        self.dismiss(animated: true, completion: nil)
                    }
                })
                
            })

        })
        
        // Set Local Settings Values
        let settings = Settings(blocking: flagsSwitch.isOn, threshold: Int(thresholdStepper.value))
        settings.updateToCurrentSettings()
        self.view.endEditing(true)
    }
    
    func updateProfilePicture(withImage image: UIImage, compressionRatio comp: CGFloat, completion: @escaping ((Error?) -> Void)) {
        
        guard let profPic = profilePictureImageView.image, image != profPic else {
            // existing profile pic and the profile pic chosen are the same, do not update picture
            print("pictures are the same")
            completion(nil)
            return
        }
        
        if let data = UIImageJPEGRepresentation(image, comp) {
            AppDelegate.profPicStorRef.child(user.uid).put(data, metadata: nil) { (meta: FIRStorageMetadata?, error: Error?) in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    

}
