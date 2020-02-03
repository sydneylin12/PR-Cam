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
