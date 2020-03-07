//
//  SettingsSwitch.swift
//  PR Cam
//
//  Created by Sydney Lin on 3/4/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

import UIKit

// Custom class used to hold default values for switch
// Make it easier to implement settings in the future
class SettingsSwitch: UISwitch {

    // The user defaults key
    var settingKey: String! {
        didSet {
            //print("didSet settingKey, settingKey = \(self.settingKey ?? "DEFAULT")")
        }
    }

    required init(coder aDecoder: NSCoder)  {
        super.init(coder: aDecoder)!
    }
}
