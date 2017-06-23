//
//  GenreCollectionViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

enum GenreChoices: Int {
    case rap = 0, techno, trap
}

class GenreCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "GenreCell"
    let sectionInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    let itemsPerRow: CGFloat = 1
    var genreCount: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        
        let topCon = collectionView?.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomCon = collectionView?.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let leftCon = collectionView?.leftAnchor.constraint(equalTo: view.leftAnchor)
        let rightCon = collectionView?.rightAnchor.constraint(equalTo: view.rightAnchor)
        
        topCon?.isActive = true
        bottomCon?.isActive = true
        leftCon?.isActive = true
        rightCon?.isActive = true

        // The last element in the GenreChoices enum. If a genre is added after this value, will
        // need to update the below equation to include that value
        
        genreCount = GenreChoices.trap.hashValue + 1
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return genreCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! GenreCollectionViewCell
        if let genre = GenreChoices(rawValue: indexPath.row) {
            switch genre {
            case .rap:
                cell.genreLabel.text = "Rap"
            case .techno:
                cell.genreLabel.text = "Techno"
            case .trap:
                cell.genreLabel.text = "Trap"
            }
        }
        
        cell.backgroundColor = .yellow
        cell.layer.cornerRadius = 15.0
        cell.layer.borderColor = cell.genreLabel.backgroundColor?.cgColor
        cell.layer.borderWidth = 10.0
        
        
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.top * (itemsPerRow + 1)
        let availableHeight = view.frame.height - paddingSpace
        let heightPerItem = availableHeight / itemsPerRow
        
        return CGSize(width: heightPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return sectionInsets.left
    }
}
