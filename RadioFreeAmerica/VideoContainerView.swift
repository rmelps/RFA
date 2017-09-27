//
//  VideoContainerView.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/23/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class VideoContainerView: UIView {
    
    var playerLayer: CALayer?

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        playerLayer?.frame = self.bounds
    }

}
