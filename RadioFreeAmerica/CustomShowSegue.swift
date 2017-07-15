//
//  CustomShowSegue.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class CustomShowSegue: UIStoryboardSegue {
    /*
    var fromBottom: Bool!
    
    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
        
        if destination is StudioViewController {
            fromBottom = true
        } else {
            fromBottom = false
        }
    }
 */

    
    override func perform() {
        let source = self.source
        let destination = self.destination
        
        source.view!.superview!.insertSubview(destination.view, aboveSubview: source.view!)
        
        /*
        if fromBottom {
            destination.view.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        } else {
            destination.view.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        }
 */
 
        destination.view.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut, animations: {
            destination.view.transform = CGAffineTransform.identity
        }) { (_) in
            source.present(destination, animated: false, completion: nil)
        }
        
    }
}
