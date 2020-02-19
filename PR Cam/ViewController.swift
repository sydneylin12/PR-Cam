//
//  ViewController.swift
//  PR Cam
//
//  Created by Sydney Lin on 12/26/19.
//  Copyright © 2019 Sydney Lin. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate,  UINavigationControllerDelegate, RecordButtonDelegate {
    
    // The view used to display the video
    @IBOutlet weak var mainView: UIView!
    
    // UIButtons for swap, flash, camera roll
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    // Label for the timer and animated record button custom class
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordButton: RecordButton!
    
    // For the video screen
    var captureSession: AVCaptureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    var currentDevice: AVCaptureDevice! // Used for pinch feature
        
    // Indicate the state of the camera and currently recording
    var cameraPosition: CameraPosition = CameraPosition.BACK
    var recordingState: Bool = false // Can be kept as a boolean
    
    // Variables for the camera timer
    var time = 0
    var timer = Timer()
    
    // Constants and variable for zoom
    let minZoom: CGFloat = 1.0
    let maxZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    // Called when the application loads (once)
    override func viewDidLoad() {
        //print("View Controller - View Did Load")
        super.viewDidLoad()

        // Change label font for monospace
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: UIFont.Weight.regular)
        timerLabel.text = String(convertTime(time: time))
        
        // Detect double taps and upward swipe
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(swipeUp)
        view.addGestureRecognizer(pinch)
        
        // Add handler for background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Disable screen timeout
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Force dark theme for camera layout only
        overrideUserInterfaceStyle = .dark
        
        // Finally, configure the session
        configureSession(frontOrBack: cameraPosition)
    }
        
    // Initialize the animated record button
    override func viewDidAppear(_ animated: Bool) {
        //print("View Controller - View Did Appear")
        super.viewDidAppear(animated)
        recordButton.delegate = self
    }

    // When the animated recording button is pressed
    func tapButton(isRecording: Bool) {
        if(isRecording) {
            // Update boolean flag
            self.recordingState = true
            
            //Start timer
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.action), userInfo: nil, repeats: true)
            
            // Begin capture session
            captureSession.startRunning()
            
            // Set movie output save path
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
        // If the camera is recording
        else{
            //Update boolean flag
            self.recordingState = false
            
            // Turn off timer
            timer.invalidate()
            time = 0
            timerLabel.text = String(convertTime(time: time))
            
            // Stop recording and create notification
            movieOutput.stopRecording()
            createAlert(title: "Video Saved", message: "The video has been saved to your camera roll.")
        }
    }
    
    // Called when swap button pressed - should be disabled by default
    @IBAction func swapButtonPressed(_ sender: UIButton) {
        if cameraPosition == CameraPosition.FRONT {
            cameraPosition = CameraPosition.BACK
        }
        else if cameraPosition == CameraPosition.BACK {
            cameraPosition = CameraPosition.FRONT
        }
        else {
            print("Error in swapping cameras - this should never happen!")
        }
        // Configure the new session after swapping
        configureSession(frontOrBack: cameraPosition)
    }
    
    // Activates the flash for recording
    @IBAction func flashButtonPressed(_ sender: UIButton) {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        // If the device has a flash light
        if device!.hasTorch{
            do {
                try device!.lockForConfiguration()
                
                // If the flash light is currently on
                if (device!.torchMode == AVCaptureDevice.TorchMode.on) {
                    // Change the image to untoggled
                    sender.setImage(UIImage(named: "LightningLight"), for: .normal)
                    // Turn the flash light off
                    device!.torchMode = AVCaptureDevice.TorchMode.off
                }
                // If the light is currently off
                else {
                    do {
                        // Toggle light button to pressed
                        sender.setImage(UIImage(named: "LightningDark"), for: .normal)
                        // Turn on flash light
                        try device!.setTorchModeOn(level: 1.0)
                    }
                    catch {
                        print("Error activating flash light!")
                    }
                }
                device!.unlockForConfiguration()
            }
            catch {
                print("No flash light detected on device!")
            }
        }
    }
    
    // Go to the settings/info/about page
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "toSettingsSegue", sender: self)
    }
    
    // Called when the file output is saved (similar to a callback)
    // "Informs the delegate when all pending data has been written to an output file"
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        //print("File saved!")
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
    
    // Code to configure the camera session with an enum value of FRONT or BACK
    func configureSession(frontOrBack: CameraPosition) {
        do {
            // MUST RESET CAPTURE SESSION TO PREVENT EXCEPTIONS (MULTIPLE DEVICES)
            captureSession = AVCaptureSession()
            
            // Re-configure the audio with mixing
            captureSession.automaticallyConfiguresApplicationAudioSession = false
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .allowBluetoothA2DP, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
            var camera: AVCaptureDevice? = nil
            if cameraPosition == CameraPosition.FRONT {
                camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
            }
            else if cameraPosition == CameraPosition.BACK {
                camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
            }
            else {
                print("This should never happen!")
            }
            currentDevice = camera // Update current capture device
            let input = try AVCaptureDeviceInput(device: camera!)
            captureSession.addInput(input)
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds // Resize to fit screen
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            mainView.layer.addSublayer(previewLayer)
            movieOutput = AVCaptureMovieFileOutput() // NEED TO RE INIT TO PREVENT EXCEPTION
            captureSession.addOutput(movieOutput)
            let audioInput = AVCaptureDevice.default(for: AVMediaType.audio)
            try captureSession.addInput(AVCaptureDeviceInput(device: audioInput!))
            captureSession.startRunning()
        }
        catch {
            print("Error configuring capture session: \(error)")
        }
    }
        
    // Disable the flash light in the event of a swap
    func disableFlash() {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        // If the device has a flash light
        if device!.hasTorch{
            do {
                try device!.lockForConfiguration()
                // If the flash light is currently on
                if (device!.torchMode == AVCaptureDevice.TorchMode.on) {
                    // Change the image to untoggled
                    flashButton.setImage(UIImage(named: "LightningLight"), for: .normal)
                    // Turn the flash light off
                    device!.torchMode = AVCaptureDevice.TorchMode.off
                }
                device!.unlockForConfiguration()
            }
            catch {
                print("No flash light detected on device!")
            }
        }
    }
    
    // Create an alert when the video is finished
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in alert.dismiss(animated: true, completion: nil) }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Handle the pinch gesture to zoom the camera
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        
        // Return zoom factor using current capture device
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minZoom), maxZoom), (currentDevice.activeFormat.videoMaxZoomFactor))
        }
        
        // Update the camera's zoom using current device
        func update(scale factor: CGFloat) {
            do {
                try currentDevice.lockForConfiguration()
                defer { currentDevice.unlockForConfiguration() }
                currentDevice.videoZoomFactor = factor
            }
            catch {
                print("Error updating zoom factor: \(error)")
            }
        }
        
        // Get pinch setting from user default data
        let defaults = UserDefaults.standard
        var isPinchEnabled: Bool = true
        if defaultsHasKey(key: "IsPinchEnabled") {
            isPinchEnabled = defaults.object(forKey: "IsPinchEnabled") as! Bool
        }
        if !isPinchEnabled {
            return // Return out if pinching to zoom is disabled
        }
        
        let newFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        if pinch.state == .changed {
            update(scale: newFactor)
        }
        else if pinch.state == .ended {
            lastZoomFactor = minMaxZoom(newFactor)
            update(scale: lastZoomFactor)
        }
        
    }
    
    // Run the timer
    @objc func action() {
        time += 1;
        timerLabel.text = String(convertTime(time: time))
    }
    
    // Handle gestures such as double tap and swipes
    @objc func doubleTapped() {
        // Cannot swap while recording
        if(!movieOutput.isRecording){
            swapButtonPressed(swapButton)
        }
    }
    
    // Open the settings menu with an up swipe
    @objc func swipedUp() {
        performSegue(withIdentifier: "toSettingsSegue", sender: self)
    }
    
    // Called when the application is moved into the background
    @objc func appMovedToBackground() {
        if(recordingState){
            print("App turned off when recording.")
            
            // Force end recording in animated record button
            recordButton.endRecording()
            
            //Update boolean flag
            recordingState = false
            
            // Turn off timer
            timer.invalidate()
            time = 0
            timerLabel.text = String(convertTime(time: time))

            // Stop recording and create notification
            movieOutput.stopRecording()
            
            // Save file to path
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            UISaveVideoAtPathToSavedPhotosAlbum(fileUrl.path, nil, nil, nil )
            
            // Create notification of background app
            createAlert(title: "Recording Ended", message: "The recording has been saved before the application was exited.")
        }
    }
    
}
