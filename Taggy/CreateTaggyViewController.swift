//
//  CreateTaggyViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import Firebase

class CreateTaggyViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var taggyAdded = false
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var loadingView: UIView = UIView()
    var descriptionCleared = false
    var nameCell : CreateTaggyTableViewCell!
    var descriptionCell : CreateTaggyTableViewCell!
    
    
    @IBOutlet weak var createTaggyTableView: UITableView!
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "clearBlur"), object: self)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("sdf")
        if nameCell.nameTextField.text == "" || nameCell.nameTextField.text == "Please enter Name" {
            print("sdfgre")
            nameCell.nameTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
            nameCell.nameTextField.text = "Please enter Name"
        }
        else {
            print("dfs")
            showActivityIndicator()
            let userDetailsRef = ref.child("users").child(currentUser.userId).child("userDetails")
            userDetailsRef.observeSingleEvent(of: .value, with: { snapshot in
                taggyCount = Int(snapshot.childSnapshot(forPath: "taggies").childrenCount)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "addTaggy"), object: self)
            })
        }
    }
    
    
    
    @IBAction func nameTextFieldPressed(_ sender: AnyObject) {
        if nameCell.nameTextField.text == "Please enter Name" {
         nameCell.nameTextField.textColor = UIColor.black
         nameCell.nameTextField.text = ""
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.loadingView = UIView()
            self.loadingView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
            self.loadingView.center = self.view.center
            self.loadingView.backgroundColor = UIColor(red:44.0/255.0, green:44.0/255.0, blue:44.0/255.0, alpha:0.5)
            self.loadingView.alpha = 0.7
            self.loadingView.clipsToBounds = true
            self.loadingView.layer.cornerRadius = 10
            
            self.spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.center = CGPoint(x:self.loadingView.bounds.size.width / 2, y:self.loadingView.bounds.size.height / 2)
            
            self.loadingView.addSubview(self.spinner)
            self.view.addSubview(self.loadingView)
            self.spinner.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
    
    func addTaggy() {
        print("rwg")
        var newTaggyCode = ""
        for i in 0 ... 14 {
            if colorsArray[i] == "red" {
                newTaggyCode += "r"
            }
            else if colorsArray[i] == "blue" {
                newTaggyCode += "b"
            }
            else if colorsArray[i] == "green" {
                newTaggyCode += "g"
            }
            else if colorsArray[i] == "purple" {
                newTaggyCode += "p"
            }
            else if colorsArray[i] == "orange" {
                newTaggyCode += "o"
            }
            else if colorsArray[i] == "yellow" {
                newTaggyCode += "y"
            }
        }
        if descriptionCell.descriptionTextView.text == "Description" {
            descriptionCell.descriptionTextView.text = ""
        }
        createTaggyTableView.reloadData()
        let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        var newTaggy = [String:String]()
        newTaggy = ["code":newTaggyCode, "name":nameCell.nameTextField.text!, "description":descriptionCell.descriptionTextView.text, "status":"notlost", "activated":""]
        var i = 0
        while i < currentUser.taggies[0].count-1 {
            print("here", currentUser.taggies[0].count)
            print(currentUser.taggies[0])
            print(currentUser.taggies[1])
            if currentUser.taggies[0][i]["code"] == newTaggyCode {
                currentUser.taggies[0].remove(at: i)
                i -= 1
                currentUser.taggies[1].append(newTaggy)
            }
            i += 1
        }
        
        taggiesRef.observe(.childAdded, with: { snapshot in
            print(snapshot)
            print(taggyCount)
            print(currentUser.taggies[0].count + currentUser.taggies[1].count)
            if ((snapshot.value as? NSDictionary)?["code"] as? String ?? "") == newTaggyCode {
                print("er")
                print("elephant")
                taggiesRef.removeAllObservers()
                taggiesRef.child(snapshot.key).setValue(newTaggy)
                self.hideActivityIndicator()
                print(currentUser.taggies)
                print("cat", currentUser.taggies[1])
                HomeViewController().getNumberOfTaggies()
                self.dismiss(animated: true, completion: nil)
            }
        })
        
        
        let allTaggiesRef = ref.child("taggies")
        allTaggiesRef.observe(.childAdded, with: { snapshot in
            if snapshot.key == newTaggyCode {
                allTaggiesRef.child(snapshot.key).child("activated").setValue("true")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionCleared = false
        self.createTaggyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        createTaggyTableView.delegate = self
        createTaggyTableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(CreateTaggyViewController.addTaggy), name: NSNotification.Name(rawValue: "addTaggy"), object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CreateTaggyViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        createTaggyTableView.addGestureRecognizer(tapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Name and describe your taggy"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = createTaggyTableView.dequeueReusableCell(withIdentifier: "CreateTaggyTableViewCell", for: indexPath) as! CreateTaggyTableViewCell
        if indexPath.row == 0 {
            cell.nameTextField.isHidden = false
            cell.descriptionTextView.isHidden = true
            cell.nameTextField.delegate = self
            nameCell = cell
        }
        else {
            cell.nameTextField.isHidden = true
            cell.descriptionTextView.isHidden = false
            cell.descriptionTextView.textColor = UIColor(red:188.0/255.0, green:188.0/255.0, blue:197.0/255.0, alpha:0.7)
            cell.descriptionTextView.text = "Description"
            cell.descriptionTextView.delegate = self
            descriptionCell = cell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView!, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60
        }
        else {
            return 150
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        descriptionCell.descriptionTextView.becomeFirstResponder()
        return false
    }
    
   /* func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }*/
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionCell.descriptionTextView.text == "Description" {
            descriptionCleared = true
            textView.textColor = UIColor.black
            textView.text = ""
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func hideKeyboard() {
        createTaggyTableView.endEditing(true)
    }
}
