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
import FirebaseDatabase
import FirebaseStorage

enum ViewFlipType {
    case toCreate
    case toContainer
}

class StudioViewController: UIViewController {
    
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var playButton: MenuButton!
    @IBOutlet weak var recordButton: MenuButton!
    
    // Popup views
    @IBOutlet var finalSongContainerView: UIView!
    @IBOutlet var finalSongCreateView: UIView!
    var finalOutputPlot: AKOutputWaveformPlot!
    let popUpViewTransformScale: CGFloat = 1.5
    
    // Final Song Create View fields
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var confirmAndUploadButton: UIButton!
    @IBOutlet weak var enterTitleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    var textViewDelegate = StudioTextViewDelegate()
    var textFieldDelegate = StudioTextFieldDelegate()
    
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
    let maxVol: Double = 2.0
    
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
    
    // Chosen genre for upload
    var genre: GenreChoices!
    
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
    var finalPlayer: AKAudioPlayer!
    
    
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
                            //self.micCopy.gain = 2.0
                            
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
        
        
        // Format the final song create view and subcomponents
        descriptionTextView.layer.borderColor = UIColor.white.cgColor
        descriptionTextView.layer.borderWidth = 3.0
        descriptionTextView.layer.cornerRadius = 10.0
        
        // Set Final song Create view text field delegates
        descriptionTextView.delegate = textViewDelegate
        enterTitleTextField.delegate = textFieldDelegate
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
            
            // Moving configuration of recorders
            recorder = try AKNodeRecorder(node: recordingNode, file: currentRecordingFile)
            beatRecorder = try AKNodeRecorder(node: passthroughPlayer, file: currentBeatRecordingFile)
            
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
        
        // Setup final output plot for final song container view
        
        self.finalOutputPlot = AKOutputWaveformPlot(frame: CGRect(origin: self.finalSongWaveformView.frame.origin, size: CGSize(width: self.finalSongWaveformView.bounds.width, height: self.finalSongWaveformView.bounds.height)))
        self.finalOutputPlot.setupPlot()
        self.finalOutputPlot.color = .white
        self.finalOutputPlot.layer.cornerRadius = 20.0
        self.finalSongContainerView.addSubview(self.finalOutputPlot)
        
        
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
                let date0 = Date()
                
                try recorder.record()
                let date1 = Date()
                print("recording started at: \(date1)")
                try beatRecorder.record()
                let date2 = Date()
                print("beat recording started at: \(date2)")
                let difference = DateInterval(start: date0, end: date2)
                print(difference.duration)
                
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
            
            self.view.bringSubview(toFront: blurEffectView)
            
            let height = self.view.bounds.height / 3
            let width = self.view.bounds.width * 0.9
            let origin = CGPoint(x: 15, y: -(height + 50))
            let containerFrame = CGRect(origin: origin, size: CGSize(width: width, height: height))
            
            finalSongContainerView.frame = containerFrame
            finalSongContainerView.center = self.view.center
            
            self.view.addSubview(finalSongContainerView)
            finalSongContainerView.clipsToBounds = true
            finalSongContainerView.layer.masksToBounds = true
            
            
            finalSongContainerView.transform = CGAffineTransform(scaleX: popUpViewTransformScale, y: popUpViewTransformScale)
            
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
            print("FINAL SONG CONTAINER VIEW CONSTRAINT COUNT: \(finalSongContainerView.constraints.count)")
            
            UIView.animate(withDuration: 0.2, animations: {
                self.finalSongContainerView.transform = CGAffineTransform.identity
                self.finalSongContainerView.alpha = 1
                self.blurEffectView.alpha = 0.7
            }, completion: { (success) in
                let activityView = ActivityIndicatorView(withProgress: false)
                self.view.addSubview(activityView)
                
                do {
                    try self.playbackPlayer.reloadFile()
                    try self.beatPlaybackPlayer.reloadFile()
                } catch {
                    print("could not reload file")
                }
                
                if self.beatPlaybackPlayer.audioFile.duration > 0.0, self.playbackPlayer.audioFile.duration > 0.0 {
                    print("playback player sample count: \(self.playbackPlayer.audioFile.samplesCount)")
                    
                    AudioKit.output = self.finalMixer
                    self.playbackPlayer.play(from: 0.0, to: self.playbackPlayer.audioFile.duration)
                    self.beatPlaybackPlayer.play(from: 0.0, to: self.playbackPlayer.audioFile.duration)
                    
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
                activityView.removeFromSuperview()
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
        //TODO: Figure out why sound gets louder after cancelling once
        
        if playbackPlayer.isPlaying {
            self.playbackPlayer.stop()
            self.beatPlaybackPlayer.stop()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.finalSongContainerView.transform = CGAffineTransform(scaleX: self.popUpViewTransformScale, y: self.popUpViewTransformScale)
            self.blurEffectView.alpha = 0
            self.finalSongContainerView.alpha = 0
        }) { (success) in
            do {
                self.finalSongContainerView.removeFromSuperview()
                
                // When removing the final Song Containter View from the superview, the height and width constraints on this view remain. Ifi I do not remove them manually (like below) they will remain when the view is readded to the superview, and I will not be able to expanded or retract the view.
                
                for constraint in self.finalSongContainerView.constraints {
                    if let con = constraint.firstItem as? UIView, let id = con.accessibilityIdentifier {
                        if id == "fscontview", constraint.secondItem == nil {
                            self.finalSongContainerView.removeConstraint(constraint)
                        }
                    }
                }
                if self.isExpanded {
                    self.songRangeScrubber.alpha = 0
                    self.soundBalanceSlider.alpha = 0
                    self.fadingStackView.alpha = 0
                    self.isExpanded = false
                }
                
                // Reset Technician Screen parameters to default values
                self.fadeInStepper.value = 0.0
                self.fadeOutStepper.value = 0.0
                self.fadeInStepperValueChanged(self.fadeInStepper)
                self.fadeOutStepperValueChanged(self.fadeOutStepper)
                self.playbackPlayer.fadeInTime = self.fadeInStepper.value
                self.beatPlaybackPlayer.fadeInTime = self.fadeInStepper.value
                self.playbackPlayer.fadeOutTime = self.fadeOutStepper.value
                self.beatPlaybackPlayer.fadeOutTime = self.fadeOutStepper.value
                self.fadeInApplyButton.isHidden = true
                self.fadeOutApplyButton.isHidden = true
                
                // Remove fading
                
                try self.recorder.reset()
                try self.beatRecorder.reset()
                AudioKit.output = self.playbackPlayer
                AudioKit.engine.inputNode!.removeTap(onBus: 0)
            } catch {
                print("Error reseting recordings:\(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func finalGoBackButtonTapped(_ sender: UIButton) {
        // Stop the final compiled song from playing, delete the compiled song saved in the documents directory, and return to the finalSongContainerView
        
        //TODO: Find out why sometimes the beat and recording starting times are offset
        
        if finalPlayer != nil {
            finalPlayer.stop()
        }
        if fileDestinationURL != nil {
            do {
                try FileManager.default.removeItem(at: fileDestinationURL)
            } catch {
                print("could not remove compiled song: \(error.localizedDescription)")
            }
        }
        
        playbackPlayer.play(from: songRangeScrubber.lowerValue, to: songRangeScrubber.upperValue)
        beatPlaybackPlayer.play(from: songRangeScrubber.lowerValue, to: songRangeScrubber.upperValue)
        
        for constraint in finalSongCreateView.constraints {
            if let id = constraint.identifier, id == "height" {
                constraint.constant = heightCon.constant
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (success) in
                    self.flipViews(type: .toContainer)
                })
                break
            }
        }
        
        
    }
    
    @IBAction func finalSaveButtonTapped(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.signedInUser!
        
        finalPlayer.stop()
        
        //TODO: Improve text field checks before saving track. Also add ability to save track description. Need to update filePath on successful save
        
        let saveLocation = SavedTrackManager.trackArchiveAudioDirectoryURL
        
        guard let text = enterTitleTextField.text, !text.isEmpty else {
            AppDelegate.presentErrorAlert(withMessage: "Enter a Title", fromViewController: self)
            return
        }
        
        guard !FileManager.default.fileExists(atPath: saveLocation.appendingPathComponent(fileDestinationURL.lastPathComponent).path) else {
            AppDelegate.presentErrorAlert(withMessage: "This track is already saved", fromViewController: self)
            return
        }
        
        let newTrack = Track(user: user.uid,
                             title: enterTitleTextField.text!,
                             details: descriptionTextView.text,
                             uploadTime: String(describing: Date()),
                             fileURL: fileDestinationURL.lastPathComponent,
                             fadeInTime: String(fadeInStepper.value),
                             fadeOutTime: String(fadeOutStepper.value))
        
        if SavedTrackManager.saveNewTrack(newTrack: newTrack, tempLocation: fileDestinationURL) {
            print("Saved successfully!")
            let infoData = FileManager.default.contents(atPath: SavedTrackManager.trackArchiveInfoURL.path)
            let audioData = try! FileManager.default.contentsOfDirectory(atPath: SavedTrackManager.trackArchiveAudioDirectoryURL.path)
            print("info path: \(infoData!)")
            print("audio data:\(audioData)")
            
            let alert = UIAlertController(title: "Saved!", message: "\"\(newTrack.title)\" has been saved!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Nice", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            
        } else {
            
        }
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
        if playbackPlayer.isPlaying {
            playbackPlayer.stop()
            beatPlaybackPlayer.stop()
            sender.setImage(UIImage(named: "right"), for: .normal)
        } else {
            playbackPlayer.start()
            beatPlaybackPlayer.start()
            sender.setImage(UIImage(named: "stop"), for: .normal)
        }
    }
    @IBAction func finalConfirmButtonTapped(_ sender: UIButton) {
        
        print("playback player sample count before stop: \(playbackPlayer.audioFile.samplesCount)")
        print("current recording file sample count: \(currentRecordingFile.samplesCount)")
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        //TODO: Configure the maxVolume for normalized tracks to match current volume better
        do {
            let file1 = playbackPlayer.audioFile as AVAudioFile
            let file2 = beatPlaybackPlayer.audioFile as AVAudioFile
            
            let convFile1 = try AKAudioFile(forReading: file1.url)
            let convFile2 = try AKAudioFile(forReading: file2.url)
        
            print("playback player sample count before stop: \(playbackPlayer.audioFile.samplesCount)")
            print("playback player sample count before stop: \(beatPlaybackPlayer.audioFile.samplesCount)")
            print(convFile1.samplesCount)
            print(convFile2.samplesCount)
            
            // We need to figure out the maximum amount of gain we want for a given file, and then grab the ratio of gain between files based on current volume choice. The scale factor should be adjusted based on empirical evidence, if things don't appear correct after normalization, change the factor
            let scaleFactor: Double = 1.5
            let voiceToBeatDiff = Float((playbackPlayer.volume - beatPlaybackPlayer.volume) * scaleFactor)
            
            // Add activity indicator to show that song is loading. disable the view from user interaction until this has completed
            let activityIndicatorView = ActivityIndicatorView(withProgress: false)
            self.view.addSubview(activityIndicatorView)
            
            // Adding asynchronous normalization so that program does not freeze
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let file1Normal = try convFile1.normalized(baseDir: .temp, name: UUID().uuidString, newMaxLevel: voiceToBeatDiff) as AVAudioFile
                    let file2Normal = try convFile2.normalized(baseDir: .temp, name: UUID().uuidString, newMaxLevel: -voiceToBeatDiff) as AVAudioFile
                    DispatchQueue.main.async {
                        self.combineTracksAndPlay(first: file1Normal.url, second: file2Normal.url)
                        activityIndicatorView.removeFromSuperview()
                        if self.isExpanded {
                            self.heightCon.constant = self.heightCon.constant / 2.5
                            UIView.animate(withDuration: 0.3, animations: {
                                self.songRangeScrubber.alpha = 0
                                self.soundBalanceSlider.alpha = 0
                                self.fadingStackView.alpha = 0
                                self.view.layoutIfNeeded()
                            }, completion: { (success) in
                                self.flipViews(type: .toCreate)
                            })
                        } else {
                            self.flipViews(type: .toCreate)
                        }
                    }
                } catch {
                    activityIndicatorView.removeFromSuperview()
                    print("error in async process: \(error.localizedDescription)")
                }
                
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: Final Create Audio Window Bar Buttons
    
    @IBAction func confirmAndUploadTrackButtonTapped(_ sender: UIButton) {
        
        guard let title = enterTitleTextField.text, !title.isEmpty else {
            let message = "Enter a title before uploading!"
            print(message)
            AppDelegate.presentErrorAlert(withMessage: message, fromViewController: self)
            return
        }
        let activityIndicatorView = ActivityIndicatorView(withProgress: true)
        self.view.addSubview(activityIndicatorView)
        
        let user = (UIApplication.shared.delegate as! AppDelegate).signedInUser!
        
        // Point to the destination where did upload will be stored in the database
        let uploadDBRef = FIRDatabase.database().reference(withPath: "feed/\(genre.rawValue.lowercased())").childByAutoId()
        
        // Point to the destination where the audio file will be stored in FIRStorage
        let uploadStorageRef = FIRStorage.storage().reference(withPath: "uploads/\(user.uid!)/\(uploadDBRef.key).m4a")
        
        // First, we need to grab the final combined track as a data object to prepare for upload
        var data = Data()
        
        do {
            data = try Data(contentsOf: self.fileDestinationURL)
        } catch let error {
            print("Could not cast audio track as data: \(error.localizedDescription)")
            activityIndicatorView.removeFromSuperview()
            return
        }
        
        // Then, we will upload this data to FIRStorage, and upon completion, grab the download URL, and write data to the database pointing to this uploaded audio track
        let uploadTask = uploadStorageRef.put(data, metadata: nil) { (meta, error) in
            guard let meta = meta else {
                let message = "Could not retrieve metadata...aborting upload task"
                print(message)
                AppDelegate.presentErrorAlert(withMessage: message, fromViewController: self)
                activityIndicatorView.removeFromSuperview()
                return
            }
            if let error = error {
                let message = "uploadError: \(error.localizedDescription)"
                print(message)
                AppDelegate.presentErrorAlert(withMessage: message, fromViewController: self)
                activityIndicatorView.removeFromSuperview()
                return
            }
            
            if let downloadURL = meta.downloadURL() {
                let track = Track(user: user.uid,
                                  title: title,
                                  details: self.descriptionTextView.text,
                                  uploadTime: String(describing: Date()),
                                  fileURL: String(describing: downloadURL),
                                  fadeInTime: String(self.fadeInStepper.value),
                                  fadeOutTime: String(self.fadeOutStepper.value))
                uploadDBRef.setValue(track.toAny(), withCompletionBlock: { (error, reference) in
                    if let error = error {
                        let message = "error uploading track to database: \(error.localizedDescription)"
                        print(message)
                        AppDelegate.presentErrorAlert(withMessage: message, fromViewController: self)
                        activityIndicatorView.removeFromSuperview()
                        return
                    }
                    if let rootVC = self.presentingViewController as? WordsmithPageViewController {
                        rootVC.setViewControllers([rootVC.orderedViewControllers[2]], direction: .forward, animated: false, completion: nil)
                    }
                    activityIndicatorView.removeFromSuperview()
                    self.finalPlayer.stop()

                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                let message = "Could not access download URL: \(error?.localizedDescription)"
                print(message)
                AppDelegate.presentErrorAlert(withMessage: message, fromViewController: self)
                activityIndicatorView.removeFromSuperview()
                return
            }
        }
        
        uploadTask.observe(.progress) { (taskSnapshot) in
            
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            formatter.minimumIntegerDigits = 1
            formatter.numberStyle = .percent
            if let progress = taskSnapshot.progress {
                let fraction = progress.fractionCompleted
                print("fraction completed: \(progress.fractionCompleted)")
                
                if let string = formatter.string(from: NSNumber(value: fraction)) {
                    activityIndicatorView.progressLabel!.text = string
                }
            }
            
            
        }
    }
    
    func flipViews(type: ViewFlipType) {
        var first = UIView()
        var second = UIView()
        var direction = UIViewAnimationOptions()
        
        switch type {
        case .toCreate:
            first = self.finalSongContainerView
            second = self.finalSongCreateView
            second.frame = first.frame
            direction = .transitionFlipFromRight
        case .toContainer:
            first = self.finalSongCreateView
            second = self.finalSongContainerView
            first.frame = second.frame
            direction = .transitionFlipFromLeft
        }
        
        let transitionOptions: UIViewAnimationOptions = [direction, .showHideTransitionViews]
        
        UIView.transition(with: first, duration: 0.5, options: transitionOptions, animations: {
            first.isHidden = true
        }, completion: nil)
    
        UIView.transition(with: second, duration: 0.5, options: transitionOptions, animations: {
            second.isHidden = false
        }) { (success) in
            
            let identifiers: [String] = ["height", "width", "centerY", "centerX"]
            
            if success, type == .toCreate {
                
                // Configure AutoLayout constraints for createview
                second.translatesAutoresizingMaskIntoConstraints = false
                //second.removeConstraints(second.constraints)
                
                var alreadyConstrained = false
                for constraint in self.finalSongCreateView.constraints {
                    if let id = constraint.identifier {
                        if identifiers.contains(id) {
                            alreadyConstrained = true
                            break
                        }
                    }
                }
                
                var constraints = [NSLayoutConstraint]()
                
                let heightConstraint = second.heightAnchor.constraint(equalToConstant: self.heightCon.constant * 2.5)
                let widthContraint = second.widthAnchor.constraint(equalToConstant: first.frame.width)
                let centerYConstraint = second.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
                let centerXConstraint = second.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
                
                if !alreadyConstrained {
                    constraints = [heightConstraint, widthContraint, centerYConstraint, centerXConstraint]
                    if identifiers.count == constraints.count {
                        for (index, constraint) in constraints.enumerated() {
                            
                            constraint.identifier = identifiers[index]
                            constraint.isActive = true
                        }
                    }
                } else {
                    heightConstraint.identifier = identifiers[0]
                    heightConstraint.isActive = true
                }
                
                
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (success) in
                    self.isExpanded = true
                })
            }
            if success, type == .toContainer {
                self.isExpanded = false
                
                for constraint in self.finalSongCreateView.constraints {
                    if let id = constraint.identifier, id == identifiers[0] {
                        self.finalSongCreateView.removeConstraint(constraint)
                    }
                }
                first.frame = second.frame
            }
        }
    }
    
    //MARK: Final UISlider Actions
    
    @IBAction func volumeBalanceSliderChanged(_ sender: UISlider) {
        let recordingVol: Double = Double(sender.value)
        let beatVol: Double = 1.0 - recordingVol
        
        playbackPlayer.volume = self.maxVol * recordingVol
        beatPlaybackPlayer.volume = self.maxVol * beatVol
    }
   
    @IBAction func scrubberDidTouchUp(_ sender: RangeSlider) {
        
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        playbackPlayer.startTime = sender.lowerValue
        playbackPlayer.endTime = sender.upperValue
        
        beatPlaybackPlayer.startTime = sender.lowerValue
        beatPlaybackPlayer.endTime = sender.upperValue
        
        playbackPlayer.start()
        beatPlaybackPlayer.start()
        
        playOrPauseButton.setImage(UIImage(named: "stop"), for: .normal)
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
        
        playOrPauseButton.setImage(UIImage(named: "stop"), for: .normal)
    }
    
    @IBAction func applyFadeOut(_ sender: UIButton) {
        playbackPlayer.stop()
        beatPlaybackPlayer.stop()
        
        playbackPlayer.fadeOutTime = fadeOutStepper.value
        beatPlaybackPlayer.fadeOutTime = fadeOutStepper.value
        
        
        playbackPlayer.start()
        beatPlaybackPlayer.start()
        sender.isHidden = true
        
        playOrPauseButton.setImage(UIImage(named: "stop"), for: .normal)
    }
    
    //MARK: Combine Tracks
    
    func combineTracksAndPlay(first: URL, second: URL) {
        
        let composition = AVMutableComposition()
        let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        self.fileDestinationURL = documentDirectoryURL.appendingPathComponent("\(UUID().uuidString).m4a")! as URL
        
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
 
        //TODO: Improve cropping accuracy
        let sampleRate: Double = 44100
        let diff = Int64((songRangeScrubber.upperValue - songRangeScrubber.lowerValue) * sampleRate)
        
        let value = CMTimeValue.init(songRangeScrubber.lowerValue)
        let startTime: CMTime = CMTimeMake(value * Int64(sampleRate), Int32(sampleRate))
        let dur1: CMTime = CMTimeMake(diff, Int32(sampleRate))
        let dur2: CMTime = CMTimeMake(diff, Int32(sampleRate))
        
        print("start time: \(startTime), dur1: \(dur1)")
        
        let timeRange1 = CMTimeRangeMake(startTime, dur1)
        let timeRange2 = CMTimeRangeMake(startTime, dur2)
        do
        {
            try compositionAudioTrack1.insertTimeRange(timeRange1, of: assetTrack1, at: kCMTimeZero)
            try compositionAudioTrack2.insertTimeRange(timeRange2, of: assetTrack2, at: kCMTimeZero)
        }
        catch
        {
            print("Could not insert time range: \(error.localizedDescription)")
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
                    do {
                        try filemanager.removeItem(at: url1)
                        try filemanager.removeItem(at: url2)
                    } catch {
                        print("Error removing files from url: \(error.localizedDescription)")
                    }
                }
                
                do
                {
                    let file = try AKAudioFile(forReading: self.fileDestinationURL)
                    self.finalPlayer = try AKAudioPlayer(file: file, looping: true, completionHandler: nil)
                    AudioKit.output = self.finalPlayer
                    self.finalPlayer.fadeInTime = self.fadeInStepper.value
                    self.finalPlayer.fadeOutTime = self.fadeOutStepper.value
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
