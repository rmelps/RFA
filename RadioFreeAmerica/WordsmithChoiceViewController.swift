//
//  WordsmithChoiceViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/5/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Add Pan Gesture Recognizer to view
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WordsmithChoiceViewController.handlePan(_:)))
        panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(panGestureRecognizer)

       
    }
    
    @IBAction func playPreview(_ sender: MenuButton) {
        
    }
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
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
