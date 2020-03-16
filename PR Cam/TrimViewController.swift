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
    //var playbackTimeCheckerTimer: Timer! = nil
    //let playerObserver: Any? = nil

    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Double!

    var videoPlaybackPosition: CGFloat = 0.0
    var rangeSlider: RangeSlider! = nil

    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var imageFrameView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var trimButton: UIButton!

    //@IBOutlet weak var startView: UIView!
    //@IBOutlet weak var startTimeText: UITextField!

    //@IBOutlet weak var endView: UIView!
    //@IBOutlet weak var endTimeText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadViews()
    }
    
    // Load the view of the trim controller
    func loadViews() {
        print("Trim view recieved URL: \(self.url!)")
        
        // Create border for video layer
        //videoLayer.layer.borderWidth = 5.0
        //videoLayer.layer.cornerRadius = 5.0
        //videoLayer.layer.borderColor = UIColor.gray.cgColor
        
        frameContainerView.layer.borderWidth = 2.0
        frameContainerView.layer.cornerRadius = 10.0
        frameContainerView.layer.borderColor = UIColor.white.cgColor
        
        imageFrameView.layer.borderWidth  = 2.0
        imageFrameView.layer.cornerRadius = 10.0
        imageFrameView.layer.borderColor  = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        
        buttonView.layer.cornerRadius = 10.0
        
        /*
        layoutContainer.layer.borderWidth = 1.0
        layoutContainer.layer.borderColor = UIColor.white.cgColor

        selectButton.layer.cornerRadius = 5.0
        cropButton.layer.cornerRadius   = 5.0

        //Style for startTime
        startTimeText.layer.cornerRadius = 5.0
        startTimeText.layer.borderWidth  = 1.0
        startTimeText.layer.borderColor  = UIColor.white.cgColor

        //Style for endTime
        endTimeText.layer.cornerRadius = 5.0
        endTimeText.layer.borderWidth  = 1.0
        endTimeText.layer.borderColor  = UIColor.white.cgColor
        */
                
        // Create the video player and asset from URL
        player = AVPlayer()
        asset = AVURLAsset.init(url: self.url)

        thumbTime = asset.duration
        thumbtimeSeconds = CMTimeGetSeconds(thumbTime)

        // Get and create the video from the URL passed in
        let item: AVPlayerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoLayer.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        
        self.createRangeSlider()
        self.createImageFrames()

        // Add single tap gesture recognizer on video layer
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnVideoLayer))
        self.videoLayer.addGestureRecognizer(tap)
        self.tapOnVideoLayer(tap: tap)
        
        // Add notification observer for when the video finishes playing
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.player)

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
        rangeSlider.maximumValue = thumbtimeSeconds
        rangeSlider.lowerValue = 0.0
        rangeSlider.upperValue = thumbtimeSeconds
        
        //Range slider action
        rangeSlider.addTarget(self, action: #selector(TrimViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
    }
    
    // Called when the range slider value is changed
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        //print("LOWER: \(rangeSlider.lowerValue) UPPER: \(rangeSlider.upperValue)")
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
    @objc func finishedPlaying(){
        print("Video finished playing!")
        isPlaying = false
    }
    
    // Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
        self.videoPlaybackPosition = pos
        let time: CMTime = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if(pos == CGFloat(thumbtimeSeconds)) {
            self.player.pause()
        }
    }
    
    // Trim Video Function
    func cropVideo(sourceURL: NSURL, startTime: Float, endTime: Float) {
        let manager = FileManager.default
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("Video length: \(length) seconds")

        do {
            try manager.removeItem(at: self.url)
        }
        catch let error {
            print("Error removing item at URL: \(error)")
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = self.url
        exportSession.outputFileType = AVFileType.mp4

        let startTime = CMTime(seconds: Double(startTime), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(endTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
            switch exportSession.status {
                case .completed:
                    print("Exported at \(self.url!)")
                    self.saveToCameraRoll(url: self.url)
                case .failed:
                    print("Cropping video failed!")
                case .cancelled:
                    print("Cropping video cancelled!")
                default: break
            }
        }
        
    }
    
    // Save Video to Photos Library
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
        let thumbTime: CMTime = asset.duration
        let thumbtimeSeconds = CMTimeGetSeconds(thumbTime)
        let maxLength = "\(thumbtimeSeconds)" as NSString

        let thumbAvg: Double  = thumbtimeSeconds/6
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
            catch {
                print("Image generation failed with error (error)")
            }
          
            startXPosition = startXPosition + xPositionForEach
            startTime = startTime + thumbAvg
            imageButton.isUserInteractionEnabled = false
            imageFrameView.addSubview(imageButton)
        }
    }
}


