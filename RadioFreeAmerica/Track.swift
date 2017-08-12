//
//  Track.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Track {
    var user: String
    var title: String
    var uploadTime: String
    var fileURL: String
    var fadeInTime: String
    var fadeOutTime: String
    let errorMessage = "Error"
    
    init(user: String, title: String, uploadTime: String, fileURL: String, fadeInTime: String, fadeOutTime: String){
        self.user = user
        self.title = title
        self.uploadTime = uploadTime
        self.fileURL = fileURL
        self.fadeInTime = fadeInTime
        self.fadeOutTime = fadeOutTime
    }
    
    init(snapShot: FIRDataSnapshot) {
        
        let snapShotValue = snapShot.value as? [String:Any]
        
        if let user = snapShotValue?["user"] as? String {
            self.user = user
        } else {
            self.user = errorMessage
        }
        
        if let title = snapShotValue?["title"] as? String {
            self.title = title
        } else {
            self.title = errorMessage
        }
        
        if let uploadTime = snapShotValue?["uploadTime"] as? String {
            self.uploadTime = uploadTime
        } else {
            self.uploadTime = errorMessage
        }
        
        if let fileURL = snapShotValue?["fileURL"] as? String {
            self.fileURL = fileURL
        } else {
            self.fileURL = errorMessage
        }
        
        if let fadeInTime = snapShotValue?["fadeInTime"] as? String {
            self.fadeInTime = fadeInTime
        } else {
            self.fadeInTime = errorMessage
        }
        
        if let fadeOutTime = snapShotValue?["fadeOutTime"] as? String {
            self.fadeOutTime = fadeOutTime
        } else {
            self.fadeOutTime = errorMessage
        }
    }
    
    func toAny() -> Any {
        return ["user": self.user, "title": self.title, "uploadTime": self.uploadTime, "fileURL": self.fileURL, "fadeInTime": self.fadeInTime, "fadeOutTime":self.fadeOutTime]
    }
    
}
