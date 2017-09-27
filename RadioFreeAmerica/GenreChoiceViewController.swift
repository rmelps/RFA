//
//  GenreChoiceViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class GenreChoiceViewController: UIViewController {
    
    // Background Color Gradient
    var gradient: CAGradientLayer!
    var gradientColor: CGColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradient.colors?[gradient.colors!.endIndex - 1] = gradientColor
        self.view.layer.insertSublayer(gradient, at: 0)

        
    }

}
