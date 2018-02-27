//
//  TaggyDetailViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class TaggyDetailViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    var currentlyEditing = false
    var nameCell : TaggyDetailTableViewCell!
    var descriptionCell : TaggyDetailTableViewCell!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var taggyImageView: UIImageView!
    @IBOutlet weak var taggyDetailTableView: UITableView!
    
    @IBAction func downloadButtonPressed(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [HomeViewController().drawTaggy("string") as UIImage], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        HomeViewController().getNumberOfTaggies()
        dismiss(animated: true, completion: nil)
    }
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        if currentlyEditing == false {
            taggyDetailTableView.isScrollEnabled = true
            editButton.title = "Save"
            currentlyEditing = true
            nameCell.nameTextField.isUserInteractionEnabled = true
            descriptionCell.descriptionTextView.isEditable = true
            nameCell.nameTextField.becomeFirstResponder()
        }
        else {
            self.view.endEditing(true)
            if nameCell.nameTextField.text == "" || nameCell.nameTextField.text == "Please enter Name" {
                nameCell.nameTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                nameCell.nameTextField.text = "Please enter Name"
            }
            else {
            taggyDetailTableView.isScrollEnabled = false
            currentlyEditing = false
            editButton.title = "Edit"
            nameCell.nameTextField.isUserInteractionEnabled = false
            descriptionCell.descriptionTextView.isEditable = false
            let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
            let taggiesQuery = taggiesRef.queryOrderedByKey()
            taggiesQuery.observe(.childAdded, with: { snapshot in
                if snapshot.value!["code"] as! String == currentUser.taggies[1][globalIndex]["code"] {
                    print("man")
                    currentUser.taggies[1][globalIndex]["name"] = self.nameCell.nameTextField.text
                    currentUser.taggies[1][globalIndex]["description"] = self.descriptionCell.descriptionTextView.text
                    taggiesRef.child(snapshot.key).child("name").setValue(self.nameCell.nameTextField.text)
                    taggiesRef.child(snapshot.key).child("description").setValue(self.descriptionCell.descriptionTextView.text)
                    if currentUser.taggies[1][globalIndex]["status"] == "lost" {
                        ref.child("taggies").child(currentUser.taggies[1][globalIndex]["code"]!).child("taggyName").setValue(self.nameCell.nameTextField.text)
                    }
                }
            })
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.taggyDetailTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        taggyDetailTableView.delegate = self
        taggyDetailTableView.dataSource = self
        print(globalIndex)
        print(currentUser.taggies[1])
        colorsString = currentUser.taggies[1][globalIndex]["code"]!
        taggyImageView.image = HomeViewController().drawTaggy("string")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TaggyDetailViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        taggyDetailTableView.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameCell.nameTextField.text = currentUser.taggies[1][globalIndex]["name"]!
        descriptionCell.descriptionTextView.text = currentUser.taggies[1][globalIndex]["description"]!
        if descriptionCell.descriptionTextView.text == "" {
            descriptionCell.descriptionTextView.text = "No description"
        }
    }
    
    @IBAction func nameTextFieldPressed(_ sender: AnyObject) {
        if nameCell.nameTextField.text == "Please enter Name" {
            nameCell.nameTextField.textColor = UIColor.black
            nameCell.nameTextField.text = ""
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Taggy Details"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = taggyDetailTableView.dequeueReusableCell(withIdentifier: "TaggyDetailTableViewCell", for: indexPath) as! TaggyDetailTableViewCell
        if indexPath.row == 0 {
            cell.nameTextField.isHidden = false
            cell.descriptionTextView.isHidden = true
            cell.nameTextField.delegate = self
            nameCell = cell
        }
        else {
            cell.nameTextField.isHidden = true
            cell.descriptionTextView.isHidden = false
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
        if descriptionCell.descriptionTextView.text == "Description" || descriptionCell.descriptionTextView.text == "No description" {
            textView.textColor = UIColor.black
            textView.text = ""
        }
        taggyDetailTableView.setContentOffset(CGPoint(x: 0,y: 80), animated: true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func hideKeyboard() {
        taggyDetailTableView.endEditing(true)
        taggyDetailTableView.setContentOffset(CGPoint(x: 0,y: 0), animated: true)
    }
}
