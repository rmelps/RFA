//
//  StudioViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 7/11/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import AudioKit
import AVFoundation

class StudioViewController: UIViewController {
    
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var playButton: MenuButton!
    @IBOutlet weak var recordButton: MenuButton!
    @IBOutlet var finalSongContainerView: UIView!
    @IBOutlet weak var finalSongWaveformView: AKOutputWaveformPlot!
    @IBOutlet weak var beatBufferView: UIView!
    @IBOutlet weak var beatPlotView: AKNodeOutputPlot!
    @IBOutlet weak var recordedAudioPlotView: AKNodeOutputPlot!
    
    //finalSongContainerView layout constraints
    var topCon: NSLayoutConstraint!
    
    // Beat of the day Local URL
    var beatURL: URL!
    
    // AKAudioPlayer with beat
    private var player: AKAudioPlayer!
    private var playerCopy: AKMixer!
    private var passthroughPlayer: AKMixer!
    
    
    // Playback player and file
    var playbackPlayer: AKAudioPlayer!
    var currentRecordingFile: AKAudioFile!
    
    // Node to record
    var recorder: AKNodeRecorder!
    var recordingNode: AKMixer!
    
    // AKNodeOutputPlots
    var recordedAudioPlot: AKNodeOutputPlot!
    var beatPlot: AKNodeOutputPlot!
    var micPlot: AKNodeOutputPlot!
    
    //Recording session variables
    let session = AVAudioSession.sharedInstance()
    
    // Microphone from AudioKit inputs
    var microphone: AKMicrophone!
    var micCopy: AKBooster!
    
    // Boolean set when currently recording or previewing
    var isRecording = false
    var isPlaying = false
    
    // Original Button colors
    private var recordingButtonColor: UIColor!
    private var playButtonColor: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        recordButton.isHidden = true
        recordingButtonColor = recordButton.buttonColor
        playButton.isEnabled = false
        playButtonColor = playButton.buttonColor
        
        do {
            //try AKSettings.setSession(category: .playAndRecord, with: [.defaultToSpeaker, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeDefault, options: .defaultToSpeaker)
            AKSettings.bufferLength = .medium
            
            
            session.requestRecordPermission({ (allowed) in
                if allowed {
 
                    let inputDevices = self.setAKInputDevices()
                    
                    if let inputs = inputDevices {
                        do {
                            self.microphone = AKMicrophone()
                            
                            for input in inputs {
                                if input.deviceID.contains("Front") {
                                    try self.setAKMicrophoneDevice(input: input)
                                }
                            }
                            
                            self.micCopy = AKBooster(self.microphone)
                            self.micCopy.gain = 2.0
                            
                            self.recordingNode = AKMixer([self.micCopy])
                            
                            self.configureNodes()
                            
                        } catch let error {
                            print("could not access input devices: \(error.localizedDescription)")
                        }
                        
                    } else {
                        print("no input devices found")
                    }
                    
                } else {
                    print("recording not allowed")
                }
            })
        } catch let error {
            print("recording session error: \(error.localizedDescription)")
        }
        
        // Format the final song container view
        finalSongContainerView.layer.cornerRadius = 10.0
        finalSongContainerView.layer.borderColor = UIColor.white.cgColor
        finalSongContainerView.layer.borderWidth = 3.0
        finalSongContainerView.alpha = 0
        finalSongContainerView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
    }
    
    func configureNodes() {
        
        recordButton.isHidden = false
        
        do {
            let file = try AKAudioFile(forReading: beatURL)
            player = try AKAudioPlayer(file: file, looping: true, completionHandler: nil)
            playerCopy = AKMixer(player)
            passthroughPlayer = AKMixer(playerCopy)
            
            
            recordingNode.connect(player)
            
            // Now set up playback recorder for audio playback after recording
            currentRecordingFile = try AKAudioFile()
            playbackPlayer = try AKAudioPlayer(file: currentRecordingFile)
            
        } catch let error {
            fatalError("Could not read beat URL at \(beatURL): \(error.localizedDescription)")
        }
        
        
        if let playerCopy = playerCopy {
            
            let waveformWindowSize = CGSize(width: self.view.frame.width, height: self.view.frame.height / 6)
            
            print(beatPlotView.frame)
            beatPlot = AKNodeOutputPlot(playerCopy, frame: CGRect(origin: beatPlotView.frame.origin, size: waveformWindowSize))
            beatPlot.plotType = .buffer
            beatPlot.shouldFill = true
            beatPlot.backgroundColor = .clear
            beatPlot.shouldMirror = true
            beatPlot.color = .yellow
            
            
            recordedAudioPlot = AKNodeOutputPlot(passthroughPlayer, frame: CGRect(origin: recordedAudioPlotView.frame.origin, size: waveformWindowSize))
            recordedAudioPlot.plotType = .rolling
            recordedAudioPlot.shouldFill = true
            recordedAudioPlot.backgroundColor = .clear
            recordedAudioPlot.shouldMirror = true
            recordedAudioPlot.color = .red
            
            if let micCopy = micCopy {
                
                
                let micPlot = AKNodeOutputPlot(micCopy, frame: CGRect(origin: beatBufferView.frame.origin, size: waveformWindowSize))
                micPlot.plotType = .rolling
                micPlot.shouldFill = true
                micPlot.backgroundColor = .clear
                micPlot.shouldMirror = true
                micPlot.color = .blue
                
                self.view.addSubview(micPlot)
            }
            
            self.view.addSubview(recordedAudioPlot)
            self.view.addSubview(beatPlot)
            
        }
        
        
        AudioKit.output = passthroughPlayer
        AudioKit.start()
        playButton.isEnabled = true
        player.play()
        
        let stopImage = UIImage(named: "stop")
        playButton.setImage(stopImage, for: .normal)
        isPlaying = true
        recordButton.isEnabled = false
        recordButton.buttonColor = .lightGray
        
        
        if !AKSettings.headPhonesPlugged {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch {
                print("could not override speaker")
            }
        }
    }
    @IBAction func recordButtonTapped(_ sender: MenuButton) {
        
        //TODO: Make far more sophisticated playback mechanism
        
        if !isRecording {
            do {
                player.play()
                recorder = try AKNodeRecorder(node: recordingNode, file: currentRecordingFile)
                try recorder.record()
                isRecording = true
                playButton.isEnabled = false
                playButton.buttonColor = .lightGray
                
                let stopImage = UIImage(named: "stop")
                sender.setImage(stopImage, for: .normal)
            } catch {
                print("error loading node recorder")
            }
        } else {
            recorder.stop()
            player.stop()
            playButton.buttonColor = playButtonColor
            playButton.isEnabled = true
            isRecording = false
            
            let height = self.view.bounds.height / 3
            let width = self.view.bounds.width * 0.9
            let origin = CGPoint(x: 15, y: -(height + 50))
            let containerFrame = CGRect(origin: origin, size: CGSize(width: width, height: height))
            finalSongContainerView.frame = containerFrame
            finalSongContainerView.center = self.view.center
            
            self.view.bringSubview(toFront: blurEffectView)
            self.view.addSubview(finalSongContainerView)
            
            // Configure AutoLayout constraints for containerview
            finalSongContainerView.translatesAutoresizingMaskIntoConstraints = false
            self.finalSongContainerView.widthAnchor.constraint(equalToConstant: width).isActive = true
            self.finalSongContainerView.heightAnchor.constraint(equalToConstant: height).isActive = true
            self.finalSongContainerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            self.finalSongContainerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            
            UIView.animate(withDuration: 0.2, animations: {
                self.finalSongContainerView.transform = CGAffineTransform.identity
                self.finalSongContainerView.alpha = 1
                self.blurEffectView.alpha = 1
            }, completion: { (success) in
                
                
                
                do {
                    try self.playbackPlayer.reloadFile()
                } catch {
                    print("could not reload file")
                }
                
                if self.playbackPlayer.audioFile.duration > 0.0 {
                    
                    let outputPlot = AKOutputWaveformPlot(frame: CGRect(origin: self.finalSongWaveformView.frame.origin, size: CGSize(width: self.finalSongWaveformView.bounds.width, height: self.finalSongWaveformView.bounds.height)))
                    outputPlot.setupPlot()
                    outputPlot.color = .white
                    outputPlot.layer.cornerRadius = 20.0
                    self.finalSongContainerView.addSubview(outputPlot)
                    
                    AudioKit.output = self.playbackPlayer
                    self.playbackPlayer.play()
                }
            })
            
            let recordImage = UIImage(named: "record")
            sender.setImage(recordImage, for: .normal)
        }
        
    }
    @IBAction func playButtonTapped(_ sender: MenuButton) {
        if !isPlaying {
            player.play()
            let stopImage = UIImage(named: "stop")
            sender.setImage(stopImage, for: .normal)
            isPlaying = true
            recordButton.isEnabled = false
            recordButton.buttonColor = .lightGray
        } else {
            player.stop()
            let playImage = UIImage(named: "right")
            sender.setImage(playImage, for: .normal)
            isPlaying = false
            recordButton.isEnabled = true
            recordButton.buttonColor = recordingButtonColor
        }
    }
    
    
    func createMicWaveform() {
        
        micCopy = AKBooster(microphone)
        
        let micPlot = AKNodeOutputPlot(micCopy, frame: recordedAudioPlotView.frame)
        micPlot.plotType = .buffer
        micPlot.shouldFill = true
        micPlot.backgroundColor = .clear
        micPlot.shouldMirror = true
        micPlot.color = .yellow
        
       self.view.addSubview(micPlot)
    }
    
    func setAKInputDevices() -> [AKDevice]? {
        
        
        var returnDevices = [AKDevice]()
        if let devices = session.availableInputs {
            for device in devices {
                
                if device.dataSources == nil {
                    returnDevices.append(AKDevice(name: device.portName, deviceID: device.uid))
                } else {
                    for dataSource in device.dataSources! {
                        returnDevices.append(AKDevice(name: device.portName,
                                                      deviceID: "\(device.uid) \(dataSource.dataSourceName)"))
                    }
                }
            }
            return returnDevices
        }
        return nil
        
    }
    
    func setAKMicrophoneDevice(input: AKDevice) throws {
        if let devices = AVAudioSession.sharedInstance().availableInputs {
            for device in devices {
                if device.dataSources == nil {
                    if device.uid == input.deviceID {
                        do {
                            try AVAudioSession.sharedInstance().setPreferredInput(device)
                        } catch {
                            AKLog("Could not set the preferred input to \(input)")
                        }
                    }
                } else {
                    for dataSource in device.dataSources! {
                        if input.deviceID == "\(device.uid) \(dataSource.dataSourceName)" {
                            do {
                                try AVAudioSession.sharedInstance().setPreferredInput(device)
                                try AVAudioSession.sharedInstance().setInputDataSource(dataSource)
                                try dataSource.setPreferredPolarPattern(AVAudioSessionPolarPatternCardioid)
                                print("set preferred input to \(device)")
                                print("set inputdatasource to \(dataSource)")
                            } catch {
                                AKLog("Could not set the preferred input to \(input)")
                            }
                        }
                    }
                }
            }
        }
    }

}
