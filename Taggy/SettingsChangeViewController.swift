//
//  SettingsChangeViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 11/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsChangeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UINavigationControllerDelegate {

    var cell1 : SettingsChangeTableViewCell!
    var cell2 : SettingsChangeTableViewCell!
    var cell3 : SettingsChangeTableViewCell!
    var cellsLoaded = false
    var shouldClear = false
    var selectedRow = 0
    
    @IBAction func settingsChangeTextViewPressed(_ sender: UITextField) {
        shouldClear = true
        redo = false
        selectedRow = sender.tag
        settingsChangeTableView.reloadData()
        print("mika",selectedRow)
        settingsChangeTableView.setContentOffset(CGPoint(x: 0,y: 70*CGFloat(selectedRow)), animated: true)
    }
        
    @IBOutlet weak var settingsChangeTableView: UITableView!
    
    var valid = true
    var redo = true
    
    @IBAction func saveButton(_ sender: AnyObject) {
        
        valid = true
        redo = false
        settingsChangeTableView.reloadData()
        if !cellsLoaded {
            cell1 = settingsChangeTableView.dequeueReusableCell(withIdentifier: "SettingsChangeTableViewCell", for: IndexPath(row: 0, section: 0)) as! SettingsChangeTableViewCell
            if textFieldsArray.contains("First Name") {
                cell2 = settingsChangeTableView.dequeueReusableCell(withIdentifier: "SettingsChangeTableViewCell", for: IndexPath(row: 1, section: 0)) as! SettingsChangeTableViewCell
            }
            else if textFieldsArray.contains("New Password") {
                cell2 = settingsChangeTableView.dequeueReusableCell(withIdentifier: "SettingsChangeTableViewCell", for: IndexPath(row: 1, section: 0)) as! SettingsChangeTableViewCell
            }
            cellsLoaded = true
        }
        
        if textFieldsArray.contains("First Name") {
            checkForEmptyField(cell1.settingsChangeTextField, correction: "Please enter first name")
            checkForEmptyField(cell2.settingsChangeTextField, correction: "Please enter last name")
            if valid {
                currentUser.firstName = cell1.settingsChangeTextField.text!
                currentUser.lastName = cell2.settingsChangeTextField.text!
                ref.child("users").child(currentUser.userId).child("userDetails").child("firstname").setValue(currentUser.firstName)
                ref.child("users").child(currentUser.userId).child("userDetails").child("lastname").setValue(currentUser.lastName)
                self.navigationController?.popViewController(animated: true)
            }
        }
        else if textFieldsArray.contains("Email") {
            checkForEmptyField(cell1.settingsChangeTextField, correction: "Please enter email")
            if valid {
                FIRAuth.auth()?.currentUser?.updateEmail(cell1.settingsChangeTextField.text!) { error in
                    if let error = error {
                        if error.code == FIRAuthErrorCode.errorCodeInvalidEmail.rawValue {
                            self.cell1.settingsChangeTextField.text = "Email is invalid"
                            self.cell1.settingsChangeTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                        }
                        self.valid = false
                        return
                    }
                    else {
                        currentUser.email = self.cell1.settingsChangeTextField.text!
                        UserDefaults.standard.set(currentUser.email, forKey: "emailLogIn")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
        else{
            checkForEmptyField(cell1.settingsChangeTextField, correction: "Please enter new password")
            checkForEmptyField(cell2.settingsChangeTextField, correction: "Please confirm new password")
            if valid {
                if cell1.settingsChangeTextField.text != cell2.settingsChangeTextField.text {
                    cell1.settingsChangeTextField.text = "Passwords do not match"
                    cell1.settingsChangeTextField.isSecureTextEntry = false
                    cell1.settingsChangeTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                    cell2.settingsChangeTextField.text = "Passwords do not match"
                    cell2.settingsChangeTextField.isSecureTextEntry = false
                    cell2.settingsChangeTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                    valid = false
                }
            }
            if valid {
                FIRAuth.auth()?.currentUser?.updatePassword(cell2.settingsChangeTextField.text!) { error in
                    if let error = error {
                        if error.code == FIRAuthErrorCode.errorCodeWeakPassword.rawValue {
                            self.cell1.settingsChangeTextField.text = "Password too weak"
                            self.cell2.settingsChangeTextField.text = ""
                            self.cell1.settingsChangeTextField.isSecureTextEntry = false
                            self.cell1.settingsChangeTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                        }
                        self.valid = false
                        return
                    } else {
                        UserDefaults.standard.set(self.cell2.settingsChangeTextField.text!, forKey: "passwordLogIn")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func checkForEmptyField(_ textField : UITextField, correction: String) {
        print(textField.text!)
        if textField.text! == "" || textField.text! == correction {
            textField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
            if textField.isSecureTextEntry == true {
                textField.isSecureTextEntry = false
            }
            textField.text! = correction
            valid = false
        }
    }
    
    func isError(_ textField : UITextField) {
        if textField.textColor! == UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1) {
            textField.text! = ""
            textField.textColor = UIColor.black
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        redo = true
        cellsLoaded = false
        self.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        self.settingsChangeTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        settingsChangeTableView.delegate = self
        settingsChangeTableView.dataSource = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SettingsChangeViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        settingsChangeTableView.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return textFieldsArray.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Change your details here"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsChangeTableView.dequeueReusableCell(withIdentifier: "SettingsChangeTableViewCell", for: indexPath) as! SettingsChangeTableViewCell
        cell.settingsChangeTextField.placeholder = textFieldsArray[indexPath.row]
        if redo == true {
        if textFieldsArray[indexPath.row] == "First Name" {
            cell.settingsChangeTextField.text = currentUser.firstName
            cell.settingsChangeTextField.autocapitalizationType = .words
        }
        else if textFieldsArray[indexPath.row] == "Last Name" {
            cell.settingsChangeTextField.text = currentUser.lastName
            cell.settingsChangeTextField.autocapitalizationType = .words
        }
        else if textFieldsArray[indexPath.row] == "Email" {
            cell.settingsChangeTextField.text = currentUser.email
            cell.settingsChangeTextField.keyboardType = .emailAddress
        }
        else {
            cell.settingsChangeTextField.isSecureTextEntry = true
        }
        }
        cell.settingsChangeTextField.tag = indexPath.row
        if shouldClear {
            if indexPath.row == selectedRow {
                if textFieldsArray.contains("New Password") {
                    cell.settingsChangeTextField.isSecureTextEntry = true
                }
                isError(cell.settingsChangeTextField)
                cell.settingsChangeTextField.becomeFirstResponder()
                shouldClear = false
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("moop")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func hideKeyboard() {
        settingsChangeTableView.endEditing(true)
        settingsChangeTableView.setContentOffset(CGPoint(x: 0,y: 0), animated: true)
    }
}
