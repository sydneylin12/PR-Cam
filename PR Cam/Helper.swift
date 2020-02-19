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

// Enum for handing camera position
public enum CameraPosition {
    case FRONT
    case BACK
}

// Enum for the current theme
public enum AppTheme: Int {
    case LIGHT = 0
    case DARK = 1
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
public func defaultsHasKey(key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

// Class to hold settings and pro mode
public class Settings {
    private static var isProEnabled: Bool = true
    private static var currentTheme: AppTheme = AppTheme.LIGHT
    
    // Getter for pro mode enabled or not
    public static func getPro() -> Bool {
        return isProEnabled
    }
    
    // Setter for "global" static variable
    public static func setPro(b: Bool) {
        isProEnabled = b
    }
    
    public static func getTheme() -> AppTheme {
        return currentTheme
    }
    
    public static func setTheme(theme: AppTheme) {
        currentTheme = theme
    }
    
    //static func saveData(){
        //let defaults = UserDefaults.standard
        //let theme = currentTheme == AppTheme.LIGHT ? false : true
        //defaults.set(false, forKey: "isPro")
        //defaults.set(theme, forKey: "ProTheme")
    //}
}

/*
 ---UNUSED CODE---
 
 @IBOutlet weak var cameraRollButton: UIButton!
 @IBOutlet weak var prButton: UIButton!
 
 // Enable and disable the overlay
 var overlayEnabled: Bool = true
 
 // Open the (video) camera roll
 @IBAction func cameraRollButtonPressed(_ sender: UIButton){
     if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
         let imagePicker = UIImagePickerController()
         imagePicker.sourceType = .photoLibrary;
         imagePicker.mediaTypes = ["public.movie"]
         imagePicker.allowsEditing = true
         imagePicker.delegate = self
         self.present(imagePicker, animated: true, completion: nil)
     }
 }
 
 @IBAction func prButtonPressed(_ sender: UIButton){
     disableOverlay()
 }
 
 // Turn off the overlay if the PR button is pressed
 func disableOverlay(){
     if overlayEnabled{
         //prButton.setImage(UIImage(named: "PR Cam Logo Dark"), for: .normal)
         swapButton.isHidden = true
         flashButton.isHidden = true
         recordButton.isHidden = true
         cameraRollButton.isHidden = true
         timerLabel.isHidden = true
     }
     else{
         //prButton.setImage(UIImage(named: "PR Cam Logo"), for: .normal)
         swapButton.isHidden = false
         flashButton.isHidden = false
         recordButton.isHidden = false
         cameraRollButton.isHidden = false
         timerLabel.isHidden = false
     }
     overlayEnabled = !overlayEnabled
 }
 
 // TODO
 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     print("Video picked from image controller!")
     // Dictionary that contains the file URL if a video is picked
     for (key, value) in info{
         print(type(of: key))
         print(type(of: value))
         print("KEY: \(key) \nVALUE: \(value)")
     }
     self.dismiss(animated: true, completion: nil)
 }
 */
