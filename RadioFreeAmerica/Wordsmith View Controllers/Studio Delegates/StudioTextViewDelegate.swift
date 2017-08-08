//
//  StudioTextViewDelegate.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/7/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import UIKit

class StudioTextViewDelegate: NSObject, UITextViewDelegate {
   
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print(textView.text.count)
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        if textView.text.count > 300 {
            return false
        }
        
        return true
    }
}
