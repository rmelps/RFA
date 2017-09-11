//
//  SettingsViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/9/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

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
    }
    @IBAction func doneBarButtonTapped(_ sender: UIBarButtonItem) {
    }
    

}
