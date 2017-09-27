//
//  GenreCollectionViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import AVFoundation

enum GenreChoices: String {
    case Rap, Techno, Trap
}

class GenreCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "GenreCell"
    let sectionInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    let itemsPerRow: CGFloat = 1
    var genreCount: Int!
    var genreChoice: GenreChoices!
    
    // AV Player Layer
    var playerLayer = AVPlayerLayer()

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
        
        genreCount = GenreChoices.Trap.hashValue + 1
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showWordsmithPagesSegue":
            
            let vc = segue.destination as! WordsmithPageViewController
            vc.genreChoice = self.genreChoice
            
        default:
            break
        }
    }

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
        
        let genre = getGenreFromHash(hashValue: indexPath.row)
        
        switch genre {
        case .Rap:
            cell.genreLabel.text = GenreChoices.Rap.rawValue
            cell.genre = .Rap
            setCellVideoLayer(cell: cell, resourceName: "rock")
        case .Techno:
            cell.genreLabel.text = GenreChoices.Techno.rawValue
            cell.genre = .Techno
        case .Trap:
            cell.genreLabel.text = GenreChoices.Trap.rawValue
            cell.genre = .Trap
        }
        
        cell.backgroundColor = .yellow
        cell.layer.cornerRadius = 15.0
        cell.layer.borderColor = cell.genreLabel.backgroundColor?.cgColor
        cell.layer.borderWidth = 10.0
        
        
    
        // Configure the cell
    
        return cell
    }
    
    func getGenreFromHash(hashValue hash: Int) -> GenreChoices {
        switch hash {
        case 0:
            return .Rap
        case 1:
            return .Techno
        case 2:
            return .Trap
        default:
            fatalError("Genre Choice Hash Value out of range: hash = \(hash)")
        }
    }
    
    func setCellVideoLayer(cell: GenreCollectionViewCell, resourceName: String) {
        
        let playerLayer = AVPlayerLayer()
        playerLayer.frame = cell.avLayerView.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        guard let url = Bundle.main.path(forResource: resourceName, ofType: "m4v") else {
            print("\(resourceName) not found!")
            return
        }
        
        let player = AVPlayer(url: URL(fileURLWithPath: url))
        player.actionAtItemEnd = .none
        player.volume = 0.0
        playerLayer.player = player
        cell.avLayerView.layer.addSublayer(playerLayer)
        cell.avLayerView.playerLayer = playerLayer
        player.play()
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected a cell")
        let cell = collectionView.cellForItem(at: indexPath) as! GenreCollectionViewCell
        self.genreChoice = cell.genre
        self.performSegue(withIdentifier: "showWordsmithPagesSegue", sender: self)
    }
}
