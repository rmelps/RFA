//
//  FireAudioManager.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

enum TrackError: Error {
    case notAvailable
}

extension TrackError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return NSLocalizedString("This track is no longer available", comment: "removed from Firebase Database")
        }
    }
}

struct FireAudioManager {
    static var quickLoadFiles = [(key:String, file: AVAudioFile)]()
    //static var audioPlayer = AVAudioPlayer()
    
    static func modifyPostStat(statName name: String, increase: Bool, forTrack track: Track, inGenre genre: GenreChoices) {
        
        guard let key = track.key else {
            print("Could not find key for track")
            return
        }
        let feedDBRef = FIRDatabase.database().reference().child("feed/\(genre.rawValue.lowercased())")
        let ref = feedDBRef.child(key)
        ref.runTransactionBlock({ (thisData: FIRMutableData) -> FIRTransactionResult in
            if var post = thisData.value as? [String: Any], let uid = FIRAuth.auth()?.currentUser?.uid {
                let stat = post[name] as? [String] ?? []
                var statSet = Set(stat)
                if increase {
                    statSet.insert(uid)
                } else {
                    statSet.remove(uid)
                }
                let statArr = Array(statSet)
                post[name] = statArr as Any
                
                switch name {
                case "downloads":
                    if FireAudioManager.saveCachedTrackToLibrary(track) {
                        thisData.value = post
                        track.downloads = statArr
                    }
                case "stars":
                    thisData.value = post
                    track.stars = statArr
                case "flags":
                    thisData.value = post
                    track.flags = statArr
                default:
                    break
                }
                
                return FIRTransactionResult.success(withValue: thisData)
            }
            return FIRTransactionResult.success(withValue: thisData)
            
        }) { (error: Error?, isCommitted: Bool, snapshot: FIRDataSnapshot?) in
            if let error = error {
                print("Error is data transaction: \(error.localizedDescription)")
            }
            if isCommitted {
                print("committed data")
                var num = 0
                
                if increase {
                    num += 1
                } else {
                    num -= 1
                }
                let userDBRef = FIRDatabase.database().reference().child("users")
                let ref = userDBRef.child(track.user)
                ref.runTransactionBlock({ (data: FIRMutableData) -> FIRTransactionResult in
                    print("running block")
                    if var prof = data.value as? [String:Any] {
                        switch name {
                        case "downloads":
                            var dl = prof["downloads"] as? Int ?? 0
                            dl += num
                            prof["downloads"] = dl
                            data.value = prof
                        case "stars":
                            var star = prof["stars"] as? Int ?? 0
                            star += num
                            prof["stars"] = star
                            data.value = prof
                        default:
                            break
                        }
                        print("commiting data: \(name): \(data.value)")
                        return FIRTransactionResult.success(withValue: data)
                    }
                    return FIRTransactionResult.success(withValue: data)
                })
                
            } else {
                print("could not commit data")
            }
        }
    }
    
    static func saveCachedTrackToLibrary(_ track: Track) -> Bool {
        let trackToSave = track
        guard let FIRkey = track.key else {
            print("no key found for track")
            return false
        }
        var url: URL?
        
        for (key,file) in FireAudioManager.quickLoadFiles {
            if key == FIRkey {
                url = file.url
                break
            }
        }
        if let url = url {
            trackToSave.fileURL = url.lastPathComponent
            if SavedTrackManager.saveNewTrack(newTrack: trackToSave, tempLocation: url) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
        
    }
    
    //MARK: - File Handling functions
    
    static func removeTrackFromFirebase(track: Track, fromFeedDBRef feedDBRef: FIRDatabaseReference, completion: @escaping (Error?) -> Void) {
        guard let key = track.key else {
            print("can not remove from Firebase, can not find key")
            return
        }
        let fileURL = track.fileURL
        let ref = feedDBRef.child(key)
        let userDBRef = AppDelegate.userDBRef
        
        ref.removeValue { (error: Error?, reference: FIRDatabaseReference) in
            if let error = error {
                completion(error)
                return
            }
            userDBRef.child(track.user).observeSingleEvent(of: .value, with: { (snapshot:FIRDataSnapshot) in
                var val = snapshot.value as! [String:Any]
                if let keys = val["tracks"] as? [String] {
                    var keysSet = Set(keys)
                    keysSet.remove(ref.key)
                    val["tracks"] = Array(keysSet)
                }
                userDBRef.child(track.user).setValue(val as Any, withCompletionBlock: { (error:Error?, reference: FIRDatabaseReference) in
                    FIRStorage.storage().reference(forURL: fileURL).delete(completion: { (error: Error?) in
                        if let error = error {
                            completion(error)
                            return
                        }
                        completion(nil)
                        return
                    })
                })
                
            })
        }
    }
    
    static func loadAndStoreAudioFile(forTrack track: Track, fromFeedDBRef feedDBRef: FIRDatabaseReference, withCompletion finCompletion: @escaping ((AVAudioFile?, Error?) -> Void)) {
        //TODO: Need to create custom fadeIn and fadeOut on audioplayers (since I'm scrapping audiokit for this view controller)
        guard let key = track.key else {
            print("Can not find key for track")
            return
        }
        
        for (name, file) in FireAudioManager.quickLoadFiles {
            if name == key {
                finCompletion(file, nil)
                return
            }
        }
        // If the requested track is not already saved, then we will download the track from firebase, and if our temporary storage contains more than X tracks, we will pop the first one from storage.
        
        feedDBRef.child(track.key!).observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
            let fileManager = FileManager.default
            let fileNameRand = "\(UUID().uuidString).m4a"
            let localURL = fileManager.temporaryDirectory.appendingPathComponent(fileNameRand)
            if let value = snapshot.value as? [String: Any] {
                let url = value["fileURL"] as! String
                let ref = FIRStorage.storage().reference(forURL: url)
                
                ref.write(toFile: localURL, completion: { (url: URL?, error: Error?) -> Void in
                    if let url = url {
                        var file = AVAudioFile()
                        do {
                            file = try AVAudioFile(forReading: url)
                        } catch {
                            print("Could not create audio file")
                            finCompletion(nil, error)
                            return
                        }
                        FireAudioManager.quickLoadFiles.append((key: key, file: file))
                        
                        if FireAudioManager.quickLoadFiles.count > 5 {
                            let first = FireAudioManager.quickLoadFiles.first
                            do {
                                try fileManager.removeItem(at: first!.file.url)
                                FireAudioManager.quickLoadFiles.remove(at: 0)
                            } catch {
                                print("Could not remove audio file: \(error.localizedDescription)")
                                finCompletion(nil, error)
                                return
                            }
                        }
                        
                        finCompletion(file, nil)
                        return
                        
                    } else if let error = error {
                        print("Audio download error: \(error.localizedDescription)")
                        finCompletion(nil, error)
                        return
                    }
                })
                
            } else {
                print("track is no longer available")
                finCompletion(nil, TrackError.notAvailable)
                return
            }
            
        }
    }
}
