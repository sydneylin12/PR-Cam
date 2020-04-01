//
//  Helper.swift
//  PR Cam
//
//  Created by Sydney Lin on 1/28/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

// Class made for helper functions
// Mainly used to clean up the ViewController.swift file
import Foundation
import StoreKit
import Photos

// Enum for handing camera position
enum CameraPosition {
    case FRONT
    case BACK
}

// Convert to formatted time from hundreths of a second
func convertTime(time: Int) -> String{
    let t = time // Convert to milliseconds
    let minutes = String(format: "%02d", (t / 6000) % 60)
    let seconds = String(format: "%02d", (t / 100) % 60)
    let hundreds = String(format: "%02d", t % 100)
    return "\(minutes):\(seconds).\(hundreds)"
}

// Check if the data has been saved to defaults (persistent data)
func hasKey(key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

// Get the value of a defaults key and return it
func getValue(key: String) -> Any {
    return UserDefaults.standard.object(forKey: key)!
}

// Set a user defaults key
func setKey(key: String, value: Any){
    UserDefaults.standard.set(value, forKey: key)
}

// Determine if the user is a pro user
func isPro() -> Bool {
    if hasKey(key: "ProEnabled") {
        return getValue(key: "ProEnabled") as! Bool
    }
    else {
        return false
    }
}

// Generate a random URL for file saving
func generateURL() -> URL {
    let videoFileName = NSUUID().uuidString
    let videoFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((videoFileName as NSString).appendingPathExtension("mov")!)
    let newURL = URL(fileURLWithPath: videoFilePath)
    return newURL
}

// Request review for the app store
func requestReview() {
    if hasKey(key: "IsProEnabled") {
        let proUser: Bool = getValue(key: "IsProEnabled") as! Bool
        if !proUser { // If pro is not enabled
            SKStoreReviewController.requestReview()
        }
    }
}

// Create a generic alert when the video is finished
func createAlert(sender: UIViewController, title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    // Do not request review if there is an error
    if title.contains("Error") {
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in alert.dismiss(animated: true, completion: nil)
        }))
    }
        
    else { // Request a review on successful notification
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in alert.dismiss(animated: true, completion: {
                requestReview()
            })
        }))
    }
    
    // Present the alert
    sender.present(alert, animated: true, completion: nil)
}

// Delete the last item from the camera roll
func deleteLast() {
    let fetchOptions: PHFetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: fetchOptions)
    if fetchResult.lastObject != nil {
        let lastAsset: PHAsset = fetchResult.lastObject! as PHAsset
        let arrayToDelete = NSArray(object: lastAsset)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(arrayToDelete)
        }, completionHandler: {
            success, error in
            if success {
                print("Deletion of last video succeeded!")
            }
        })
    }
}
