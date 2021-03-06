//
//  SettingsTableViewController.swift
//  PR Cam
//
//  Created by Sydney Lin on 2/16/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, SKPaymentTransactionObserver {
    
    // Label indicating app version
    @IBOutlet weak var versionLabel: UILabel!
    
    // Settings switches custom classes
    @IBOutlet weak var pinchSwitch: SettingsSwitch!
    @IBOutlet weak var doubleTapSwitch: SettingsSwitch!
    @IBOutlet weak var proSwitch: SettingsSwitch!
    
    // Table view controller cells
    @IBOutlet weak var purchaseProCell: UITableViewCell!
    @IBOutlet weak var pinchCell: UITableViewCell!
    @IBOutlet weak var doubleTapCell: UITableViewCell!
    @IBOutlet weak var proToggleCell: UITableViewCell!
    @IBOutlet weak var moreInfoCell: UITableViewCell!
    
    // IAP product ID
    let productID: String = "com.sydneylin.prcam.pro"
    
    //let settingsKeys = ["PinchEnabled", "DoubleTapEnabled", "ProEnabled"]
    
    // List of settings UI elements (array of switches to be toggled)
    var settingsSwitches: Array<SettingsSwitch> = []

    // Called each time the segue is used/TableVC is loaded in
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Supress the errors about width/height constraint
        self.tableView.rowHeight = 44
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = version
        
        // Disable highlighting for settings ONLY
        pinchCell.selectionStyle = .none
        doubleTapCell.selectionStyle = .none
        proToggleCell.selectionStyle = .none
        
        // Initialize default keys as custom class property
        pinchSwitch.settingKey = "PinchEnabled"
        doubleTapSwitch.settingKey = "DoubleTapEnabled"
        proSwitch.settingKey = "ProTheme"
        
        // Append all switches to the list
        settingsSwitches.append(pinchSwitch)
        settingsSwitches.append(doubleTapSwitch)
        settingsSwitches.append(proSwitch)
        
        // IAP observer
        SKPaymentQueue.default().add(self)
                
        // Finally, configure default values and settings switches
        configureDefaults()
        configureSettings()
    }
    
    // Handle the payments
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            // If item has been purchased
            if transaction.transactionState == .purchased || transaction.transactionState == .restored{
                print("Transaction succeeded with state: \(transaction.transactionState)")
                // Update the defaults to enable pro mode
                SKPaymentQueue.default().finishTransaction(transaction)

                // Enable pro features
                setKey(key: "ProEnabled", value: true)
                toggleProFeature(isEnabled: true)
            }
            else if transaction.transactionState == .failed {
                print("Transaction failed!")
                SKPaymentQueue.default().finishTransaction(transaction)
            }
            else{
                print("Error with transaction: \(transaction.transactionState)")
            }
        }
    }
    
    // Return number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    // Return number of sections in each cell
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // Settings
            return 2
        }
        else if section == 1 { // Help & Support
            return 3
        }
        else if section == 2 { // About
            return 1
        }
        else if section == 3 { // Pro settings
            return 4
        }
        else {
            return 0
        }
    }
    
    // Handles interaction at an index path [a, b]
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let a = indexPath[0] // Get section index
        let idx = indexPath.item // Get cell index of section (a)
        if a == 1 && idx == 0 {
            infoPressed()
        }
        else if a == 1 && idx == 1 {
            sharePressed()
        }
        else if a == 1 && idx == 2 {
            contactPressed()
        }
        else if a == 3 && idx == 0 {
            purchasePressed()
        }
        else if a == 3 && idx == 1 {
            restorePressed()
        }
        else if a == 3 && idx == 3 {
            moreInfoPressed()
        }
        // De-select after finished
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Update the user defaults value when a switch is toggled
    @IBAction func onSwitchChanged(_ sender: SettingsSwitch) {
        setKey(key: sender.settingKey, value: sender.isOn)
        if sender.settingKey == "ProTheme" {
            configureTheme(isDark: sender.isOn)
        }
    }
    
    // Initialize the default values and configure the page
    func configureDefaults() {
        let defaults = UserDefaults.standard
        
        // If keys do not exist, default them to true
        if !hasKey(key: "PinchEnabled") {
            defaults.set(true, forKey: "PinchEnabled")
        }
        if !hasKey(key: "DoubleTapEnabled") {
            defaults.set(true, forKey: "DoubleTapEnabled")
        }
        if !hasKey(key: "ProTheme") { // Use boolean instead of the custom enum
            defaults.set(false, forKey: "ProTheme")
        }
        
        // Configure pro mode IAP
        if !hasKey(key: "ProEnabled") { // Pro has not been purchased by default
            defaults.set(false, forKey: "ProEnabled")
            toggleProFeature(isEnabled: false)
        }
        else { // Enable/disable pro switch accordingly
            let isPro: Bool = getValue(key: "ProEnabled") as! Bool
            toggleProFeature(isEnabled: isPro)
        }
    }
    
    // Disable and enable pro features (does not modify switch values)
    func toggleProFeature(isEnabled: Bool) {
        if(!isEnabled) {
            proToggleCell.isUserInteractionEnabled = false
            proSwitch.thumbTintColor = UIColor.systemGray
        }
        else {
            proToggleCell.isUserInteractionEnabled = true
            proSwitch.thumbTintColor = UIColor.white
        }
    }
    
    // Iterate through the settings switches and enable/disable them accordingly
    func configureSettings() {
        for s in settingsSwitches {
            // Get defaults key label from custom class
            let switchKey: String = s.settingKey
            
            // Special condition to configure theme
            if hasKey(key: switchKey) && switchKey == "ProTheme" {
                let switchState = getValue(key: switchKey)
                s.isOn = switchState as! Bool
                configureTheme(isDark: s.isOn)
            }
            else if hasKey(key: switchKey) {
                let switchState = getValue(key: switchKey)
                s.isOn = switchState as! Bool
            }
            else {
                print("No key for current switch: \(s.description)")
            }
        }
    }
    
    // Reusable helper function to set the colors of the theme
    func configureTheme(isDark: Bool) {
        if isDark { // true == dark theme
            proSwitch.isOn = true
            overrideUserInterfaceStyle = .dark
            pinchSwitch.onTintColor = UIColor.systemRed
            doubleTapSwitch.onTintColor = UIColor.systemRed
            proSwitch.onTintColor = UIColor.systemRed
            versionLabel.textColor = UIColor.systemRed
            purchaseProCell.tintColor  = UIColor.systemRed
            moreInfoCell.tintColor = UIColor.systemRed
            setKey(key: "ProTheme", value: true)
        }
        else {
            proSwitch.isOn = false
            overrideUserInterfaceStyle = .light
            pinchSwitch.onTintColor = UIColor.systemGreen
            doubleTapSwitch.onTintColor = UIColor.systemGreen
            proSwitch.onTintColor = UIColor.systemGreen
            versionLabel.textColor = UIColor.systemBlue
            purchaseProCell.tintColor  = UIColor.systemBlue
            moreInfoCell.tintColor = UIColor.systemBlue
            setKey(key: "ProTheme", value: false)
        }
    }
    
    // Share info about the app
    func sharePressed() {
        let title = "Film your workouts with music! Try out PR Cam!"
        let URL: NSURL = NSURL(string: "https://apps.apple.com/us/app/pr-cam/id1493299604?ls=1")!
        
        let activityVC = UIActivityViewController(activityItems: [title, URL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        // Exclude these types for sharing
        activityVC.excludedActivityTypes = [
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.openInIBooks,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.addToReadingList
        ]
        
        // Present the share popup
        self.present(activityVC, animated: true, completion: nil)
    }
    
    // Open link in safari to github page
    func infoPressed() {
        let infoURL: URL = URL(string: "https://github.com/sydneylin12/PR-Cam/blob/master/README.md")!
        UIApplication.shared.open(infoURL)
    }
    
    // Contact me (Sid) through a popup
    func contactPressed() {
        if MFMailComposeViewController.canSendMail(){
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["sydney.lin12@gmail.com"])
            mail.setSubject("Sent from PR Cam.")
            present(mail, animated: true)
        }
    }
    
    // Purchase the IAP and activate pro mode
    func purchasePressed() {
        if SKPaymentQueue.canMakePayments() {
            print("User able to make payment!")
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = productID
            SKPaymentQueue.default().add(paymentRequest)
        }
        else {
            print("User unable to make payment!")
        }
    }
    
    // Restore purchases button to meet apple requirements
    func restorePressed() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func moreInfoPressed() {
        let desc: String = "Help out a university student developer and gain access to these features!\n\n" + "-PR Cam Pro dark theme\n" + "-Trim videos right after filming them\n"
        createAlert(sender: self, title: "About PR Cam Pro", message: desc)
    }
    
    // Dismiss the mail popup
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
