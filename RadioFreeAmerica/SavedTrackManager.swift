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
                print("Could not unarchive tracks...")
                return [Track]()
            }
        }
    }
    
    static func getLocalURL(forTrack track: Track) -> URL {
        return trackArchiveAudioDirectoryURL.appendingPathComponent(track.fileURL)
    }
    
    static func saveNewTrack(newTrack track: Track, tempLocation: URL) -> Bool {
        var archivedTracks = [Track]()
        
        if let savedTracks = NSKeyedUnarchiver.unarchiveObject(withFile: trackArchiveInfoURL.path) as? [Track] {
            archivedTracks = savedTracks
        } else {
            print("Could not unarchive tracks...")
        }
        archivedTracks.append(track)
        
        let infoSuccess = NSKeyedArchiver.archiveRootObject(archivedTracks, toFile: trackArchiveInfoURL.path)

        if infoSuccess {
            print("successfully archived track info")
            do {
                let fileManager = FileManager.default
                try fileManager.createDirectory(atPath: trackArchiveAudioDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
                let data = try Data(contentsOf: tempLocation)
                let appendingURL = trackArchiveAudioDirectoryURL.appendingPathComponent(track.fileURL)
                
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
    
    static func removeTrack(atIndex index: Int) -> Bool {
        var tracks = self.savedTracks
        let track = self.savedTracks[index]
        
        tracks.remove(at: index)
        
        let infoSuccess = NSKeyedArchiver.archiveRootObject(tracks, toFile: trackArchiveInfoURL.path)
        
        if infoSuccess {
            do {
                let storageURL = trackArchiveAudioDirectoryURL.appendingPathComponent(track.fileURL)
                let fileManager = FileManager.default
                try fileManager.removeItem(at: storageURL)
                return true
            } catch {
                print("could not remove track from storage: \(error.localizedDescription)")
                return false
            }
        } else {
            print("Could not archive track info")
            return false
        }
    }
}
