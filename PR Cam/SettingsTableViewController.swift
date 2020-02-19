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
    
    //@IBOutlet weak var audioSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var pinchSwitch: UISwitch!
    @IBOutlet weak var proSwitch: UISwitch!
    @IBOutlet weak var settingsTableCell: UITableViewCell!
    @IBOutlet weak var purchaseProCell: UITableViewCell!
    @IBOutlet weak var proToggleCell: UITableViewCell!
    
    // IAP product ID
    let productID: String = "com.sydneylin.prcam.pro"

    // Called each time the segue is used/TableVC is loaded in
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Supress the errors about width/height constraint
        self.tableView.rowHeight = 44
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = version
        
        // Disable highlighting for settings ONLY
        settingsTableCell.selectionStyle = .none
        proToggleCell.selectionStyle = .none
        
        // IAP observer
        SKPaymentQueue.default().add(self)
        
        // Finally, configure the default values
        configureDefaults()
    }
    
    // Handle the payments
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            // If item has been purchased
            if transaction.transactionState == .purchased {
                print("Transaction succeeded!")
                // Update the defaults to enable pro mode
                let defaults = UserDefaults.standard
                defaults.set(true, forKey: "IsProEnabled")
            }
            else if transaction.transactionState == .failed {
                print("Transaction failed!")
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    
    // Return number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    // Return number of sections in each cell 0: 1, 1: 3, 2: 1, 3: 2
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // Settings
            return 1
        }
        else if section == 1 { // Help & Support
            return 3
        }
        else if section == 2 { // About
            return 1
        }
        else if section == 3 {
            return 2
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
        // De-select after finished
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Triggered when pinch switch is changed
    @IBAction func onPinchChanged(_ sender: UISwitch) {
        configurePinch(isEnabled: sender.isOn)
    }
    
    // Triggered when the pro theme switch is used
    @IBAction func onThemeChanged(_ sender: UISwitch) {
        if sender.isOn { // Turned on pro theme
            configureTheme(theme: AppTheme.DARK)
        }
        else {
            configureTheme(theme: AppTheme.LIGHT)
        }
    }
    
    // Initialize the default values and configure the page
    func configureDefaults() {
        let defaults = UserDefaults.standard
        if defaultsHasKey(key: "IsPinchEnabled") {
            let b: Bool = defaults.object(forKey: "IsPinchEnabled") as! Bool
            print("Pinch enabled status: \(b)")
            configurePinch(isEnabled: b)
        }
        else {
            print("No key for pinching!") // Default to enable pinch
            defaults.set(true, forKey: "IsPinchEnabled")
            configurePinch(isEnabled: true)
        }
        
        // Check defaults if pro mode is enabled
        if defaultsHasKey(key: "IsProEnabled") {
            let b: Bool = defaults.object(forKey: "IsProEnabled") as! Bool

            print("Pro enabled status: \(b)")
            if b { // Pro is enabled
                proToggleCell.isUserInteractionEnabled = true
                proSwitch.thumbTintColor = UIColor.white
            }
            else { // Disable pro theme if not paid
                proToggleCell.isUserInteractionEnabled = false
                proSwitch.thumbTintColor = UIColor.systemGray
                configureTheme(theme: AppTheme.LIGHT) // Reset theme in case
            }
        }
        else{
            // Not purchased as default
            print("No key for pro version!")
            defaults.set(false, forKey: "IsProEnabled")
        }
        
        // Look for key that determines theme and configure
        if defaultsHasKey(key: "ProTheme") {
            let intTheme: Int = defaults.object(forKey: "ProTheme") as! Int
            print("Pro theme status: \(String(describing: AppTheme.init(rawValue: intTheme)))")
            configureTheme(theme: AppTheme(rawValue: intTheme)!)
        }
        else {
            // Set light theme by default
            print("No key for current pro theme!")
            print(AppTheme.LIGHT.rawValue)
            defaults.set(AppTheme.LIGHT.rawValue, forKey: "ProTheme")
        }
    }
    
    // Reusable helper function to set the colors of the theme
    func configureTheme(theme: AppTheme) {
        let defaults = UserDefaults.standard
        if theme == AppTheme.DARK {
            proSwitch.isOn = true // On if the theme was selected
            overrideUserInterfaceStyle = .dark
            pinchSwitch.onTintColor = UIColor.systemRed
            proSwitch.onTintColor = UIColor.systemRed
            versionLabel.textColor = UIColor.systemRed
            purchaseProCell.tintColor  = UIColor.systemRed
            defaults.set(AppTheme.DARK.rawValue, forKey: "ProTheme")
        }
        else if theme == AppTheme.LIGHT {
            proSwitch.isOn = false
            overrideUserInterfaceStyle = .light
            pinchSwitch.onTintColor = UIColor.systemGreen
            proSwitch.onTintColor = UIColor.systemGreen
            versionLabel.textColor = UIColor.systemBlue
            purchaseProCell.tintColor  = UIColor.systemBlue
            defaults.set(AppTheme.LIGHT.rawValue, forKey: "ProTheme")
        }
        else {
            print("Error configuring theme - this should never happen!")
        }
    }
    
    // Adjust the pinch switch as needed
    func configurePinch(isEnabled: Bool) {
        let defaults = UserDefaults.standard
        if isEnabled {
            pinchSwitch.isOn = true
            defaults.set(true, forKey: "IsPinchEnabled")
        }
        else {
            pinchSwitch.isOn = false
            defaults.set(false, forKey: "IsPinchEnabled")
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
        let infoURL: URL = URL(string: "https://github.com/sydneylin12/PR-Cam")!
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
    
    // Dismiss the mail popup
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.destination is ViewController {
            let vc = segue.destination as? ViewController
            vc?.isAudioEnabled = true
        }
    } */

}
