//
//  TrimViewController.swift
//  PR Cam
//
//  Created by Sydney Lin on 3/14/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

class TrimViewController: UIViewController {
    
    // URL for the file to be trimmed
    public var url: URL!
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    @IBOutlet weak var videoLayer: UIView!
    
    var isPlaying: Bool = true
    var isDirty: Bool = false

    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var totalTime: Double! = 0.0

    var videoPlaybackPosition: CGFloat = 0.0
    var rangeSlider: RangeSlider! = nil

    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var imageFrameView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var trimButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadViews()
    }
    
    // Load the view of the trim controller
    func loadViews() {
        print("Trim view recieved URL: \(self.url!)")
        
        // Initialize the UI elements
        frameContainerView.layer.borderWidth = 2.0
        frameContainerView.layer.cornerRadius = 10.0
        frameContainerView.layer.borderColor = UIColor.white.cgColor
        
        imageFrameView.layer.borderWidth  = 2.0
        imageFrameView.layer.cornerRadius = 10.0
        imageFrameView.layer.borderColor  = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        
        buttonView.layer.cornerRadius = 10.0
        
        progressBar.setProgress(0.0, animated: false)
        progressBar.isHidden = true
        progressBar.layer.masksToBounds = true
        progressBar.layer.cornerRadius = 5.0
                
        // Create the video player and asset from URL
        player = AVPlayer()
        asset = AVURLAsset.init(url: self.url)
        let item: AVPlayerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoLayer.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        
        // Get the total video time
        totalTime = CMTimeGetSeconds(asset.duration)
        
        // Initialize the trim slider AFTER getting total time
        self.createRangeSlider()
        self.createImageFrames()

        // Add single tap gesture recognizer on video layer
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnVideoLayer))
        self.videoLayer.addGestureRecognizer(tap)
        self.tapOnVideoLayer(tap: tap)
        
        // Add notification observer for when the video finishes playing
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(exportCompleted), name: Notification.Name("ExportCompleted"), object: nil)

        videoLayer.layer.addSublayer(playerLayer)
        player.play()
        
        if(!isDirty){ // Disable trim if the video has not been edited
            self.trimButton.isEnabled = false
            self.trimButton.setTitleColor(UIColor.systemGray, for: .normal)
        }
    }
    
    // Button action for crop video
    @IBAction func cropVideo(_ sender: Any) {
        let start = Float(rangeSlider.lowerValue)
        let end = Float(rangeSlider.upperValue)
        self.cropVideo(sourceURL: url as NSURL, startTime: start, endTime: end)
    }
    
    // When close button is clicked, dismiss the trim VC
    @IBAction func onClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Initialize the range slider element
    func createRangeSlider() {
        rangeSlider = RangeSlider(frame: frameContainerView.bounds)
        frameContainerView.addSubview(rangeSlider)
        rangeSlider.trackHighlightTintColor = UIColor.clear
        rangeSlider.trackTintColor = UIColor.clear
        rangeSlider.thumbTintColor = UIColor.white
        rangeSlider.curvaceousness = 1.0
        
        // Set the max, upper value, and min to 0 and (video.length) respectively
        rangeSlider.minimumValue = 0.0
        rangeSlider.maximumValue = totalTime
        rangeSlider.lowerValue = 0.0
        rangeSlider.upperValue = totalTime
        
        //Range slider action
        rangeSlider.addTarget(self, action: #selector(TrimViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
    }
    
    // Called when the range slider value is changed
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        self.player.pause()
        isPlaying = false
        
        self.isDirty = true
        self.trimButton.isEnabled = true
        self.trimButton.setTitleColor(UIColor.systemRed, for: .normal)
        
        if(rangeSlider.lowerLayerSelected) {
            self.seekVideo(toPos: CGFloat(rangeSlider.lowerValue))
        }
        else {
            self.seekVideo(toPos: CGFloat(rangeSlider.upperValue))
        }
    }
    
    // Tap action on video player
    @objc func tapOnVideoLayer(tap: UITapGestureRecognizer) {
        if isPlaying {
            self.player.play()
        }
        else { // If the video is paused
            self.seekVideo(toPos: CGFloat(rangeSlider.lowerValue))
            self.player.pause()
        }
        isPlaying = !isPlaying
    }
    
    // Called when the trim video preview finished
    @objc func finishedPlaying() {
        //print("Video finished playing!")
        isPlaying = false
    }
    
    // Called when the tread finishes exporting the video and dismiss the trim VC
    @objc func exportCompleted() {
        deleteLast()
        self.dismiss(animated: true, completion: nil)
    }
    
    // Dismiss the view controller
    @objc func exportFailed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
        self.videoPlaybackPosition = pos
        let time: CMTime = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if(pos == CGFloat(totalTime)) {
            self.player.pause()
        }
    }
    
    // Trim Video Function
    func cropVideo(sourceURL: NSURL, startTime: Float, endTime: Float) {
        // Disable close button and unhide progress bar
        progressBar.isHidden = false
        closeButton.isEnabled = false
        closeButton.setTitleColor(UIColor.gray, for: .normal)
        trimButton.isEnabled = false
        trimButton.setTitleColor(UIColor.gray, for: .normal)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        let newUrl = generateURL()
        exportSession.outputURL = newUrl
        exportSession.outputFileType = AVFileType.mp4

        let startTime = CMTime(seconds: Double(startTime), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(endTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        var isComplete: Bool = false
        
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
            switch exportSession.status {
                case .completed:
                    print("Exported at \(self.url!)")
                    isComplete = true
                    self.saveToCameraRoll(url: newUrl)
                    // MUST call this on the main thread
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("ExportCompleted"), object: nil)
                    }
                case .failed:
                    DispatchQueue.main.async {
                        isComplete = true
                        createAlert(sender: self, title: "Error trimming video.", message: "The trimming operation failed due to an error.")
                        self.closeButton.isEnabled = true
                        self.closeButton.setTitleColor(UIColor.white, for: .normal)
                        self.trimButton.isEnabled = true
                        self.trimButton.setTitleColor(UIColor.systemRed, for: .normal)
                    }
                default:
                    break
            }
        }
        
        // Update the progress bar continuously
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {
            (timer) in guard !isComplete else{
                timer.invalidate()
                return
            }
            self.progressBar.setProgress(exportSession.progress, animated: true)
        })
    }
    
    // Save video to photo library
    func saveToCameraRoll(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        })
    }
    
    // Generate images for trim slider
    func createImageFrames() {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let totalTime = CMTimeGetSeconds(asset.duration)
        let maxLength = "\(totalTime)" as NSString

        let thumbAvg: Double  = totalTime/6
        var startTime: Double = 0.0
        var startXPosition: CGFloat = 0.0
        
        //loop for 6 number of frames
        for _ in 0...5 {
            let imageButton = UIButton()
            let xPositionForEach = CGFloat(self.imageFrameView.frame.width)/6
            imageButton.frame = CGRect(x: CGFloat(startXPosition), y: CGFloat(0), width: xPositionForEach, height: CGFloat(self.imageFrameView.frame.height))
            do {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                imageButton.setImage(image, for: .normal)
            }
            catch let error {
                print("Image generation failed with error \(error)")
            }
          
            startXPosition = startXPosition + xPositionForEach
            startTime = startTime + thumbAvg
            imageButton.isUserInteractionEnabled = false
            imageFrameView.addSubview(imageButton)
        }
    }
}


