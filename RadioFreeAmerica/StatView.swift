//
//  StatView.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/3/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class StatView: UIView {
    
    @IBOutlet weak var statLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    
    class func instantiateFromNib() -> StatView {
        return UINib(nibName: "StatView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! StatView
    }
}
