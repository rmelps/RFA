//
//  WordsmithFeedTableViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/23/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import AudioKit

class WordsmithFeedTableViewController: UITableViewController {
    
    let reuseIdentifier = "trackCell"
    var feedDBRef: FIRDatabaseReference!
    var userDBRef: FIRDatabaseReference!
    var parentVC: WordsmithFeedViewController!
    var uploadStorageRef: FIRStorageReference!
    
    var audioPlayer: AKAudioPlayer!
    
    var tracks = [Track]()
    var users = [String:String]()
    var quickLoadFiles = [(key:String, file: AKAudioFile)]()
    
    var compressedHeight: CGFloat!
    var expandedHeight: CGFloat {
        get {
            let padding: CGFloat = 165.0
            return compressedHeight + padding
        }
    }
    var selectedRow: Int?
    
    var fromStudio: Bool!
   

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        
        
        compressedHeight = self.tableView.frame.height / 6
        
        let genre = parentVC.wordsmithPageVC.genreChoice!
        feedDBRef = FIRDatabase.database().reference().child("feed/\(genre.rawValue.lowercased())")
        userDBRef = FIRDatabase.database().reference().child("users")
        uploadStorageRef = FIRStorage.storage().reference().child("uploads")
        
        if !parentVC.fromStudio {
            loadFullTrackSuite()
        }
        
  
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if parentVC.fromStudio {
            loadFullTrackSuite()
        }
        
        if let row = selectedRow {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tracks.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TrackTableViewCell
        let trackForCell = tracks[indexPath.row]
        let imagePadding: CGFloat = 16
        cell.trackNameLabel.text = trackForCell.title
        cell.userNameLabel.text = users[trackForCell.user]
        cell.trackDescriptionTextView.text = trackForCell.details
        cell.profileImageWidthConstraint.constant = compressedHeight - imagePadding
        cell.profilePic.image = nil
        
        let photoRef = FIRStorage.storage().reference().child("profilePics/\(trackForCell.user)")
        let fileManager = FileManager.default
        
        let url = fileManager.temporaryDirectory.appendingPathComponent(trackForCell.user)
        if fileManager.fileExists(atPath: url.path) {
            let path = url.path
            if let data = fileManager.contents(atPath: path) {
                cell.profilePic.image = UIImage(data: data)
            }
        } else {
            photoRef.write(toFile: url) { (url: URL?, error: Error?) in
                if let error = error {
                    print("error saving profile image: \(error.localizedDescription)")
                }
                if let url = url {
                    let path = url.path
                    if let data = fileManager.contents(atPath: path) {
                        cell.profilePic.image = UIImage(data: data)
                    }
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let row = selectedRow, indexPath.row == row {
            return expandedHeight
        }
        
        return compressedHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == selectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
            selectedRow = nil
            if audioPlayer != nil {
                audioPlayer.stop()
            }
        } else {
            selectedRow = indexPath.row
            let track = tracks[selectedRow!]
            loadAndStoreAudioFile(forTrack: track)
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func loadFullTrackSuite() {
        tracks = []
        let activityIndicator = ActivityIndicatorView(withProgress: false)
        parentVC.view.addSubview(activityIndicator)
        
        let recentPostsQuery = feedDBRef.queryLimited(toFirst: 50)
        
        recentPostsQuery.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
            for child in snapshot.children {
                if let childSnap = child as? FIRDataSnapshot {
                    let track = Track(snapShot: childSnap)
                    self.tracks.insert(track, at: 0)
                }
            }
            
            self.userDBRef.observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
                for track in self.tracks {
                    if snapshot.hasChild(track.user) {
                        let uidSnap = snapshot.childSnapshot(forPath: track.user)
                        let uidVal = uidSnap.value as! [String: Any]
                        let name = uidVal["name"] as! String
                        self.users.updateValue(name, forKey: track.user)
                    }
                }
                 self.tableView.reloadData()
            })
            self.tableView.reloadData()
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            activityIndicator.removeFromSuperview()
        }
    }
    
    func loadAndStoreAudioFile(forTrack track: Track) {
        guard let key = track.key else {
            print("Can not find key for track")
            return
        }
        for (name, file) in quickLoadFiles {
            if name == key {
                do {
                    print(file.url)
                   audioPlayer = try AKAudioPlayer(file: file, looping: true, completionHandler: nil)
                    AudioKit.output = audioPlayer
                    AudioKit.start()
                    audioPlayer.play()
                    return
                } catch {
                    print("error in playing saved audio file: \(error.localizedDescription)")
                    return
                }
            }
        }
        // If the requested track is not already saved, then we will download the track from firebase, and if our temporary storage contains more than X tracks, we will pop the first one from storage.
        print("COULD NOT FIND LOCALLY CHECKING FIRSTORAGE FOR FILE")
        
        feedDBRef.child(track.key!).observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
            let fileManager = FileManager.default
            let fileNameRand = "\(UUID().uuidString).m4a"
            let localURL = fileManager.temporaryDirectory.appendingPathComponent(fileNameRand)
            if let value = snapshot.value as? [String: Any] {
                let url = value["fileURL"] as! String
                let ref = FIRStorage.storage().reference(forURL: url)
                
                ref.write(toFile: localURL, completion: { (url: URL?, error: Error?) in
                    if let url = url {
                        do {
                            let file = try AKAudioFile(forReading: url)
                            self.audioPlayer = try AKAudioPlayer(file: file, looping: true, completionHandler: nil)
                            self.quickLoadFiles.append((key: key, file: file))
                            
                            if self.quickLoadFiles.count > 5 {
                                let first = self.quickLoadFiles.first
                                do {
                                    try fileManager.removeItem(at: first!.file.url)
                                    self.quickLoadFiles.remove(at: 0)
                                } catch {
                                    print("Could not remove audio file: \(error.localizedDescription)")
                                }
                            }
 
                            AudioKit.output = self.audioPlayer
                            AudioKit.start()
                            self.audioPlayer.play()
                        } catch {
                            print("error in creating ak audio file: \(error.localizedDescription)")
                        }
                    } else if let error = error {
                        print("Audio download error: \(error.localizedDescription)")
                    }
                })
                
            } else {
                print("Could not find snapshot value")
                return
            }
            
        }
        
    }

}
