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
    var stars: Stat!
    var knowledge: Stat!
    var crowns: Stat!
    var downloads: Stat!
    let itemRef: FIRDatabaseReference?
    
    init(userData: FIRUser, snapShot: FIRDataSnapshot, picURL: String) {
        
        uid = userData.uid
        photoPath = picURL
        
        itemRef = snapShot.ref
        
        let snapShotValue = snapShot.value as? [String: AnyObject]
        
        if let name = snapShotValue?["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        
        if let stars = snapShotValue?["stars"] as? Int {
            self.stars = Stat(description: "Stars", value: stars)
        } else {
            self.stars = Stat(description: "Stars", value: 0)
        }
        
        if let knowledge = snapShotValue?["knowledge"] as? Int {
            self.knowledge = Stat(description: "Knowledge", value: knowledge)
        } else {
            self.knowledge = Stat(description: "Knowledge", value: 0)
        }
        
        if let crowns = snapShotValue?["crowns"] as? Int {
            self.crowns = Stat(description: "Crowns", value: crowns)
        } else {
            self.crowns = Stat(description: "Crowns", value: 0)
        }
        
        if let downloads = snapShotValue?["downloads"] as? Int {
            self.downloads = Stat(description: "Downloads", value: downloads)
        } else {
            self.downloads = Stat(description: "Downloads", value: 0)
        }
    }
    
    init(userData: FIRUser) {
        uid = userData.uid
        name = userData.displayName
        itemRef = nil
        
        self.knowledge = Stat(description: "Knowledge", value: 0)
        self.stars = Stat(description: "Stars", value: 0)
        self.crowns = Stat(description: "Crowns", value: 0)
        self.downloads = Stat(description: "Downloads", value: 0)
        
        if let photoPath = userData.photoURL {
            self.photoPath = String(describing: photoPath)
        }
        
    }
    
    init(uid: String, name: String, photoPath: String?) {
        self.uid = uid
        self.name = name
        itemRef = nil
        
        self.knowledge = Stat(description: "Knowledge", value: 0)
        self.stars = Stat(description: "Stars", value: 0)
        self.crowns = Stat(description: "Crowns", value: 0)
        self.downloads = Stat(description: "Downloads", value: 0)
        
        if let photoPath = photoPath {
            self.photoPath = photoPath
        }
    }
    
    func toAny() -> Any {
        
        return ["uid":uid, "name":name, "photoPath": photoPath!, "knowledge": knowledge.value, "stars": stars.value, "crowns": crowns.value, "downloads": downloads.value]
    }
}
