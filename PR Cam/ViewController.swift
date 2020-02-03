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

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    // The view used to display the video
    @IBOutlet weak var cameraView: UIView!
    
    // The buttons for record and swap camera
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    // Label for the timer
    @IBOutlet weak var timerLabel: UILabel!
    
    // For the video screen
    var captureSession: AVCaptureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        
    // Controls the side of the camera and flash
    var frontOrBack: Bool = false
    
    // Bool indicating if the camera is recording - used for turn off bug
    var isRecording: Bool = false
    
    // For the camera timer
    var time = 0;
    var timer = Timer();
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Change label font for monospace
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: UIFont.Weight.regular)
        
        // Initialize text with 0 time
        timerLabel.text = String(convertTime(time: time))
        
        // Detect double taps
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
        // Add handler for background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Disable screen timeout
        UIApplication.shared.isIdleTimerDisabled = true
    
        do{
            // Create camera device for back camera
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            // Add video input
            let input = try AVCaptureDeviceInput(device: backCamera!)
            captureSession.addInput(input)
            
            // Create preview video frame for screen
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            
            // Not sure what this does (set bounds to whole screen)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraView.layer.addSublayer(previewLayer)
            
            // Add movie file output
            captureSession.addOutput(movieOutput)
            
            // Add audio output to file - DOES NOT WORK WITH MUSIC
            //let audioInput = AVCaptureDevice.default(for: AVMediaType.audio)
            //try captureSession.addInput(AVCaptureDeviceInput(device: audioInput!))
            
            // Begin capture session - need to get preview of camera
            captureSession.startRunning()
        }
        catch{
            print("Error creating video capture [initialization]!")
        }
    }

    // When the record button is pressed
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        // If the camera is not recording
        if(!movieOutput.isRecording){
            // Update boolean flag
            isRecording = true
            
            //Start timer
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.action), userInfo: nil, repeats: true)

            // Update image to clicked
            sender.setImage(UIImage(named: "RecordingLogo"), for: .normal)
            swapButton.isEnabled = false
            
            // Begin capture session
            captureSession.startRunning()
            
            // Set movie output save path
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
        // If the camera is recording
        else{
            //Update boolean flag
            isRecording = false
            
            // Turn off timer
            timer.invalidate()
            time = 0
            timerLabel.text = String(convertTime(time: time))
            
            // Update image to unclicked
            sender.setImage(UIImage(named: "RecordLogo"), for: .normal)
            swapButton.isEnabled = true

            // Stop recording and create notification
            movieOutput.stopRecording()
            createAlert(title: "Video Saved", message: "The video has been saved to your camera roll.")
        }
    }
    
    // Called when swap button pressed
    @IBAction func swapButtonPressed(_ sender: UIButton){
        // Stop capture and change record button back to normal
        captureSession.stopRunning()
        recordButton.setImage(UIImage(named: "RecordLogo"), for: .normal)
        
        if frontOrBack{ //Front camera is connected
            do{
                // Enable flash button
                flashButton.isEnabled = true
                
                // Create a new capture session (repeat of first code block)
                captureSession = AVCaptureSession()
                let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

                let input = try AVCaptureDeviceInput(device: cam!)
                captureSession.addInput(input)
                
                // Create preview video frame for screen
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = view.layer.bounds
                
                // Not sure what this does (set bounds to whole screen)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                cameraView.layer.addSublayer(previewLayer)
                
                // Add movie file output
                movieOutput = AVCaptureMovieFileOutput()
                captureSession.addOutput(movieOutput)
                captureSession.startRunning()
            }
            catch{
                print("Error switching to front camera")
            }
        }
        else{ // Back camera is currently connected
            do{
                // Disable the flash for front camera
                flashButton.isEnabled = false
                disableFlash()
                
                // Create a new capture session (repeat of first code block)
                captureSession = AVCaptureSession()
                let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

                let input = try AVCaptureDeviceInput(device: cam!)
                captureSession.addInput(input)
                
                // Create preview video frame for screen
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = view.layer.bounds
                
                // Not sure what this does (set bounds to whole screen)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                cameraView.layer.addSublayer(previewLayer)
                
                // Add movie file output
                movieOutput = AVCaptureMovieFileOutput()
                captureSession.addOutput(movieOutput)
                captureSession.startRunning()
            }
            catch{
                print("Error switching to front camera")
            }
        }
        
        // Change the bool toggle for camera side
        frontOrBack = !frontOrBack
    }
    
    // Activates the flash for recording
    @IBAction func flashButtonPressed(_ sender: UIButton){
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
    
    // Open the (video) camera roll
    @IBAction func cameraRollButtonPressed(_ sender: UIButton){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary;
            imagePicker.mediaTypes = ["public.movie"]
            imagePicker.allowsEditing = true
            // Present the image picker
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // TODO trim video
    func openVideoEditor(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let videoEditor = UIVideoEditorController()
            videoEditor.videoMaximumDuration = 0
            self.present(videoEditor, animated: true, completion: nil)
        }
    }
    
    /* NOT IMPLEMENTED YET
    @IBAction func prButtonPressed(_ sender: UIButton){
        if(!isPrRecording){
            print("Started screen recording")
            recorder.startRecording(handler: nil)
        }
        else{
            // Stop screen recording
            print("Ended screen rcording")
            recorder.stopRecording(handler: { (preview, error) in
                if let temp = error{
                    print("ERROR SAVING RECORDING")
                    return
                }
                self.present(preview!, animated: true, completion: nil)
            })
        }
        isPrRecording = !isPrRecording
    } */
        
    // Disable the flash light in the event of a swap
    func disableFlash(){
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
    
    // Save the output to a file
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
    
    // Create an alert when the video is finished
    func createAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in alert.dismiss(animated: true, completion: nil) }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Run the timer
    @objc func action(){
        time += 1;
        timerLabel.text = String(convertTime(time: time))
    }
    
    // Handle double tap on camera
    @objc func doubleTapped(){
        // Cannot swap while recording
        if(!movieOutput.isRecording){
            swapButtonPressed(swapButton)
        }
    }
    
    // Called when the application is moved into the background
    @objc func appMovedToBackground(){
        // Save recording and enable camera swap if it was recording
        if(isRecording){
            print("App turned off when recording.")
            //Update boolean flag
            isRecording = false
            
            // Update image to unclicked
            recordButton.setImage(UIImage(named: "RecordLogo"), for: .normal)
            swapButton.isEnabled = true

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

