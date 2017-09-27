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
    var genre: GenreChoices!
    var feedDBRef: DatabaseReference!
    var userDBRef: DatabaseReference!
    weak var parentVC: WordsmithFeedViewController!
    var uploadStorageRef: StorageReference!
    
    var audioPlayer: AVAudioPlayer!
    
    var tracks = [Track]()
    var users = [String:String]()
    
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
        
        genre = parentVC.wordsmithPageVC.genreChoice!
        feedDBRef = Database.database().reference().child("feed/\(genre.rawValue.lowercased())")
        userDBRef = Database.database().reference().child("users")
        uploadStorageRef = Storage.storage().reference().child("uploads")
        
        currentMode = parentVC.mode
    
        loadFullTrackSuite(withActivityIndicator: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        AppDelegate.clearProfPicTempDir()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if parentVC.fromStudio {
            loadFullTrackSuite(withActivityIndicator: true, completion: nil)
            parentVC.fromStudio = false
        }
        
        if let row = selectedRow {
            //let indexPath = IndexPath(row: row, section: 0)
            //tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
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
        
        //TODO: There seems to be an issue when uploading the first track of a feed in displaying the correct cell
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TrackTableViewCell
        guard indexPath.row < tracks.count else {
            return cell
        }
        let trackForCell = tracks[indexPath.row]
        let imagePadding: CGFloat = 16
        cell.track = trackForCell
        cell.trackNameLabel.text = trackForCell.title
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
            cell.userNameLabel.text = users[trackForCell.user]
        case .local:
            cell.backgroundColor = UIColor(displayP3Red: 107/255, green: 184/255, blue: 101/255, alpha: 1.0)
        //TODO: Add in method to grab username for locally saved tracks
        default:
            break
        }
        
        let photoRef = Storage.storage().reference().child("profilePics/\(trackForCell.user)")
        let fileManager = FileManager.default
        let base = fileManager.temporaryDirectory.appendingPathComponent("profPics")
        let url = base.appendingPathComponent(trackForCell.user)
        if fileManager.fileExists(atPath: url.path) {
            
            let path = url.path
            print(fileManager.temporaryDirectory.path)
            print(path)
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
                let uid = Auth.auth().currentUser!.uid
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
        guard tracks.count > 0 else {
            return
        }
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
        AppDelegate.clearProfPicTempDir()
        
        if indicator {
            parentVC.view.addSubview(activityIndicator)
        }
        
        let recentPostsQuery = feedDBRef.queryOrderedByKey().queryLimited(toLast: 10)
        
        
        recentPostsQuery.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            self.tracks = []
            for child in snapshot.children {
                if let childSnap = child as? DataSnapshot {
                    let track = Track(snapShot: childSnap)
                    self.tracks.insert(track, at: 0)
                }
            }
            
            self.userDBRef.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
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
        
        feedDBRef.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            print("running loop")
            while key == "" {
                if index < 0 {
                    break
                }
                if let lastKey = self.tracks[index].key, snapshot.hasChild(lastKey) {
                    key = lastKey
                    print("found key")
                    let query = self.feedDBRef.queryOrderedByKey().queryEnding(atValue: key).queryLimited(toLast: 6)
                    
                    query.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
                        var newTracks = [Track]()
                        for child in snapshot.children {
                            if let childSnap = child as? DataSnapshot {
                                if childSnap.key == key {
                                    continue
                                }
                                let track = Track(snapShot: childSnap)
                                newTracks.insert(track, at: 0)
                            }
                        }
                        self.tracks.append(contentsOf: newTracks)
                        
                        self.userDBRef.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
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
        if let user = Auth.auth().currentUser, user.uid == tracks[indexPath.row].user {
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
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showProfileFromTableSegue":
            let vc = segue.destination as! ProfileViewController
            let cell = sender as! TrackTableViewCell
            vc.user = cell.user
            vc.tag = cell.user.tagLine
            vc.name = cell.user.name
            vc.bio = cell.user.biography
            vc.image = cell.profilePic.image
            vc.delegate = self
        default:
            break
        }
    }
    
    func retrieveUserProfile(forTrack track: Track, handler: @escaping ((RFAUser?) -> Void)) {
        self.userDBRef.observeSingleEvent(of: .value) { (snapshot:DataSnapshot) in
            guard snapshot.hasChild(track.user) else {
                handler(nil)
                return
            }
            let userSnap = snapshot.childSnapshot(forPath: track.user)
            let user = RFAUser(uid: track.user, snapShot: userSnap, picURL: nil, nameFromProvider: nil)
            handler(user)
        }
    }
 
    //MARK: - File Handling functions
    
    func removeTrackFromFirebase(track: Track, completion: @escaping (Error?) -> Void) {
        guard currentMode == .web else {
            print("can not remove from Firebase, mode is \(currentMode.rawValue)")
            return
        }
        FireAudioManager.removeTrackFromFirebase(track: track, fromFeedDBRef: feedDBRef, completion: completion)
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
        
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        FireAudioManager.loadAndStoreAudioFile(forTrack: track, fromFeedDBRef: self.feedDBRef) { (file: AVAudioFile?, error: Error?) in
            if let error = error {
                AppDelegate.presentErrorAlert(withMessage: error.localizedDescription, fromViewController: self.parentVC)
            } else if let file = file {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: file.url, fileTypeHint: ".m4a")
                    self.audioPlayer.numberOfLoops = -1
                    self.audioPlayer.play()
                } catch {
                    AppDelegate.presentErrorAlert(withMessage: "Could not play track!", fromViewController: self.parentVC)
                }
            }
        }
    }
}
