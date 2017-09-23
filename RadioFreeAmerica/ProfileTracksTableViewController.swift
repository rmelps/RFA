//
//  ProfileTracksTableViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 9/18/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ProfileTracksTableViewController: UITableViewController {
    
    var parentVC: ProfileViewController!
    let reuseIdentifier = "profileTrackCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let delegate = parentVC.delegate as? WordsmithFeedTableViewController {
            let thisUserDBRef = delegate.userDBRef.child(parentVC.user.uid)
            retrieveRecentTracks(fromUserDBRef: thisUserDBRef, feedDBRef: delegate.feedDBRef) { (tracks: [Track]) in
                self.parentVC.tracks = tracks
                print("track count: \(tracks.count)")
                
                self.tableView.reloadData()
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
    
    func retrieveRecentTracks(fromUserDBRef ref: FIRDatabaseReference, feedDBRef fref: FIRDatabaseReference, completion: @escaping (([Track]) -> Void)) {
        var allTracks = [Track]()
        ref.observeSingleEvent(of: .value) { (snapshot:FIRDataSnapshot) in
            if let val = snapshot.value as? [String:Any], let tracks = val["tracks"] as? [String] {
                fref.observeSingleEvent(of: .value, with: { (snapshot: FIRDataSnapshot) in
                    for trackKey in tracks {
                        if snapshot.hasChild(trackKey){
                            allTracks.append(Track(snapShot: snapshot))
                        }
                    }
                    completion(allTracks)
                })
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return parentVC.tracks.count
    }

   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell...

        return cell
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

}
