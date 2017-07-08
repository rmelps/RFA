//
//  WordsmithChoiceViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/5/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import FirebaseDatabase

class WordsmithChoiceViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var playPreviewButton: MenuButton!
    @IBOutlet weak var topStack: UIStackView!
    @IBOutlet weak var bottomStack: UIStackView!
    
    // panGestureRecognizer touches
    private var panGestureRecognizer = UIPanGestureRecognizer()
    private var touchStart = CGPoint()
    private var yOffset = CGFloat()
    private var currentShapeLayer: CAShapeLayer?
    
    // 1st and 2nd labels for stacks
    @IBOutlet weak var topFirstLabel: UILabel!
    @IBOutlet weak var topSecondLabel: UILabel!
    @IBOutlet weak var bottomFirstLabel: UILabel!
    @IBOutlet weak var bottomSecondLabel: UILabel!
    @IBOutlet weak var enterStudioLabel: UILabel!
    @IBOutlet weak var voteLabel: UILabel!
    
    // Firebase Storage reference
    var trackStorageRef: FIRStorageReference!
    private var downloadTask: FIRStorageDownloadTask?
    
    // Firebase Database Reference
    var currentTrackRef: FIRDatabaseReference!
    
    // Chosen Genre
    var genre: GenreChoices!
    
    // AVPlayer
    var player: AVAudioPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Pan Gesture Recognizer to view
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WordsmithChoiceViewController.handlePan(_:)))
        panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(panGestureRecognizer)
        
        // Add additional control events for playPreviewButton touchUp
        playPreviewButton.addTarget(self, action: #selector(WordsmithChoiceViewController.playPreviewButtonUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // Set the current day's database reference
        let genreRaw = genre.rawValue.lowercased()
        print(genreRaw)
        //TODO: Will not use database reference "today", but the actual date
        currentTrackRef = FIRDatabase.database().reference().child("tracks/\(genreRaw)/today")
        
        // Find current tracks storage URL
        currentTrackRef.observe(.value) { (snapShot) in
            let snapVal = snapShot.value as? [String: Any]
            
            if let fileURL = snapVal?["fileURL"] as? String {
                self.trackStorageRef = FIRStorage.storage().reference(forURL: fileURL)
            }
        }
        
    }
    
    @IBAction func playPreviewButtonDown(_ sender: MenuButton) {
        print("button down")
        
        //TODO: Change test mp3 to daily mp3
        if downloadTask == nil {
            if let player = player {
                player.play()
            } else {
                guard trackStorageRef != nil else {
                    print("Found nil for test storage ref")
                    return
                }
                downloadTask = trackStorageRef.data(withMaxSize: 15 * 1024 * 1024, completion: { (data, error) in
                    self.downloadTask = nil
                    if let error = error {
                        print("downloadTask error occurred: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data {
                        do {
                            try self.player = AVAudioPlayer(data: data, fileTypeHint: ".mp3")
                            self.player?.numberOfLoops = -1
                            self.player!.play()
                        } catch let playerError {
                            print("player error occurred: \(playerError.localizedDescription)")
                        }
                    }
                })
            }
        } else {
            downloadTask?.resume()
        }
        
    }
    
    @objc func playPreviewButtonUp(_ sender: MenuButton) {
        print("button up")
        
        player?.pause()
        
        if let downloadTask = downloadTask {
            downloadTask.pause()
        }
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        var touch = CGPoint()
        var startPoint = CGPoint()
        let maxDistance: CGFloat = abs(bottomStack.bounds.minY - self.view.center.y)
        let minDistance: CGFloat = abs(bottomStack.bounds.maxY - self.view.center.y - playPreviewButton.bounds.height / 2)
        let maxLineWidth: CGFloat = playPreviewButton.bounds.width
        
        switch sender.state {
        case .possible:
            break
        case .began:
            touchStart = sender.location(in: self.view)
        case .changed:
            
            touch = sender.location(in: self.view)
            yOffset = touchStart.y - touch.y
            
            if abs(yOffset) > maxDistance {
                break
            }
            
            let thickness = maxLineWidth - abs(yOffset / maxDistance * maxLineWidth)
            startPoint = CGPoint(x: self.view.center.x, y: self.view.center.y)
            let endPoint = CGPoint(x: startPoint.x, y: startPoint.y - yOffset)
            drawLine(from: startPoint, to: endPoint, thickness: thickness)
            
        case .ended:
            UIView.animate(withDuration: 0.5, animations: {
                self.currentShapeLayer?.strokeColor = UIColor.clear.cgColor
                
                
                if abs(self.yOffset) > minDistance {
                    if self.yOffset > 0 {
                        self.topFirstLabel.isHidden = true
                        self.topSecondLabel.isHidden = true
                        self.bottomStack.isHidden = true
                    } else {
                        self.bottomFirstLabel.isHidden = true
                        self.bottomSecondLabel.isHidden = true
                        self.topStack.isHidden = true
                    }
                }
                
            })
            print(sender.location(in: self.view))
        case .failed, .cancelled:
            break
        }
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint:CGPoint, thickness: CGFloat) {
        currentShapeLayer?.removeFromSuperlayer()
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        path.lineWidth = thickness
        path.lineCapStyle = .round
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineWidth = thickness
        
        currentShapeLayer = shapeLayer
        
        self.view.layer.insertSublayer(currentShapeLayer!, at: 0)
        
    }
    
    
    //MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            
            let pan = gestureRecognizer as! UIPanGestureRecognizer
            
            if abs(pan.velocity(in: self.view).x) > abs(pan.velocity(in: self.view).y) {
                return false
            }
        }
        return true
    }
    
}
