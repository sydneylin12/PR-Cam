//
//  SettingsTableViewController.swift
//  PR Cam
//
//  Created by Sydney Lin on 2/16/20.
//  Copyright © 2020 Sydney Lin. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    //@IBOutlet weak var audioSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    
    var isAudioEnabled: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Supress the errors about width/height constraint
        self.tableView.rowHeight = 44
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = version
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // Return number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    // Return number of rows in each section
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
        else {
            return 0
        }
    }
    
    /* to be used with settings update
    @IBAction func onAudioSwitchChanged(_ sender: UISwitch) {
        print("Switch changed")
    } */
    
    // Handles interaction at an index path [a, b]
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = indexPath.item // Second index b of the array [a, b]
        if idx == 0 {
            infoPressed()
        }
        if idx == 1 {
            sharePressed()
        }
        if idx == 2 {
            contactPressed()
        }
        // De-select after finished
        self.tableView.deselectRow(at: indexPath, animated: true)
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
