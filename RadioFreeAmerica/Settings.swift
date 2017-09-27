//
//  Settings.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation

class Settings: NSObject, NSCoding {
    
    static let settingsArchiveURL: URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        
        return documentDirectory.appendingPathComponent("user-settings")
    }()
    static var currentSettings: Settings? {
        get {
            if let settings = NSKeyedUnarchiver.unarchiveObject(withFile: settingsArchiveURL.path) as? Settings {
                return settings
            } else {
                print(NSKeyedUnarchiver.unarchiveObject(withFile: settingsArchiveURL.path).debugDescription)
                return nil
            }
        }
    }
    
    var isBlocking: Bool
    var flagThresh: Int
    
    override convenience init(){
        self.init()
        isBlocking = false
        flagThresh = 1
    }
    
    init(blocking block: Bool, threshold thresh: Int){
        self.isBlocking = block
        
        if thresh > 50 {
            self.flagThresh = 50
        } else if thresh < 1 {
            self.flagThresh = 1
        } else {
            self.flagThresh = thresh
        }
    }
    
    func updateToCurrentSettings(){
        let success = NSKeyedArchiver.archiveRootObject(self, toFile: Settings.settingsArchiveURL.path)
            
        if success {
            print("successfully saved settings!")
        } else {
            print("Error saving settings")
        }
    }
    
    
    //MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(isBlocking, forKey: "isBlocking")
        aCoder.encode(flagThresh, forKey: "flagThresh")
    }
    
    required init?(coder aDecoder: NSCoder) {
        isBlocking = aDecoder.decodeBool(forKey: "isBlocking")
        flagThresh = aDecoder.decodeInteger(forKey: "flagThresh")
    }
    
}
