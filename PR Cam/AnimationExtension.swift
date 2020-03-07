//
//  AnimationExtension.swift
//  PR Cam
//
//  Created by Sydney Lin on 3/4/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

import Foundation
import UIKit

// Animated buttons extension from YT
extension UIButton {
    // Pulse a UIButton
    func pulse() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.2
        pulse.fromValue = 0.75
        pulse.toValue = 1.0
        pulse.autoreverses = false
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        layer.add(pulse, forKey: nil)
    }
}
