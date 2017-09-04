//
//  WordsmithFeedViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class WordsmithFeedViewController: UIViewController, WordsmithPageViewControllerChild {
    @IBOutlet weak var libraryBarButton: UIBarButtonItem!
    @IBOutlet weak var tableContainerView: UIView!
    
    weak var wordsmithPageVC: WordsmithPageViewController!
    var fromStudio: Bool!
    var tableContainerController: WordsmithFeedTableViewController!
    
    var mode: TableDisplayMode = .web {
        didSet{
            if let container = tableContainerController {
                container.currentMode = mode
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if fromStudio == nil {
            fromStudio = false
        }
    }
    @IBAction func libraryButtonTapped(_ sender: UIBarButtonItem) {
        switch mode {
        case .web:
            mode = .local
            let savedTracks = SavedTrackManager.savedTracks
            tableContainerController.tracks = savedTracks.reversed()
            tableContainerController.tableView.reloadData()
            sender.image = UIImage(named: "savedMusicFilled")
        case .local:
            mode = .web
            tableContainerController.loadFullTrackSuite(withActivityIndicator: true, completion: nil)
            sender.image = UIImage(named: "savedMusic")
        }
        let topRow = IndexPath(row: 0, section: 0)
        tableContainerController.tableView.scrollToRow(at: topRow, at: .top, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "embeddFeedTableSegue":
            let vc = segue.destination as! WordsmithFeedTableViewController
            vc.parentVC = self
            tableContainerController = vc
        default:
            break
        }
    }
}
