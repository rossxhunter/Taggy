//
//  SettingsViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import Firebase

class SettingsOption {
    var optionImage : UIImage
    var optionText : String
    var valueText : String
    
    init(optionImage:UIImage, optionText:String, valueText:String) {
        self.optionImage = optionImage
        self.optionText = optionText
        self.valueText = valueText
    }
}

var textFieldsArray = [String]()

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var settingsArray = Array(repeating: [SettingsOption](), count: 2)
    var sections = [String]()
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.settingsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        setupSettingsTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupSettingsTable()
        settingsTableView.reloadData()
    }
    
    func setupSettingsTable() {
        let nameOption = SettingsOption(optionImage: UIImage(named:"userProfile")!, optionText: "Name", valueText:currentUser.firstName + " " + currentUser.lastName)
        let emailOption = SettingsOption(optionImage: UIImage(named:"userProfile")!, optionText: "Email", valueText:currentUser.email)
        let passwordOption = SettingsOption(optionImage: UIImage(named:"userProfile")!, optionText: "Password", valueText:"")
        let logoutOption = SettingsOption(optionImage: UIImage(named:"logoutIcon")!, optionText: "Logout", valueText:"")
        let aboutOption = SettingsOption(optionImage: UIImage(named:"aboutIcon")!, optionText: "About", valueText:"")
        let feedbackOption = SettingsOption(optionImage: UIImage(named:"feedbackIcon")!, optionText: "Give Feedback", valueText:"")
        settingsArray = [[nameOption, emailOption,passwordOption], [logoutOption, feedbackOption, aboutOption]]
        sections = ["Your Account", "Other"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return settingsArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return settingsArray[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as! SettingsTableViewCell
        cell.settingsIconImageView.image = settingsArray[indexPath.section][indexPath.row].optionImage
        cell.settingsTextLabel.text = settingsArray[indexPath.section][indexPath.row].optionText
        if settingsArray[indexPath.section][indexPath.row].optionText == "Password" {
            cell.passwordTextField.isHidden = false
            cell.passwordTextField.text = "password"
        }
        else {
            cell.passwordTextField.isHidden = true
        }
        cell.settingsValueLabel.text = settingsArray[indexPath.section][indexPath.row].valueText
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                textFieldsArray = ["First Name", "Last Name"]
            }
            else if indexPath.row == 1 {
                textFieldsArray = ["Email"]
            }
            else {
                textFieldsArray = ["New Password", "Confirm Password"]
            }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier: "SettingsChangeViewController")
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        else if indexPath.section == 1 && indexPath.row == 0 {
            logoutConfirmation()
        }
        settingsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func logoutConfirmation() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let logoutAction = UIAlertAction(title: "Logout", style: UIAlertActionStyle.default) {
            UIAlertAction in
            ref.child("users").child(currentUser.userId).child("devices").child(token).setValue("loggedout")
            try! FIRAuth.auth()?.signOut()
            tb.dismiss(animated: false, completion: nil)
            print("logout!")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            print("cancel!")
        }
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
    }
}
