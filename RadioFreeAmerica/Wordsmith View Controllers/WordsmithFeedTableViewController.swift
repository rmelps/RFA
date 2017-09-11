//
//  WordsmithFeedTableViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/23/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import AVFoundation

enum TableDisplayMode: String {
    case web
    case local
}

class WordsmithFeedTableViewController: UITableViewController {
    
    let reuseIdentifier = "trackCell"
    var feedDBRef: FIRDatabaseReference!
    var userDBRef: FIRDatabaseReference!
    weak var parentVC: WordsmithFeedViewController!
    var uploadStorageRef: FIRStorageReference!
    
    var audioPlayer: AVAudioPlayer!
    
    var tracks = [Track]()
    var users = [String:String]()
    var quickLoadFiles = [(key:String, file: AVAudioFile)]()
    
    var compressedHeight: CGFloat!
    var expandedHeight: CGFloat {
        get {
            let padding: CGFloat = 165.0
            return compressedHeight + padding
        }
    }
    
    var selectedRow: Int?
    var editPoint: CGPoint?
    var currentMode: TableDisplayMode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        compressedHeight = self.tableView.frame.height / 6
        
        let genre = parentVC.wordsmithPageVC.genreChoice!
        feedDBRef = FIRDatabase.database().reference().child("feed/\(genre.rawValue.lowercased())")
        userDBRef = FIRDatabase.database().reference().child("users")
        uploadStorageRef = FIRStorage.storage().reference().child("uploads")
        
        currentMode = parentVC.mode
    
        loadFullTrackSuite(withActivityIndicator: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if parentVC.fromStudio {
            loadFullTrackSuite(withActivityIndicator: true, completion: nil)
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
        cell.tableView = self.tableView
        
        // Add gesture recognizer to cell to turn on editing of that particular cell
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(WordsmithFeedTableViewController.setCellEditing(_:)))
        cell.addGestureRecognizer(longPressRecognizer)
        
        if indexPath.row == selectedRow {
            cell.displayToolBar(on: true)
        } else {
            cell.displayToolBar(on: false)
        }
        
        switch currentMode {
        case .web:
            cell.backgroundColor = UIColor(displayP3Red: 223/255, green: 109/255, blue: 99/255, alpha: 1.0)
        case .local:
            cell.backgroundColor = UIColor(displayP3Red: 107/255, green: 184/255, blue: 101/255, alpha: 1.0)
        default:
            break
        }
        
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
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.isEditing {
            tableView.setEditing(false, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TrackTableViewCell
        
        if indexPath.row == selectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
            selectedRow = nil
            cell.displayToolBar(on: false)
            if audioPlayer != nil {
                audioPlayer.stop()
            }
        } else {
            if let oldRow = selectedRow {
                let oldCell = tableView.cellForRow(at: IndexPath(row: oldRow, section: 0)) as? TrackTableViewCell
                oldCell?.displayToolBar(on: false)
            }
            selectedRow = indexPath.row
            let track = tracks[selectedRow!]
            
            switch currentMode {
            case .web:
                // Configure toolbar style for selected cell
                let uid = FIRAuth.auth()!.currentUser!.uid
                cell.refreshButtonStyle(forTrack: track, forUser: uid)
                
                cell.displayToolBar(on: true)
                loadAndStoreAudioFile(forTrack: track)
            case .local:
                cell.displayToolBar(on: false)
                retrieveLocalAudioFile(forTrack: track)
            default:
                break
            }
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let location = editPoint, let path = tableView.indexPathForRow(at: location), path == indexPath {
            guard let cell = tableView.cellForRow(at: indexPath) as? TrackTableViewCell else {
                return false
            }
            switch currentMode {
            case .web:
                if cellBelongsToCurrentUser(cell: cell) {
                    return true
                }
            case .local:
                return true
            default:
                fatalError("no mode has been set")
            }
        }
        return false
    }

    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let track = tracks[indexPath.row]
            switch currentMode {
            case .web:
                let activityView = ActivityIndicatorView(withProgress: false)
                parentVC.view.addSubview(activityView)
                removeTrackFromFirebase(track: track, completion: { (error: Error?) in
                    activityView.removeFromSuperview()
                    if let error = error {
                        print("Could not remove track from Firebase: \(error.localizedDescription)")
                        return
                    }
                    self.tracks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.setEditing(false, animated: true)
                })
            case .local:
                if SavedTrackManager.removeTrack(atIndex: indexPath.row, sourceReversed: true) {
                    tracks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.setEditing(false, animated: true)
                } else {
                    AppDelegate.presentErrorAlert(withMessage: "Could Not Delete Track!", fromViewController: parentVC)
                }
            default:
                fatalError("currentMode is not set")
            }
            selectedRow = nil
            tableView.beginUpdates()
            tableView.endUpdates()
            
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action:UITableViewRowAction, indexPath: IndexPath) in
            let track = self.tracks[indexPath.row]
            switch self.currentMode {
            case .web:
                self.removeTrackFromFirebase(track: track, completion: { (error: Error?) in
                    if let error = error {
                        print("Could not remove track from Firebase: \(error.localizedDescription)")
                        return
                    }
                    self.tracks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.setEditing(false, animated: true)
                })
            case .local:
                if SavedTrackManager.removeTrack(atIndex: indexPath.row, sourceReversed: true) {
                    self.tracks.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                } else {
                    AppDelegate.presentErrorAlert(withMessage: "Could Not Delete Track!", fromViewController: self.parentVC)
                }
            default:
                fatalError("currentMode is not set")
            }
        }
        return [deleteAction]
    }
    
    //MARK: - Scroll View Delegate
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        // Reload table view if the user scrolls a certain distance above the top cell
        let topCellYPosInTable = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).origin
        let topCellYPosInSuper = tableView.convert(topCellYPosInTable, to: parentVC.view)
        let yPadding = parentVC.tableContainerView.convert(parentVC.tableContainerView.frame.origin, to: parentVC.view).y / 2
        
        if topCellYPosInSuper.y > (compressedHeight + yPadding) {
            if currentMode == .web {
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
                let header = UIView(frame: CGRect(origin: tableView.frame.origin, size: CGSize(width: tableView.bounds.width, height: 60)))
                indicator.center = header.center
                header.addSubview(indicator)
                indicator.startAnimating()
                indicator.hidesWhenStopped = true
                tableView.tableHeaderView = header
                loadFullTrackSuite(withActivityIndicator: false, completion: {
                    indicator.stopAnimating()
                    header.frame = CGRect(origin: header.frame.origin, size: CGSize(width: header.frame.width, height: 0.0))
                })
            }
        }
        
        // Query new tracks if the user scrolls a certain distance below final cell
        let row = tracks.count - 1
        let bottomCellRectInTable = tableView.rectForRow(at: IndexPath(row: row, section: 0))
        let bottomCellYPosInTable = bottomCellRectInTable.origin
        let bottomCellYPosInSuper = tableView.convert(bottomCellYPosInTable, to: parentVC.view)
        
        if bottomCellYPosInSuper.y < (parentVC.view.frame.maxY - bottomCellRectInTable.height - yPadding) {
            print("should append new tracks")
            if currentMode == .web {
                appendNewTracks(completion: nil)
            }
            
        }
    }
    
    //MARK: - Grab track data
    
    func loadFullTrackSuite(withActivityIndicator indicator: Bool, completion: (()->Void)?){
        let activityIndicator = ActivityIndicatorView(withProgress: false)
        
        if indicator {
            parentVC.view.addSubview(activityIndicator)
        }
        
        let recentPostsQuery = feedDBRef.queryOrderedByKey().queryLimited(toLast: 10)
        
        
        recentPostsQuery.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
            self.tracks = []
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
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
            if indicator {
                activityIndicator.removeFromSuperview()
            }
            completion?()
        }
    }
    
    func appendNewTracks(completion: (()->Void)?) {
        var key: String = ""
        var index: Int = tracks.count - 1
        
        feedDBRef.observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
            print("running loop")
            while key == "" {
                if index < 0 {
                    break
                }
                if let lastKey = self.tracks[index].key, snapshot.hasChild(lastKey) {
                    key = lastKey
                    print("found key")
                    let query = self.feedDBRef.queryOrderedByKey().queryEnding(atValue: key).queryLimited(toLast: 6)
                    
                    query.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
                        var newTracks = [Track]()
                        for child in snapshot.children {
                            if let childSnap = child as? FIRDataSnapshot {
                                if childSnap.key == key {
                                    continue
                                }
                                let track = Track(snapShot: childSnap)
                                newTracks.insert(track, at: 0)
                            }
                        }
                        self.tracks.append(contentsOf: newTracks)
                        
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
                            self.tableView.beginUpdates()
                            self.tableView.endUpdates()
                        })
                    }
                } else {
                    print("couldn't find key")
                    index -= 1
                }
            }
            
        })
        
        
    }
    
    func cellBelongsToCurrentUser(cell: TrackTableViewCell) -> Bool {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return false
        }
        if let user = FIRAuth.auth()?.currentUser, user.uid == tracks[indexPath.row].user {
            return true
        }
        return false
    }
    //MARK: - Gesture Recognizer Callbacks
    
    @objc func dismissCellEditing(_ sender: UITapGestureRecognizer) {
        if sender.state == .possible, !tableView.isEditing {
            tableView.removeGestureRecognizer(sender)
            return
        }
        guard editPoint != nil, tableView.isEditing else {
            print("editPoint: \(editPoint) \n editing?: \(tableView.isEditing)")
            tableView.removeGestureRecognizer(sender)
            return
        }
        let location = sender.location(in: tableView)
        if let editingPath = tableView.indexPathForRow(at: editPoint!) {
            let thisPath = tableView.indexPathForRow(at: location)
            if thisPath != editingPath {
                tableView.setEditing(false, animated: true)
                tableView.removeGestureRecognizer(sender)
            }
        }
    }
    
    @objc func setCellEditing(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let location = sender.location(in: self.tableView)
        editPoint = location
        
        if let indexPath = tableView.indexPathForRow(at: location) {
            if let cell = tableView.cellForRow(at: indexPath) as? TrackTableViewCell {
                guard !cell.isSelected else {
                    return
                }
                if tableView.isEditing {
                    tableView.setEditing(false, animated: true)
                } else {
                    tableView.setEditing(true, animated: true)
                    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(WordsmithFeedTableViewController.dismissCellEditing(_:)))
                    tapGestureRecognizer.numberOfTapsRequired = 2
                    if cell.isEditing {
                        tableView.addGestureRecognizer(tapGestureRecognizer)
                    } else {
                        tableView.setEditing(false, animated: false)
                    }
                }
                
            }
        }
    }
    //MARK: - Cell Toolbar Actions
    func modifyPostStat(statName name: String, increase: Bool) {
        
        guard currentMode == .web, let row = selectedRow else {
            print("Like button should only be selectable in web mode")
            return
        }
        let track = tracks[row]
        guard let key = track.key else {
            print("Could not find key for track")
            return
        }
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
                    if self.saveTrackToLibrary(track) {
                        
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
                let ref = self.userDBRef.child(track.user)
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
    
    func saveTrackToLibrary(_ track: Track) -> Bool {
        let trackToSave = track
        guard let FIRkey = track.key else {
            print("no key found for track")
            return false
        }
        var url: URL?
        
        for (key,file) in quickLoadFiles {
            if key == FIRkey {
                url = file.url
                break
            }
        }
        
        if let url = url {
            trackToSave.fileURL = url.lastPathComponent
            if SavedTrackManager.saveNewTrack(newTrack: trackToSave, tempLocation: url) {
                let alert = UIAlertController(title: "Saved!", message: "\"\(track.title)\" has been saved!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Nice", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return true
            } else {
                AppDelegate.presentErrorAlert(withMessage: "Could not save Track", fromViewController: parentVC)
                return false
            }
        } else {
            AppDelegate.presentErrorAlert(withMessage: "Song has not finished downloading!", fromViewController: parentVC)
            return false
        }
    
    }
    
    //MARK: - File Handling functions
    
    func removeTrackFromFirebase(track: Track, completion: @escaping (Error?) -> Void) {
        guard currentMode == .web, let key = track.key else {
            print("can not remove from Firebase, mode is \(currentMode.rawValue)")
            return
        }
        let fileURL = track.fileURL
        let ref = feedDBRef.child(key)
        
        ref.removeValue { (error: Error?, reference: FIRDatabaseReference) in
            if let error = error {
                completion(error)
            }
            FIRStorage.storage().reference(forURL: fileURL).delete(completion: { (error: Error?) in
                if let error = error {
                    completion(error)
                }
                completion(nil)
            })
        }
    }
    
    func retrieveLocalAudioFile(forTrack track: Track) {
        guard currentMode == .local else {
            print("Can not retrieve local audio files while in web mode")
            return
        }
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        do {
            let url = SavedTrackManager.getLocalURL(forTrack: track)
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: ".m4a")
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
        } catch {
            print("error retriving local track: \(error.localizedDescription)")
        }
    }
    
    func loadAndStoreAudioFile(forTrack track: Track) {
        //TODO: Need to create custom fadeIn and fadeOut on audioplayers (since I'm scrapping audiokit for this view controller)
        guard let key = track.key else {
            print("Can not find key for track")
            return
        }
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        for (name, file) in quickLoadFiles {
            if name == key {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: file.url, fileTypeHint: ".m4a")
                    audioPlayer.numberOfLoops = -1
                    audioPlayer.play()
                    return
                } catch {
                    print("error in playing saved audio file: \(error.localizedDescription)")
                    return
                }
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
                
                ref.write(toFile: localURL, completion: { (url: URL?, error: Error?) in
                    if let url = url {
                        do {
                            let file = try AVAudioFile(forReading: url)
                            self.audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: ".m4a")
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
 
                            self.audioPlayer.numberOfLoops = -1
                            self.audioPlayer.play()
                            //TODO: Perfect this timer for fade in/fade out durations
                            /*
                            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
                                print(self.audioPlayer.currentTime)
                                if self.audioPlayer.currentTime > 10.0 {
                                    timer.invalidate()
                                }
                                if !self.audioPlayer.isPlaying {
                                    timer.invalidate()
                                }
                            }).fire()
                            */
                        } catch {
                            print("error in creating ak audio file: \(error.localizedDescription)")
                        }
                    } else if let error = error {
                        print("Audio download error: \(error.localizedDescription)")
                    }
                })
                
            } else {
                AppDelegate.presentErrorAlert(withMessage: "Track is no longer available", fromViewController: self.parentVC)
                return
            }
            
        }
        
    }
}
