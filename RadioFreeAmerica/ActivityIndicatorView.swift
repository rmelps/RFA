//
//  ActivityIndicatorView.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/23/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class ActivityIndicatorView: UIView {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var progressLabel: UILabel?
    
    init(withProgress: Bool) {
        super.init(frame: CGRect.zero)
        configure(withProgress: withProgress)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    private func configure(withProgress: Bool) {
        self.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: activityIndicator.bounds.width * 2.5, height: activityIndicator.bounds.height * 2.5))
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        self.layer.cornerRadius = 7.0
        self.addSubview(activityIndicator)
        
        // Configure progress
        if withProgress {
            let size = CGSize(width: self.bounds.width, height: self.bounds.height / 6)
            let frame = CGRect(origin: CGPoint.zero, size: size)
            progressLabel = UILabel(frame: frame)
            progressLabel!.textAlignment = .center
            progressLabel!.font = UIFont(name: "AppleSDGothicNeo-Thin", size: 15.0)
            progressLabel!.textColor = .white
            progressLabel!.adjustsFontSizeToFitWidth = true
            progressLabel!.minimumScaleFactor = 0.5
            progressLabel!.text = "0.0 %"
            self.addSubview(progressLabel!)
        }
        
        
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let view = newSuperview {
            activityIndicator.center = self.center
            self.center = view.center
            activityIndicator.startAnimating()
            if progressLabel != nil {
                progressLabel!.frame.origin = CGPoint(x: 0.0, y: self.bounds.height - progressLabel!.frame.height)
            }
        }
    }
}
