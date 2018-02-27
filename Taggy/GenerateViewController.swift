//
//  GenerateViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

class GenerateViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UINavigationControllerDelegate {
    
    var taggyGenerated = false
    var generatePressed = false
    
    @IBAction func generateTaggyButtonPressed(_ sender: UIButton) {
        generatePressed = true
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.generateTaggyButton.frame.origin.y = 30
            }, completion: { finished in
                self.taggyGenerated = true
                var count = 0
                var arrayOfTaggies = [String]()
                var notReleased = false
                ref.observeSingleEvent(of: .value, with: { data in
                    let totalNumberOfTaggies = data.childSnapshot(forPath: "taggies").childrenCount
                    ref.child("taggies").observe(.childAdded, with: { snapshot in
                        count += 1
                        arrayOfTaggies.append(String(snapshot.key))
                        if count == Int(totalNumberOfTaggies) {
                            while notReleased == false {
                                self.randomiseTaggy()
                                if !arrayOfTaggies.contains(colorsString) {
                                    notReleased = true
                                }
                            }
                            self.saveTaggyButton.isEnabled = true
                            self.saveTaggyButton.backgroundColor = UIColor(red:230.0/255.0, green:25.0/255.0, blue:56.0/255.0, alpha:1.0)
                            if self.segControl.selectedSegmentIndex == 0 {
                                self.taggyGeneratedImageView.isHidden = false
                                self.saveTaggyButton.isHidden = false
                            }
                        }
                    })
                })
        })
    }
    
    @IBAction func saveTaggyButtonPressed(_ sender: UIButton) {
        saveTaggyButton.isEnabled = false
        saveTaggyButton.backgroundColor = UIColor.gray
        let userDetailsRef = ref.child("users").child(currentUser.userId).child("userDetails")
        userDetailsRef.observeSingleEvent(of: .value, with: { snapshot in
            taggyCount = Int(snapshot.childSnapshot(forPath: "taggies").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "addTaggyGenerate"), object: self)
        })
    }
    
    func getNumberOfTaggies() {
        let userDetailsRef = ref.child("users").child(currentUser.userId).child("userDetails")
        userDetailsRef.observeSingleEvent(of: .value, with: { snapshot in
            taggyCount = Int(snapshot.childSnapshot(forPath: "taggies").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "populateArrayGenerate"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "removeOldTaggies"), object: self)
        })
    }
    
    func addTaggy() {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.long
        let currentDateString = dateFormatter.string(from: currentDate)
        print(currentUser.userId)
        let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        currentUser.taggies[0] = []
        currentUser.taggies[1] = []
        var newTaggy = [String:String]()
        if currentUser.taggies[0].count + currentUser.taggies[1].count == taggyCount {
            print(currentUser.taggies)
            newTaggy = ["code":colorsString, "name":"", "description":"", "status":"", "activated":currentDateString]
            currentUser.taggies[0].append(newTaggy)
            taggiesRef.removeAllObservers()
            taggiesRef.childByAutoId().setValue(newTaggy)
        }
        else {
            taggiesRef.observe(.childAdded, with: { snapshot in
                print(snapshot)
                print("moopy")
                if (snapshot.value!["activated"] as! String) != "" {
                    currentUser.taggies[0].append(["code":(snapshot.value!["code"] as! String), "name":(snapshot.value!["name"] as! String), "description":(snapshot.value!["description"] as! String), "status":(snapshot.value!["status"] as! String), "activated":(snapshot.value!["activated"] as! String)])
                }
                else {
                    currentUser.taggies[1].append(["code":(snapshot.value!["code"] as! String), "name":(snapshot.value!["name"] as! String), "description":(snapshot.value!["description"] as! String), "status":(snapshot.value!["status"] as! String), "activated":(snapshot.value!["activated"] as! String)])
                }
                if currentUser.taggies[0].count + currentUser.taggies[1].count == taggyCount {
                    var newTaggy = [String:String]()
                    newTaggy = ["code":colorsString, "name":"", "description":"", "status":"", "activated":currentDateString]
                    currentUser.taggies[0].append(newTaggy)
                    taggiesRef.removeAllObservers()
                    taggiesRef.childByAutoId().setValue(newTaggy)
                }
            })
        }
        let allTaggiesRef = ref.child("taggies")
        let newTaggyRef = allTaggiesRef.child(colorsString)
        newTaggyRef.child("activated").setValue("false")
        newTaggyRef.child("user").setValue(currentUser.userId)
    }
    @IBAction func segControlPressed(_ sender: UISegmentedControl) {
        if segControl.selectedSegmentIndex == 0 {
            generateTaggyButton.isHidden = false
            if taggyGenerated {
                self.saveTaggyButton.isHidden = false
                self.taggyGeneratedImageView.isHidden = false
            }
            unactivatedTableView.isHidden = true
            noUnactivatedTaggiesImageView.isHidden = true
        }
        else {
            generateTaggyButton.isHidden = true
            saveTaggyButton.isHidden = true
            taggyGeneratedImageView.isHidden = true
            unactivatedTableView.isHidden = false
            noUnactivatedTaggiesImageView.isHidden = false
            view.bringSubview(toFront: noUnactivatedTaggiesImageView)
            getNumberOfTaggies()
        }
    }
    
    func downloadTaggy(_ sender:UIButton) {
        colorsString = currentUser.taggies[0][Int(sender.tag)]["code"]!
        let activityViewController = UIActivityViewController(activityItems: [HomeViewController().drawTaggy("string") as UIImage], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    @IBOutlet weak var saveTaggyButton: UIButton!
    @IBOutlet weak var generateTaggyButton: UIButton!
    @IBOutlet weak var taggyGeneratedImageView: UIImageView!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var unactivatedTableView: UITableView!
    @IBOutlet weak var noUnactivatedTaggiesImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generatePressed = false
        getNumberOfTaggies()
        
        self.unactivatedTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        unactivatedTableView.delegate = self
        unactivatedTableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(addTaggy), name: NSNotification.Name(rawValue: "addTaggyGenerate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(populateArray), name: NSNotification.Name(rawValue: "populateArrayGenerate"), object: nil)
        saveTaggyButton.setTitleColor(UIColor(red:213.0/255.0, green:213.0/255.0, blue:213.0/255.0, alpha:1.0), for: .disabled)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func populateArray() {
        currentUser.taggies[0] = []
        currentUser.taggies[1] = []
        if taggyCount == 0 {
            self.unactivatedTableView.reloadData()
        }
        print("cow", currentUser.taggies[0])
        let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        taggiesRef.observe(.childAdded, with: { snapshot in
            if (snapshot.value!["activated"] as! String) != "" {
                print("mouse",currentUser.taggies[0])
                currentUser.taggies[0].append(["code":(snapshot.value!["code"] as! String), "name":(snapshot.value!["name"] as! String), "description":(snapshot.value!["description"] as! String), "status":(snapshot.value!["status"] as! String), "activated":(snapshot.value!["activated"] as! String)])
            }
            else {
                currentUser.taggies[1].append(["code":(snapshot.value!["code"] as! String), "name":(snapshot.value!["name"] as! String), "description":(snapshot.value!["description"] as! String), "status":(snapshot.value!["status"] as! String), "activated":(snapshot.value!["activated"] as! String)])
            }
            print("nice")
            print(currentUser.taggies[0])
            print(currentUser.taggies[1])
            print(taggyCount)
            
            if currentUser.taggies[0].count + currentUser.taggies[1].count == taggyCount {
                taggiesRef.removeAllObservers()
                print("hi!")
                self.unactivatedTableView.reloadData()
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if taggyGenerated == false {
            generateTaggyButton.frame.origin.x = view.frame.width/2-125
            generateTaggyButton.frame.origin.y = view.frame.height/2-40
        }
    }
    
    override func viewDidLayoutSubviews() {
        if generatePressed {
            generateTaggyButton.frame.origin.x = view.frame.width/2-125
            generateTaggyButton.frame.origin.y = 30
        }
        else {
            generateTaggyButton.frame.origin.x = view.frame.width/2-125
            generateTaggyButton.frame.origin.y = view.frame.height/2-40
        }
    }
    
    func randomiseTaggy() {
        colorsString = ""
        for _ in 0 ... 14 {
            let randNum = Int(arc4random_uniform(6))
            if randNum == 0 {
                colorsString += "r"
            }
            else if randNum == 1 {
                colorsString += "g"
            }
            else if randNum == 2 {
                colorsString += "b"
            }
            else if randNum == 3 {
                colorsString += "y"
            }
            else if randNum == 4 {
                colorsString += "p"
            }
            else if randNum == 5 {
                colorsString += "o"
            }
        }
        taggyGeneratedImageView.image = HomeViewController().drawTaggy("string")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("huieagfyfbihud",currentUser.taggies)
        if currentUser.taggies[0].count == 0 {
            print("taggy")
            print(noUnactivatedTaggiesImageView.isHidden)
            noUnactivatedTaggiesImageView.image = UIImage(named:"noUnactivatedTaggies")
        }
        else {
            print("nutty")
            noUnactivatedTaggiesImageView.image = UIImage(named:"nothing")
        }
        return currentUser.taggies[0].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnactivatedTableViewCell", for: indexPath) as! UnactivatedTableViewCell
        colorsString = currentUser.taggies[0][indexPath.row]["code"]!
        cell.taggyImageView.image = HomeViewController().drawTaggy("string")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.long
        print(currentUser.taggies[0][indexPath.row]["activated"]!)
        var convertedDate = dateFormatter.date(from: currentUser.taggies[0][indexPath.row]["activated"]!)
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.day, .month, .year], from: convertedDate!)
        components.day += 7
        convertedDate = calendar.date(from: components)!
        let convertedDateString = dateFormatter.string(from: convertedDate!)
        cell.activationDateLabel.text = "Activate before " + convertedDateString
        cell.downloadTaggyButton.addTarget(self, action: #selector(downloadTaggy(_:)), for: .touchUpInside)
        cell.downloadTaggyButton.tag = indexPath.row
        cell.activationDateLabel.adjustsFontSizeToFitWidth = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        var codeToBeDeleted = ""
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
            let taggiesQuery = taggiesRef.queryOrderedByKey()
            taggiesQuery.observe(.childAdded, with: { snapshot in
                print("cal",currentUser.taggies[0])
                if (snapshot.value!["code"] as! String) == currentUser.taggies[0][indexPath.row]["code"] {
                    codeToBeDeleted = currentUser.taggies[0][indexPath.row]["code"]!
                    currentUser.taggies[0][indexPath.row].removeAll()
                    taggiesRef.child(snapshot.key).removeValue()
                    self.getNumberOfTaggies()
                }
            })
            let allTaggiesRef = ref.child("taggies")
            allTaggiesRef.observe(.childAdded, with: { snapshot in
                print("wal",snapshot)
                print("bal", snapshot.key)
                print("hal",currentUser.taggies[0])
                if snapshot.key == codeToBeDeleted {
                    allTaggiesRef.child(snapshot.key).removeValue()
                }
            })
        }
    }
}
