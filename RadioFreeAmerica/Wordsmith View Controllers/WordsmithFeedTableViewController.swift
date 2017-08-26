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

class WordsmithFeedTableViewController: UITableViewController {
    
    let reuseIdentifier = "trackCell"
    var feedDBRef: FIRDatabaseReference!
    var userDBRef: FIRDatabaseReference!
    var parentVC: WordsmithFeedViewController!
    
    var tracks = [Track]()
    var users = [String:String]()
   

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        
        let genre = parentVC.wordsmithPageVC.genreChoice!
        feedDBRef = FIRDatabase.database().reference().child("feed/\(genre.rawValue.lowercased())")
        userDBRef = FIRDatabase.database().reference().child("users")
        
        loadFullTrackSuite()
  
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
        cell.trackNameLabel.text = trackForCell.title
        cell.userNameLabel.text = users[trackForCell.user]
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

        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        let activityIndicator = ActivityIndicatorView(withProgress: false)
        parentVC.view.addSubview(activityIndicator)
        
        let recentPostsQuery = feedDBRef.queryLimited(toFirst: 50)
        
        recentPostsQuery.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
            for child in snapshot.children {
                if let childSnap = child as? FIRDataSnapshot {
                    let track = Track(snapShot: childSnap)
                    self.tracks.append(track)
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
            })
    
            self.tableView.reloadData()
            activityIndicator.removeFromSuperview()
        }
        
        
    }

}
