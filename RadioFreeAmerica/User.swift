//
//  User.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

struct User {
    var uid: String!
    var name: String!
    var photoPath: String?
    let itemRef: FIRDatabaseReference?
    
    init(userData: FIRUser, snapShot: FIRDataSnapshot) {
        
        uid = userData.uid
        
        itemRef = snapShot.ref
        
        let snapShotValue = snapShot.value as? [String: AnyObject]
        
        if let name = snapShotValue?["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        
        if let photoPath = snapShotValue?["photoPath"] as? String {
            self.photoPath = photoPath
        } else {
            self.photoPath = nil
        }
    }
    
    init(userData: FIRUser) {
        uid = userData.uid
        name = userData.displayName
        itemRef = nil
        
        if let photoPath = userData.photoURL {
            self.photoPath = String(describing: photoPath)
        }
        
    }
    
    init(uid: String, name: String, photoPath: String?) {
        self.uid = uid
        self.name = name
        itemRef = nil
        
        if let photoPath = photoPath {
            self.photoPath = photoPath
        }
    }
    
    func toAny() -> Any {
        
        return ["uid":uid, "name":name, "photoPath": photoPath]
    }
}
