//
//  MessagesViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase

class MessagesViewController: JSQMessagesViewController {
    
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var userIsTypingRef : FIRDatabaseReference!
    var otherDevicesArray = [String]()
    var otherDevicesStatusArray = [String]()
    var badgeCount = 0
    var messageText = ""
    var newMessage = false
    
    fileprivate var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            if userIsTypingRef != nil {
                userIsTypingRef.setValue(newValue)
            }
        }
    }
    var usersTypingQuery: FIRDatabaseQuery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.inputToolbar.contentView.leftBarButtonItem = nil
        let usersRef = ref.child("users")
        let otherUserDetailsRef = usersRef.child(otherUser.userId).child("userDetails")
        otherUserDetailsRef.observe(.value, with: { snapshot in
            otherUser.firstName = (snapshot.value as? NSDictionary)?["firstname"] as? String ?? ""
            otherUser.lastName = (snapshot.value as? NSDictionary)?["lastname"] as? String ?? ""
            self.title = otherUser.firstName + " " + otherUser.lastName
        })
        currentUser.messages = []
        self.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        self.navigationItem.backBarButtonItem?.title = "Back"
        senderId = currentUser.userId
        senderDisplayName = ""
        NotificationCenter.default.addObserver(self, selector: #selector(sendNotification), name: NSNotification.Name(rawValue: "sendNotificationMessages"), object: nil)
        checkDevices()
        print("lala")
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        setupBubbles()
    }
    
    func checkDevices() {
        otherDevicesArray = []
        otherDevicesStatusArray = []
        let otherDevicesRef = ref.child("users").child(otherUser.userId).child("devices")
        otherDevicesRef.observe(.childAdded, with: { snapshot in
            self.otherDevicesArray.append(snapshot.key )
            self.otherDevicesStatusArray.append(snapshot.value as! String)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldUpdate {
            shouldUpdate = false
            newMessage = false
            print("meely")
            print(currentUser.messages)
            observeMessages()
        }
        
        observeTyping()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return currentUser.messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return currentUser.messages.count
    }
    
    fileprivate func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleRed())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = currentUser.messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
            
        } else {
            return incomingBubbleImageView
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        //let avatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "pp"), diameter: 100)
        return nil
    }
    
    func addMessage(_ theSenderId: String, theReceiverId:String, text: String) {
        let message = JSQMessage(senderId: theSenderId, displayName: theReceiverId, text: text)
        currentUser.messages.append(message!)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 24 || indexPath.row == currentUser.messages.count-1 {
            scrollToBottom(animated: true)
            let otherBadgeRef = ref.child("users").child(currentUser.userId).child("badge").child(otherUser.userId)
            otherBadgeRef.observeSingleEvent(of: .value, with: { snapshot in
                UIApplication.shared.applicationIconBadgeNumber -= snapshot.value as! Int
                var tabBarBadge = tb.tabBar.items![3].badgeValue
                if tabBarBadge == nil {
                    tabBarBadge = "0"
                }
                tb.tabBar.items![3].badgeValue = String(Int(tabBarBadge!)! - (snapshot.value as! Int))
                if Int(tb.tabBar.items![3].badgeValue!)! < 1 {
                    tb.tabBar.items![3].badgeValue = nil
                }
            })
            otherBadgeRef.setValue(0)
        }
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
            as! JSQMessagesCollectionViewCell
        
        let message = currentUser.messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: Date!) {
        checkDevices()
        let usersRef = ref.child("users")
        let messagesRef = usersRef.child(currentUser.userId).child("messages")
        let itemRef = messagesRef.childByAutoId()
        let messageItem = ["text": text, "senderId": senderId, "receiverId": otherUser.userId]
        itemRef.setValue(messageItem)
        let itemRefRec = usersRef.child(otherUser.userId).child("messages").childByAutoId()
        itemRefRec.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        isTyping = false
        messageText = text
        newMessage = true
        getNumberOfBadges()
    }
    
    func getNumberOfBadges() {
        let otherUserRef = ref.child("users").child(otherUser.userId)
        otherUserRef.observeSingleEvent(of: .value, with: { (data) in
            self.badgeCount = Int(data.childSnapshot(forPath: "badge").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "sendNotificationMessages"), object: self)
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
        let currentBadgeRef = ref.child("users").child(otherUser.userId).child("badge")
        var totalBadgeCount = 0
        var count = 0
        currentBadgeRef.observe(.childAdded, with: { (data) in
            print("malawa",data)
            if data.key == currentUser.userId {
                currentBadgeRef.child(currentUser.userId).setValue((data.value as! Int)+1)
            }
            totalBadgeCount += data.value as! Int
            print("balawa",data)
            count += 1
            if count == self.badgeCount {
                for i in 0 ... self.otherDevicesArray.count-1 {
                    print(self.otherDevicesStatusArray)
                    if self.otherDevicesStatusArray[i] == "loggedin" {
                    let notif = ["body":currentUser.firstName + " " + currentUser.lastName + ": " + self.messageText, "badge":String(totalBadgeCount+1)]
                    var priority = ""
                    
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
            }
        })
    }
    
    fileprivate func observeMessages() {
        let messagesRef = ref.child("users").child(currentUser.userId).child("messages")
        let messagesQuery = messagesRef.queryLimited(toLast: 25)
        messagesQuery.observe(.childAdded, with: { (snapshot) in
            let theSenderId = (snapshot.value as? NSDictionary)?["senderId"] as? String ?? ""
            let theReceiverId = (snapshot.value as? NSDictionary)?["receiverId"] as? String ?? ""
            let text = (snapshot.value as? NSDictionary)?["text"] as? String ?? ""
            if (theReceiverId == self.senderId && theSenderId == otherUser.userId) || (theReceiverId == otherUser.userId && theSenderId == self.senderId) {
                self.addMessage(theSenderId, theReceiverId: theReceiverId, text: text)
            }
            self.finishReceivingMessage()
        })
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
    
    fileprivate func observeTyping() {
        let usersRef = ref.child("users")
        let currentUserRef = usersRef.child(currentUser.userId)
        let typingIndicatorRef = currentUserRef.child("typingIndicator")
        userIsTypingRef = usersRef.child(otherUser.userId).child("typingIndicator").child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        usersTypingQuery.observe(.value, with: { (data) in
            self.showTypingIndicator = data.hasChild(otherUser.userId)
            self.scrollToBottom(animated: true)
        })
    }
}
