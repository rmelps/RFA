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

class WordsmithChoiceViewController: UIViewController, WordsmithPageViewControllerChild, UIGestureRecognizerDelegate {
    
    var wordsmithPageVC: WordsmithPageViewController!
    
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
    var userStorageRef: FIRStorageReference!
    private var downloadTask: FIRStorageDownloadTask?
    
    // Firebase Database Reference
    var currentTrackRef: FIRDatabaseReference!
    var userDBRef: FIRDatabaseReference!
    
    // Chosen Genre
    var genre: GenreChoices!
    
    // AVPlayer
    var player: AVAudioPlayer?
    var player2: AVAudioPlayer?
    
    // Track Info View
    var trackInfoView: TrackInfoView!
    
    // URL to temporarily stored beat of the day
    var beatURL: URL?
    
    // Color gradient
    var gradient: CAGradientLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in topStack.arrangedSubviews {
            view.layer.shadowOffset = CGSize(width: 0, height: 0)
            view.layer.shadowOpacity = 1.0
            view.layer.shadowRadius = 3.0
            view.layer.shadowColor = UIColor.white.cgColor
        }
        
        for view in bottomStack.arrangedSubviews {
            view.layer.shadowOffset = CGSize(width: 0, height: 0)
            view.layer.shadowOpacity = 1.0
            view.layer.shadowRadius = 3.0
            view.layer.shadowColor = UIColor.white.cgColor
        }
        
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
        userDBRef = FIRDatabase.database().reference().child("users")
        
        // Find current tracks storage URL
        self.currentTrackRef.observe(.value) { (snapShot: FIRDataSnapshot) in
            let snapVal = snapShot.value as? [String: Any]
            
            if let fileURL = snapVal?["fileURL"] as? String {
                self.trackStorageRef = FIRStorage.storage().reference(forURL: fileURL)
                
                // configure the track info view for when the audio preview is played
                let views = Bundle.main.loadNibNamed("TrackInfoView", owner: nil, options: nil)
                self.trackInfoView = views?[0] as! TrackInfoView
                let infoWidth = self.view.bounds.width * 0.75
                let infoHeight = infoWidth / 2
                self.trackInfoView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: infoWidth, height: infoHeight))
                
                if let title = snapVal?["title"] as? String {
                    self.trackInfoView.titleLabel.text = title
                }
                
                if let uid = snapVal?["user"] as? String {
                    let uidDBRef = self.userDBRef.child(uid)
                    
                    uidDBRef.observeSingleEvent(of: .value, with: { (snapShot) in
                        let snapVal = snapShot.value as? [String:Any]
                        
                        if let user = snapVal?["name"] as? String {
                            self.trackInfoView.userNameLabel.text = user
                        }
                        if let photoPath = snapVal?["photoPath"] as? String {
                            print(photoPath)
                            let ref = FIRStorage.storage().reference(withPath: "profilePics/\(uid)")
                            ref.data(withMaxSize: 5 * 1024 * 1024, completion: { (data, error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                    return
                                }
                                if let data = data {
                                    let imageView = self.trackInfoView.userProfPicImageView
                                    imageView!.image = UIImage(data: data)
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        topStack.isHidden = false
        bottomStack.isHidden = false
        
        for label in topStack.arrangedSubviews {
            label.isHidden = false
        }
        for label in bottomStack.arrangedSubviews {
            label.isHidden = false
        }
    }
    
    @IBAction func playPreviewButtonDown(_ sender: MenuButton) {
        print("button down")
        
        //TODO: Change test mp3 to daily mp3
        if downloadTask == nil {
            if let player = player {
                player.play()
                self.addInfoViewtoSuperView()
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
                            self.addInfoViewtoSuperView()
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
        
        for view in self.view.subviews {
            if view is TrackInfoView {
                removeInfoViewFromSuperView()
            }
        }
        
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
                        self.saveMusicFileLocallyAndSegue(dirUp: true)
                    } else {
                        self.bottomFirstLabel.isHidden = true
                        self.bottomSecondLabel.isHidden = true
                        self.topStack.isHidden = true
                        self.saveMusicFileLocallyAndSegue(dirUp: true)
                    }
                }
                
            })
            print(sender.location(in: self.view))
        case .failed, .cancelled:
            break
        }
    }
    
    func saveMusicFileLocallyAndSegue(dirUp: Bool) {
        guard trackStorageRef != nil else {
            print("found nil for track Storage ref")
            return
        }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let localURL = documentsDirectory.appendingPathComponent("RFATempAudio.mp3")
        
        
        trackStorageRef.write(toFile: localURL) { (url, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let url = url {
                self.beatURL = url
                self.performSegue(withIdentifier: "showStudio", sender: self)
                
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showStudio":
            let vc = segue.destination as! StudioViewController
            vc.beatURL = self.beatURL
            vc.genre = self.genre
        default:
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
    
    private func addInfoViewtoSuperView(){
        trackInfoView.alpha = 0.0
        self.view.addSubview(trackInfoView)
        trackInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        let width = self.view.bounds.width * 0.95
        trackInfoView.widthAnchor.constraint(equalToConstant: width).isActive = true
        trackInfoView.heightAnchor.constraint(equalToConstant: width / 2).isActive = true
        trackInfoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        trackInfoView.bottomAnchor.constraint(equalTo: playPreviewButton.topAnchor, constant: -20).isActive = true
        
        trackInfoView.layer.cornerRadius = 10.0
        trackInfoView.layer.borderWidth = 3.0
        trackInfoView.layer.borderColor = UIColor.white.cgColor
        
        UIView.animate(withDuration: 0.3) {
            self.trackInfoView.alpha = 0.75
        }
    }
    
    private func removeInfoViewFromSuperView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.trackInfoView.alpha = 0.0
        }) { (success) in
            if success {
                print("removing trackInfoView from superview")
                self.trackInfoView.removeFromSuperview()
            }
        }
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
