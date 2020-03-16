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

// Enum for handing camera position
enum CameraPosition {
    case FRONT
    case BACK
}

// Handle time conversion from hundreds of seconds to formatted time
func convertTime(time: Int) -> String{
    var t = time
    let minutes = String(format: "%02d", t/6000)
    t = t % 60000
    let seconds = String(format: "%02d", t/100)
    t = t % 100
    let hundreds = String(format: "%02d", t)
    //print("\(minutes):\(seconds).\(ms)")
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

// Generate a URL for file saving
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
