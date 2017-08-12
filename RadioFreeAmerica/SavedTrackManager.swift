//
//  SavedTrackManager.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import Foundation
import AVFoundation

class SavedTrackManager {
    
    static let trackArchiveInfoURL: URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        
        return documentDirectory.appendingPathComponent("tracks.archive")
    }()
    
    static let trackArchiveAudioDirectoryURL: URL = {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        
        return documentDirectory.appendingPathComponent("tracks.audio")
    }()
    
    static var savedTracks: [Track] {
        get {
            if let archivedTracks = NSKeyedUnarchiver.unarchiveObject(withFile: trackArchiveInfoURL.path) as? [Track] {
                return archivedTracks
            } else {
                return [Track]()
            }
        }
        set {
            print("New Track Saved, Total Tracks:\(savedTracks.count)")
        }
    }
    
    static func saveNewTrack(newTrack track: Track) -> Bool {
        savedTracks.append(track)
        
        let infoSuccess = NSKeyedArchiver.archiveRootObject(savedTracks, toFile: trackArchiveInfoURL.path)
        
        if infoSuccess {
            print("successfully archived track info")
            do {
                let fileManager = FileManager.default
                try fileManager.createDirectory(atPath: trackArchiveAudioDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
                let data = try Data(contentsOf: URL(fileURLWithPath: track.fileURL))
                let appendingURL = trackArchiveAudioDirectoryURL.appendingPathComponent("\(track.title)\(track.user)")
                return FileManager.default.createFile(atPath: appendingURL.path, contents: data, attributes: nil)
            } catch {
                print("could not obtain data at path: \(error.localizedDescription)")
                return false
            }
        } else {
            print("could not archive track info")
            return false
        }
    }
}
