//
//  StudioTextFieldDelegate.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/7/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import UIKit

class StudioTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // If string is too long or entered character is not a backspace, then add the string
        if let text = textField.text, text.characters.count > 20, string.utf8CString[0] != 0 {
            return false
        }
        
        return true
    }
}
