//
//  MenuButton.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/16/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

@IBDesignable class MenuButton: UIButton {
    
    @IBInspectable var buttonColor = UIColor.blue {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath(ovalIn: rect)
        buttonColor.setFill()
        path.fill()
    }
 

}
