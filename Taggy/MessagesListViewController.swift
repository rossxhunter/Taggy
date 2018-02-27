//
//  MessagesListViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit

var otherUser : User!
var shouldUpdate = false

class MessagesListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var messagesListTableView: UITableView!
    @IBOutlet weak var noMessagesImageView: UIImageView!
    
    var sections : Array<String> = []
    var userIds = Array(repeating: [String](), count: 2)
    var lastMessages = Array(repeating: [String](), count: 2)
    var actualCount = 0
    var maxCount = 0
    var isSender = true
    var specialCase = false
    var newMessage = ""
    var refreshControl: UIRefreshControl!
    var shouldSegue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messagesListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        messagesListTableView.delegate = self
        messagesListTableView.dataSource = self
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MessagesListViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        messagesListTableView.addSubview(refreshControl)
        findMessageCount()
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesListViewController.reloadMessages), name: NSNotification.Name(rawValue: "reload"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesListViewController.findMessages), name: NSNotification.Name(rawValue: "getMessages"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesListViewController.findMessageCount), name: NSNotification.Name(rawValue: "getMessageCount"), object: nil)
        print("kaka", navigationController)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(_ sender:AnyObject) {
        findMessageCount()
    }
    
    // MARK: - Table view data source
    
    func findMessageCount() {
        let currentUserRef = ref.child("users").child(currentUser.userId)
        let queryCount = currentUserRef.queryOrderedByKey()
        queryCount.observe(.value, with : { (snapshot) in
            if snapshot.hasChild("messages") {
                if Int(snapshot.childSnapshot(forPath: "messages").childrenCount) > self.maxCount && self.maxCount != 0 {
                    for child in snapshot.childSnapshot(forPath: "messages").children {
                        self.newMessage = (child as AnyObject).value!["senderId"] as! String
                    }
                }
                else {
                    self.newMessage = ""
                }
                self.actualCount = Int(snapshot.childSnapshot(forPath: "messages").childrenCount)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "getMessages"), object: self)
            }
        })
    }
    
    func findMessages() {
        var counter = 0
        userIds = Array(repeating: [String](), count: 2)
        sections = []
        var people = [String:Bool]()
        var adjustedCount = 0
        let messagesRef = ref.child("users").child(currentUser.userId).child("messages")
        let query = messagesRef.queryOrderedByKey()
        query.observe(.childAdded, with: { (snapshot) in
            counter += 1
            let newReceiver = (snapshot.value as? NSDictionary)?["receiverId"] as? String ?? ""
            let newSender = (snapshot.value as? NSDictionary)?["senderId"] as? String ?? ""
            var newPerson = ""
            if newReceiver != currentUser.userId {
                newPerson = newReceiver
            }
            else {
                newPerson = newSender
            }
            if people.index(forKey: newPerson) == nil {
                if newSender == currentUser.userId {
                    people[newPerson] = true
                }
                else {
                    people[newPerson] = false
                }
            }
            self.isSender = people[newPerson]!
            var senderIndex = 0
            if self.isSender == true {
                senderIndex = 1
            }
            if !self.userIds[senderIndex].contains(newPerson) {
                if self.isSender == true{
                    if !self.sections.contains("Taggies you've found") {
                        self.sections.append("Taggies you've found")
                    }
                    
                }
                else {
                    if !self.sections.contains("Taggies you've lost") {
                        self.sections.insert("Taggies you've lost", at: 0)
                    }
                }
                self.userIds[senderIndex] += [newPerson]
                self.lastMessages[senderIndex].append(String(describing: (snapshot.value as? NSDictionary)?["text"]))
                adjustedCount += 1
            }
            else {
                var found = false
                var i = 0
                while i < self.userIds[senderIndex].count && found == false {
                    if self.userIds[senderIndex][i] == newPerson {
                        found = true
                    }
                    i += 1
                }
                self.lastMessages[senderIndex][i-1] = (snapshot.value as? NSDictionary)?["text"] as! String
            }
            if counter == self.actualCount {
                self.maxCount = counter
                self.actualCount = adjustedCount
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: self)
            }
        })
    }
    
    func reloadMessages() {
        messagesListTableView.reloadData()
        refreshControl?.endRefreshing()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if sections.count == 0 {
            noMessagesImageView.isHidden = false
        }
        else {
            noMessagesImageView.isHidden = true
        }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var newSection = section
        specialCase = false
        if sections.count != 2 {
            if isSender == true {
                newSection += 1
                specialCase = true
            }
        }
        print("sarah",userIds[newSection])
        return userIds[newSection].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessagesListTableViewCell", for: indexPath) as! MessagesListTableViewCell
        var additional = 0
        if specialCase == true {
            additional = 1
        }
        let usersRef = ref.child("users")
        let otherUserDetailsRef = usersRef.child(userIds[indexPath.section+additional][indexPath.row]).child("userDetails")
        otherUserDetailsRef.observe(.value, with: { snapshot in
            if (snapshot.value as? NSDictionary)?["firstname"] != nil {
                cell.nameLabel.text = ((snapshot.value as? NSDictionary)?["firstname"] as? String ?? "") + " " + ((snapshot.value as? NSDictionary)?["lastname"] as? String ?? "")
            }
        })
        let lastMessage = lastMessages[indexPath.section+additional]
        cell.messageLabel.text = lastMessage[indexPath.row]
        
        let otherBadgeRef = usersRef.child(currentUser.userId).child("badge")
        print(userIds[indexPath.section+additional][indexPath.row])
        otherBadgeRef.observeSingleEvent(of: .value, with: { snapshot in
            print(snapshot)
            print(self.userIds)
            print(indexPath.section)
            print(indexPath.row)
          
            if ((snapshot.value as? NSDictionary)?[self.userIds[indexPath.section+additional][indexPath.row]] as? Int ?? 0) > 0 {
                cell.newMessagesImageView.isHidden = false
            }
            else {
                print("doggy",snapshot)
                print("ratty", (snapshot.value as? NSDictionary)?[self.userIds[indexPath.section+additional][indexPath.row]] as? Int ?? 0)
                cell.newMessagesImageView.isHidden = true
            }
            otherBadgeRef.removeAllObservers()
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var additional = 0
        if specialCase == true {
            additional = 1
        }
        let indexPath = tableView.indexPathForSelectedRow!
        let usersRef = ref.child("users")
        let otherUserDetailsRef = usersRef.child(userIds[indexPath.section+additional][indexPath.row]).child("userDetails")
        tableView.deselectRow(at: indexPath, animated: true)
        otherUser = User(userId:userIds[indexPath.section+additional][indexPath.row], firstName: "", lastName: "", email: "", taggies: [[],[]],messages: [])
        shouldUpdate = true
    }
}
