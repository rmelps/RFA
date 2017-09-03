//
//  Track.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Track: NSObject, NSCoding {
    var user: String
    var title: String
    var stars: [String]
    var downloads: [String]
    var flags: [String]
    var details: String
    var uploadTime: String
    var fileURL: String
    var fadeInTime: String
    var fadeOutTime: String
    let errorMessage = "Error"
    var key: String?
    
    init(user: String, title: String, details: String, uploadTime: String, fileURL: String, fadeInTime: String, fadeOutTime: String){
        self.user = user
        self.title = title
        self.details = details
        self.uploadTime = uploadTime
        self.fileURL = fileURL
        self.fadeInTime = fadeInTime
        self.fadeOutTime = fadeOutTime
        self.key = nil
        self.stars = []
        self.downloads = []
        self.flags = []
    }
    
    init(snapShot: FIRDataSnapshot) {
        
        self.key = snapShot.key
        
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
        
        if let details = snapShotValue?["details"] as? String {
            self.details = details
        } else {
            self.details = errorMessage
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
        
        if let stars = snapShotValue?["stars"] as? [String] {
            self.stars = stars
        } else {
            self.stars = []
        }
        
        if let downloads = snapShotValue?["downloads"] as? [String] {
            self.downloads = downloads
        } else {
            self.downloads = []
        }
        
        if let flags = snapShotValue?["flags"] as? [String] {
            self.flags = flags
        } else {
            self.flags = []
        }
        
    }
    
    func toAny() -> Any {
        return ["user": self.user, "title": self.title, "stars": self.stars, "downloads": self.downloads, "flags": self.flags, "details": self.details, "uploadTime": self.uploadTime, "fileURL": self.fileURL, "fadeInTime": self.fadeInTime, "fadeOutTime":self.fadeOutTime]
    }
    
    //MARK: NSCoding
    
    required init(coder aDecoder: NSCoder) {
        user = aDecoder.decodeObject(forKey: "user") as! String
        title = aDecoder.decodeObject(forKey: "title") as! String
        details = aDecoder.decodeObject(forKey: "details") as! String
        uploadTime = aDecoder.decodeObject(forKey: "uploadTime") as! String
        fileURL = aDecoder.decodeObject(forKey: "fileURL") as! String
        fadeInTime = aDecoder.decodeObject(forKey: "fadeInTime") as! String
        fadeOutTime = aDecoder.decodeObject(forKey: "fadeOutTime") as! String
        key = aDecoder.decodeObject(forKey: "key") as! String?
        
        self.stars = []
        self.downloads = []
        self.flags = []
        
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(user, forKey: "user")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(details, forKey: "details")
        aCoder.encode(uploadTime, forKey: "uploadTime")
        aCoder.encode(fileURL, forKey: "fileURL")
        aCoder.encode(fadeInTime, forKey: "fadeInTime")
        aCoder.encode(fadeOutTime, forKey: "fadeOutTime")
        aCoder.encode(key, forKey: "key")
    }
    
}
