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
import WARangeSlider

class StudioViewController: UIViewController {
    
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var playButton: MenuButton!
    @IBOutlet weak var recordButton: MenuButton!
    
    // Popup views
    @IBOutlet var finalSongContainerView: UIView!
    @IBOutlet var finalSongCreateView: UIView!
    
    // Final Song Create View fields
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var enterTitleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    // Final Song Container View fields
    @IBOutlet weak var playOrPauseButton: UIButton!

    // Waveform views
    @IBOutlet weak var finalSongWaveformView: AKOutputWaveformPlot!
    @IBOutlet weak var beatBufferView: UIView!
    @IBOutlet weak var beatPlotView: AKNodeOutputPlot!
    @IBOutlet weak var recordedAudioPlotView: AKNodeOutputPlot!
    
    // Sliders for normalizing final beat and recording volumes
    @IBOutlet weak var soundBalanceSlider: UISlider!
    @IBOutlet weak var songRangeScrubber: RangeSlider!
    
    // Fading Labels
    @IBOutlet weak var fadeInTimeLabel: UILabel!
    @IBOutlet weak var fadeOutTimeLabel: UILabel!
    @IBOutlet weak var fadingStackView: UIStackView!
    @IBOutlet weak var fadeOutApplyButton: UIButton!
    @IBOutlet weak var fadeInApplyButton: UIButton!
    @IBOutlet weak var fadeInStepper: UIStepper!
    @IBOutlet weak var fadeOutStepper: UIStepper!
    
    
    // Final Container View editable constraints
    var heightCon: NSLayoutConstraint!
    
    // Final Containter View latch describing whether window is expanded or normal
    var isExpanded = false
    
    // Beat of the day Local URL
    var beatURL: URL!
    
    // AKAudioPlayer with beat
    private var player: AKAudioPlayer!
    private var playerCopy: AKMixer!
    private var passthroughPlayer: AKMixer!
    
    
    // Playback player and file
    var playbackPlayer: AKAudioPlayer!
    var beatPlaybackPlayer: AKAudioPlayer!
    var currentRecordingFile: AKAudioFile!
    var currentBeatRecordingFile: AKAudioFile!
    var finalMixer: AKMixer!
    
    // Node to record
    var recorder: AKNodeRecorder!
    var recordingNode: AKMixer!
    var beatRecorder: AKNodeRecorder!
    
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
    
    // File Destination URL
    var fileDestinationURL: URL!
    var finalPlayer: AVAudioPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButton.isHidden = true
        recordingButtonColor = recordButton.buttonColor
        playButton.isEnabled = false
        playButtonColor = playButton.buttonColor
        
        do {
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
            // Original file with the beat extracted from online database
            let file = try AKAudioFile(forReading: beatURL)
            
            // The audio player will be created from the beat and copied twice (each copy will perform a waveform analysis)
            player = try AKAudioPlayer(file: file, looping: true, completionHandler: nil)
            playerCopy = AKMixer(player)
            

            // For sending to final recorded version
            passthroughPlayer = AKMixer(playerCopy)
            
            
            // Now set up playback recorder for audio playback after recording
            currentRecordingFile = try AKAudioFile()
            currentBeatRecordingFile = try AKAudioFile()
            
            playbackPlayer = try AKAudioPlayer(file: currentRecordingFile, looping: true, completionHandler: {
                print("playback player has reached completion")
            })
            beatPlaybackPlayer = try AKAudioPlayer(file: currentBeatRecordingFile, looping: true, completionHandler: {
                print("beat player has reached completion")
            })
            
            finalMixer = AKMixer([playbackPlayer, beatPlaybackPlayer])
            
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
            
            
            recordedAudioPlot = AKNodeOutputPlot(player, frame: CGRect(origin: recordedAudioPlotView.frame.origin, size: waveformWindowSize))
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
        
        if !isRecording {
            do {
                player.play()
                recorder = try AKNodeRecorder(node: recordingNode, file: currentRecordingFile)
                beatRecorder = try AKNodeRecorder(node: passthroughPlayer, file: currentBeatRecordingFile)
                try recorder.record()
                try beatRecorder.record()
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
            beatRecorder.stop()
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
            finalSongContainerView.clipsToBounds = true
            finalSongContainerView.layer.masksToBounds = true
            
            // Configure AutoLayout constraints for containerview
            finalSongContainerView.translatesAutoresizingMaskIntoConstraints = false
            
            heightCon = self.finalSongContainerView.heightAnchor.constraint(equalToConstant: height)
            
            self.finalSongContainerView.widthAnchor.constraint(equalToConstant: width).isActive = true
            heightCon.isActive = true
            self.finalSongContainerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            self.finalSongContainerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            
            // Add the final song create view hidden behind the final song container view
            finalSongCreateView.frame = finalSongContainerView.frame
            finalSongCreateView.isHidden = true
            self.view.addSubview(finalSongCreateView)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.finalSongContainerView.transform = CGAffineTransform.identity
                self.finalSongContainerView.alpha = 1
                self.blurEffectView.alpha = 0.7
            }, completion: { (success) in
                
                do {
                    try self.playbackPlayer.reloadFile()
                    try self.beatPlaybackPlayer.reloadFile()
                } catch {
                    print("could not reload file")
                }
                
                if self.beatPlaybackPlayer.audioFile.duration > 0.0, self.playbackPlayer.audioFile.duration > 0.0 {
                    print("playback player sample count: \(self.playbackPlayer.audioFile.samplesCount)")
                    
                    let outputPlot = AKOutputWaveformPlot(frame: CGRect(origin: self.finalSongWaveformView.frame.origin, size: CGSize(width: self.finalSongWaveformView.bounds.width, height: self.finalSongWaveformView.bounds.height)))
                    outputPlot.setupPlot()
                    outputPlot.color = .white
                    outputPlot.layer.cornerRadius = 20.0
                    self.finalSongContainerView.addSubview(outputPlot)
                    
                    AudioKit.output = self.finalMixer
                    self.playbackPlayer.play()
                    self.beatPlaybackPlayer.play()
                    
                    // Configure UISlider/Range Slider properties
                    
                    self.songRangeScrubber.maximumValue = self.playbackPlayer.duration
                    print("duration is \(self.playbackPlayer.duration) seconds")
                    self.songRangeScrubber.minimumValue = 0.0
                    self.songRangeScrubber.lowerValue = 0.0
                    self.songRangeScrubber.upperValue = self.songRangeScrubber.maximumValue
                    self.soundBalanceSlider.maximumValue = 1.0
                    self.soundBalanceSlider.minimumValue = 0.0
                    self.soundBalanceSlider.value = 0.5
                    
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
    
    //MARK: Final Audio Bar Button Actions
    
    @IBAction func finalCancelButtonTapped(_ sender: UIButton) {
    }
    @IBAction func finalSaveButtonTapped(_ sender: UIButton) {
    }
    @IBAction func finalEditButtonTapped(_ sender: UIButton) {
        
        if isExpanded {
            heightCon.constant = heightCon.constant / 2.5
        } else {
            heightCon.constant = heightCon.constant * 2.5
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if self.isExpanded {
                self.songRangeScrubber.alpha = 0
                self.soundBalanceSlider.alpha = 0
                self.fadingStackView.alpha = 0
            } else {
                self.songRangeScrubber.alpha = 1
                self.soundBalanceSlider.alpha = 1
                self.fadingStackView.alpha = 1
            }
            
            self.view.layoutIfNeeded()
        }) { (success) in
            
            if self.isExpanded {
                self.isExpanded = false
            } else {
                self.isExpanded = true
            }
        }
        
    }
    @IBAction func finalPlayButtonTapped(_ sender: UIButton) {
    }
    @IBAction func finalConfirmButtonTapped(_ sender: UIButton) {
        
        let playbackVolume = playbackPlayer.volume
        let beatVolume = beatPlaybackPlayer.volume
        
        print("playback player sample count before stop: \(playbackPlayer.audioFile.samplesCount)")
        print("current recording file sample count: \(currentRecordingFile.samplesCount)")
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        //TODO: Configure the maxVolume for normalized tracks to match current volume
        do {
            let file1 = playbackPlayer.audioFile as AVAudioFile
            let file2 = beatPlaybackPlayer.audioFile as AVAudioFile
            
            let convFile1 = try AKAudioFile(forReading: file1.url)
            let convFile2 = try AKAudioFile(forReading: file2.url)
        
            print("playback player sample count before stop: \(playbackPlayer.audioFile.samplesCount)")
            print("playback player sample count before stop: \(beatPlaybackPlayer.audioFile.samplesCount)")
            print(convFile1.samplesCount)
            print(convFile2.samplesCount)
        
            let file1Normal = try convFile1.normalized(baseDir: .temp, name: UUID().uuidString, newMaxLevel: Float(playbackVolume)) as AVAudioFile
            let file2Normal = try convFile2.normalized(baseDir: .temp, name: UUID().uuidString, newMaxLevel: Float(beatVolume)) as AVAudioFile
 
            
            combineTracksAndPlay(first: file1Normal.url, second: file2Normal.url)
        } catch {
            print(error.localizedDescription)
        }
       
        if isExpanded {
            heightCon.constant = heightCon.constant / 2
            UIView.animate(withDuration: 0.3, animations: {
                self.songRangeScrubber.alpha = 0
                self.soundBalanceSlider.alpha = 0
                self.fadingStackView.alpha = 0
                self.view.layoutIfNeeded()
            }, completion: { (success) in
                self.flipViews(first: self.finalSongContainerView, second: self.finalSongCreateView)
            })
        } else {
            self.flipViews(first: self.finalSongContainerView, second: self.finalSongCreateView)
        }
    }
    
    //MARK: Final Create Audio Window Bar Buttons
    
    
    func flipViews(first:UIView, second: UIView) {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        
        UIView.transition(with: first, duration: 0.5, options: transitionOptions, animations: {
            first.isHidden = true
        }, completion: nil)
        
        UIView.transition(with: second, duration: 0.5, options: transitionOptions, animations: {
            second.isHidden = false
        }, completion: nil)
    }
    
    //MARK: Final UISlider Actions
    
    @IBAction func volumeBalanceSliderChanged(_ sender: UISlider) {
        let maxVol: Double = 2.0
        let recordingVol: Double = Double(sender.value)
        let beatVol: Double = 1.0 - recordingVol
        
        playbackPlayer.volume = maxVol * recordingVol
        beatPlaybackPlayer.volume = maxVol * beatVol
    }
    
    @IBAction func scrubberValueChanged(_ sender: RangeSlider) {
        
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        playbackPlayer.startTime = sender.lowerValue
        playbackPlayer.endTime = sender.upperValue
        
        beatPlaybackPlayer.startTime = sender.lowerValue
        beatPlaybackPlayer.endTime = sender.upperValue
        
        playbackPlayer.start()
        beatPlaybackPlayer.start()
 
    }
    
    //MARK: Final Stepper Actions
    
    @IBAction func fadeInStepperValueChanged(_ sender: UIStepper) {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: sender.value))
        
        fadeInTimeLabel.text = value! + " sec"
        
        fadeInApplyButton.isHidden = false
    }
    
    @IBAction func fadeOutStepperValueChanged(_ sender: UIStepper) {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: sender.value))
        
        fadeOutTimeLabel.text = value! + " sec"
        
        fadeOutApplyButton.isHidden = false
    }
    @IBAction func applyFadeIn(_ sender: UIButton) {
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        playbackPlayer.fadeInTime = fadeInStepper.value
        beatPlaybackPlayer.fadeInTime = fadeInStepper.value
        
        playbackPlayer.start()
        beatPlaybackPlayer.start()
        sender.isHidden = true
    }
    
    @IBAction func applyFadeOut(_ sender: UIButton) {
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        playbackPlayer.fadeOutTime = fadeOutStepper.value
        beatPlaybackPlayer.fadeOutTime = fadeOutStepper.value
        
        
        playbackPlayer.start()
        beatPlaybackPlayer.start()
        sender.isHidden = true
    }
    
    //MARK: Combine Tracks
    
    func combineTracksAndPlay(first: URL, second: URL) {
        let composition = AVMutableComposition()
        let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        self.fileDestinationURL = documentDirectoryURL.appendingPathComponent("resultmerge.m4a")! as URL
        
        let filemanager = FileManager.default
        if (!filemanager.fileExists(atPath: self.fileDestinationURL.path))
        {
            do
            {
                try filemanager.removeItem(at: self.fileDestinationURL)
            }
            catch let error
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            do
            {
                try filemanager.removeItem(at: self.fileDestinationURL)
            }
            catch let error
            {
                print(error.localizedDescription)
            }
        }
        let url1 = first
        let url2 = second
        
        let avAsset1 = AVURLAsset(url: url1 as URL, options: nil)
        let avAsset2 = AVURLAsset(url: url2 as URL, options: nil)
        
        var tracks1 = avAsset1.tracks(withMediaType: AVMediaTypeAudio)
        var tracks2 = avAsset2.tracks(withMediaType: AVMediaTypeAudio)
        
        let assetTrack1:AVAssetTrack = tracks1[0]
        let assetTrack2:AVAssetTrack = tracks2[0]
        
        let duration1: CMTime = assetTrack1.timeRange.duration
        let duration2: CMTime = assetTrack2.timeRange.duration
        
        let timeRange1 = CMTimeRangeMake(kCMTimeZero, duration1)
        let timeRange2 = CMTimeRangeMake(kCMTimeZero, duration2)
        do
        {
            try compositionAudioTrack1.insertTimeRange(timeRange1, of: assetTrack1, at: kCMTimeZero)
            try compositionAudioTrack2.insertTimeRange(timeRange2, of: assetTrack2, at: kCMTimeZero)
        }
        catch
        {
            print(error)
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputFileType = AVFileTypeAppleM4A
        assetExport?.outputURL = fileDestinationURL
        assetExport?.exportAsynchronously(completionHandler:
            {
                switch assetExport!.status
                {
                case AVAssetExportSessionStatus.failed:
                    print("failed \(assetExport!.error)")
                case AVAssetExportSessionStatus.cancelled:
                    print("cancelled \(assetExport!.error)")
                case AVAssetExportSessionStatus.unknown:
                    print("unknown\(assetExport!.error)")
                case AVAssetExportSessionStatus.waiting:
                    print("waiting\(assetExport!.error)")
                case AVAssetExportSessionStatus.exporting:
                    print("exporting\(assetExport!.error)")
                default:
                    print("complete")
                }
                
                do
                {
                    //TODO: Switch to AKAudioPlayer to allow for fading
                    self.finalPlayer = try AVAudioPlayer(contentsOf: self.fileDestinationURL)
                    self.finalPlayer?.numberOfLoops = -1
                    self.finalPlayer?.prepareToPlay()
                    self.finalPlayer?.volume = 1.0
                    self.finalPlayer?.play()
                }
                catch let error as NSError
                {
                    print(error)
                }
        })
        
        
        
    }
    
    //MARK: Custom functions derived from broken AudioKit functions
    
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
