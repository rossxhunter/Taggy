//
//  SendMessageViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 10/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class SendMessageViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var badgeCount = 0
    var otherDevicesArray = [String]()
    var messageCell : SendMessageTableViewCell!

    @IBOutlet weak var sendMessageTableView: UITableView!
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func sendButtonPressed(_ sender: UIBarButtonItem) {
        if messageCell.messageTextView.text == "" || messageCell.messageTextView.text == "Please enter Message" || messageCell.messageTextView.text == "Message" {
            messageCell.messageTextView.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
            messageCell.messageTextView.text = "Please enter Message"
        }
        else {
        print("diuhf")
        ref.child("users").child(otherUserForMessage).child("userDetails").child("taggies").child(otherTaggyIndexForMessage).child("status").setValue("found")
        ref.child("users").child(otherUserForMessage).child("badge").child(currentUser.userId).setValue(0)
        ref.child("users").child(currentUser.userId).child("badge").child(otherUserForMessage).setValue(0)
        let usersRef = ref.child("users")
        let messagesRef = usersRef.child(currentUser.userId).child("messages")
        let itemRef = messagesRef.childByAutoId()
        let messageItem = ["text": messageCell.messageTextView.text, "senderId": currentUser.userId, "receiverId": otherUserForMessage] as [String : Any]
        itemRef.setValue(messageItem)
        let itemRefRec = usersRef.child(otherUserForMessage).child("messages").childByAutoId()
        itemRefRec.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        getNumberOfBadges()
        dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sendMessageTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        sendMessageTableView.delegate = self
        sendMessageTableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(sendNotification), name: NSNotification.Name(rawValue: "sendNotificationFirst"), object: nil)
        let otherDevicesRef = ref.child("users").child(otherUserForMessage).child("devices")
        otherDevicesRef.observe(.childAdded, with: { snapshot in
            self.otherDevicesArray.append(snapshot.value as! String)
        })
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SendMessageViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        sendMessageTableView.addGestureRecognizer(tapGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Send a message to the owner"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sendMessageTableView.dequeueReusableCell(withIdentifier: "SendMessageTableViewCell", for: indexPath) as! SendMessageTableViewCell
            cell.messageTextView.textColor = UIColor(red:188.0/255.0, green:188.0/255.0, blue:197.0/255.0, alpha:0.7)
            cell.messageTextView.text = "Message"
            cell.messageTextView.delegate = self
            messageCell = cell
        return cell
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
        if messageCell.messageTextView.text == "Message" || messageCell.messageTextView.text == "Please enter Message" {
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
        sendMessageTableView.endEditing(true)
    }
    
    func getNumberOfBadges() {
        let otherUserRef = ref.child("users").child(otherUserForMessage)
        otherUserRef.observeSingleEvent(of: .value, with: { (data) in
            self.badgeCount = Int(data.childSnapshot(forPath: "badge").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "sendNotificationFirst"), object: self)
            otherUserRef.removeAllObservers()
        })
    }
    
    func sendNotification() {
        let url = "https://fcm.googleapis.com/fcm/send"
        let request : NSMutableURLRequest = NSMutableURLRequest()
        request.url = URL(string: NSString(format: "%@", url) as String)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AIzaSyApjzZYpw_5CrVtralf_eihSoWSieLOfnk", forHTTPHeaderField: "Authorization")
        let currentBadgeRef = ref.child("users").child(otherUserForMessage).child("badge")
        var totalBadgeCount = 0
        var count = 0
        currentBadgeRef.observe(.childAdded, with: { (data) in
            print("malawa",data)
            if data.key == currentUser.userId {
                currentBadgeRef.child(currentUser.userId).setValue((data.value as! Int)+1)
            }
            totalBadgeCount += data.value as! Int
            count += 1
            if count == self.badgeCount {
                for i in 0 ... self.otherDevicesArray.count-1 {
                    let notif = ["body":currentUser.firstName + " " + currentUser.lastName + " has found \"" + otherTaggyNameForMessage + "\". Message: \""  + self.messageCell.messageTextView.text + "\"", "badge":String(totalBadgeCount+1)]
                    let json = ["to":self.otherDevicesArray[i],"priority":"high","notification":notif] as [String : Any]
                    do {
                        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
                    }
                    catch {
                        print(error)
                    }
                    print("catty",request.httpBody)
                    print(json)
                    
                    let task = URLSession.shared.dataTask(with: request, completionHandler: { data,response,error in
                        if error != nil{
                            print(error!.localizedDescription)
                            return
                        }
                        do{
                            let responseJSON = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                            print(responseJSON)
                        }
                        catch {
                            print(error)
                        }
                        
                    })
                    currentBadgeRef.removeAllObservers()
                    task.resume()
                }
            }
        })
    }
}
