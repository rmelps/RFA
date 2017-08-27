//
//  WordsmithFeedViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 8/25/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

class WordsmithFeedViewController: UIViewController, WordsmithPageViewControllerChild {
    
    var wordsmithPageVC: WordsmithPageViewController!
    var fromStudio: Bool!
    

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "embeddFeedTableSegue":
            let vc = segue.destination as! WordsmithFeedTableViewController
            vc.parentVC = self
        default:
            break
        }
    }
}
