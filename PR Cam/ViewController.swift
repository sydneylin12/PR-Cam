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
import StoreKit

class ViewController: UIViewController {
    
    // The view used to display the video
    @IBOutlet weak var mainView: UIView!
    
    // UIButtons for swap, flash, camera roll
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
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
    var recordingState: Bool = false
    var currentURL: URL?
    
    // Variables for the camera timer
    var time = 0
    var timer = Timer()
    
    // Constants and variable for zoom
    let minZoom: CGFloat = 1.0
    let maxZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    // Called when the application first loads
    override func viewDidLoad() {
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
                
        // Finally, configure the session
        configureSession()
    }
        
    // Initialize the animated record button
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        recordButton.delegate = self
    }
    
    // Force dark status bar only (NOT THEME)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // Prepare to send the URL to the trim segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toTrimSegue") {
            let trimController = segue.destination as! TrimViewController
            trimController.url = self.currentURL!
        }
    }
    
    // Called when swap button pressed - should be disabled by default
    @IBAction func swapPressed(_ sender: UIButton) {
        if cameraPosition == CameraPosition.FRONT {
            cameraPosition = CameraPosition.BACK
        }
        else if cameraPosition == CameraPosition.BACK {
            cameraPosition = CameraPosition.FRONT
        }
        else {
            print("Error in swapping cameras - this should never happen!")
        }
        // Re configure camera only
        configureCameraSwap()
    }
    
    // Activates the flash for recording
    @IBAction func flashPressed(_ sender: UIButton) {
        sender.pulse() // Play a pulse animation when flash is clicked
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
    @IBAction func settingsPressed(_ sender: UIButton) {
        // Rotate the cog settings button CW
        UIView.animate(withDuration: 0.25, animations: {
            sender.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        })
        // Reset the animation angle to 0
        sender.transform = CGAffineTransform(rotationAngle: 0)
        performSegue(withIdentifier: "toSettingsSegue", sender: self)
    }
    
    // Code to configure the camera session with an enum value of FRONT or BACK
    func configureSession() {
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
    
    // Only swap the camera without configuring the audio
    func configureCameraSwap() {
        blur() // Blur/fade in animation on camera swap
        for input in captureSession.inputs { // Only remove camera inputs
            let desc: String = input.description
            if !desc.contains("Microphone") {
                captureSession.removeInput(input)
            }
        }
        
        // Set default to back camera
        var newCamera: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        if cameraPosition == CameraPosition.FRONT {
            newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
            disableFlash() // Turn off in case flash is currently on
            flashButton.isEnabled = false
        }
        else {
            // Enable flash button on back camera only
            flashButton.isEnabled = true
        }
        
        do { // Re-add the capture input and play a flip animation
            try captureSession.addInput(AVCaptureDeviceInput(device: newCamera))
            UIView.transition(with: swapButton, duration: 0.3, options: .transitionFlipFromLeft, animations: nil, completion: nil)
        }
        catch {
            print("Error adding swapped camera input to capture session.")
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
    
    // Create an alert with options to save or trim (PRO)
    func createFinishedRecordingAlert() {
        let alert = UIAlertController(title: "PR Cam recording finished.", message: "What would you like to do?", preferredStyle: .alert)
        
        // Request a review when the alert is dismissed
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Trim", style: .default, handler: {
            (action) in self.performSegue(withIdentifier: "toTrimSegue", sender: self)
        }))
        
        // Present the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    // Trigger a blur effect for swapping the camera
    func blur() {
        // Create a blur effect and blur view
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.bounds // Set bounds to whole screen
        UIView.transition(with: self.mainView, duration: 0.75, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    // Handle the pinch gesture to zoom the camera (closure)
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
        var pinchEnabled: Bool = true
        if hasKey(key: "PinchEnabled") {
            pinchEnabled = defaults.object(forKey: "PinchEnabled") as! Bool
        }
        if !pinchEnabled {
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
        // Disable if turned off in settings
        if hasKey(key: "DoubleTapEnabled") {
            let b: Bool! = (getValue(key: "DoubleTapEnabled") as! Bool)
            if !b {
                return
            }
        }
        
        // Cannot swap while recording
        if !recordingState {
            swapPressed(swapButton)
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
            createNotification(sender: self, title: "Recording Ended", message: "The recording has been saved before the application was exited.")
        }
    }
}

// Delegate function for when the recording is finished
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            //print("Video finished recording to output file URL: \(outputFileURL)")
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    // Handle when the file finishes saving
    @objc func video(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo info: UnsafeMutableRawPointer) {
        if(error == nil) {
            var trimEnabled: Bool = false
            if(hasKey(key: "TrimEnabled")){
                trimEnabled = getValue(key: "TrimEnabled") as! Bool
            }
            if(trimEnabled) { // Allow user to trim
                createFinishedRecordingAlert()
            }
            else { // Create default alert
                createNotification(sender: self, title: "PR Cam recording finished.", message: "Video has been saved to the camera roll.")
            }
        }
        else {
            createNotification(sender: self, title: "Error saving video", message: "There was an error saving the video. Please check the app settings.")
        }
    }
}

// Delegate for tapping the animated record button
extension ViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        if(isRecording) {
            // Update boolean flag
            self.recordingState = true
            
            //Start timer
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.action), userInfo: nil, repeats: true)
            
            // Begin capture session
            captureSession.startRunning()
            
            // Generate a unique URL to save the video to
            let fileURL = generateURL()
            currentURL = fileURL
            movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        }
        else{ // If the camera is recording
            self.recordingState = false
            
            // Turn off timer and reset label text
            timer.invalidate()
            time = 0
            timerLabel.text = String(convertTime(time: time))
            
            movieOutput.stopRecording()
        }
    }
}
