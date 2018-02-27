//
//  AppDelegate.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class User {
    var userId : String
    var firstName : String
    var lastName : String
    var email : String
    var taggies = [[[String:String]]](repeating: [], count: 2)
    var messages : [JSQMessage]
    
    init(userId:String, firstName:String, lastName:String, email:String, taggies:[[[String:String]]], messages:[JSQMessage]) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.taggies = taggies
        self.messages = messages
    }
}

var currentUser : User!
var waitToLoad = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    override init() {
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = false
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification),name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        if FIRInstanceID.instanceID().token() != nil {
            let token = FIRInstanceID.instanceID().token()!
            print("cat",token)
        }
        waitToLoad = true
       /* if NSUserDefaults.standardUserDefaults().stringForKey("emailLogIn") != nil && NSUserDefaults.standardUserDefaults().stringForKey("passwordLogIn") != nil {
            FIRAuth.auth()?.signInWithEmail(NSUserDefaults.standardUserDefaults().stringForKey("emailLogIn")!, password: NSUserDefaults.standardUserDefaults().stringForKey("passwordLogIn")!) { (user, error) in
                let currentUserDetailsRef = ref.child("users").child(user!.uid).child("userDetails")
                currentUserDetailsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                    currentUser = User(userId: user!.uid, firstName: snapshot.value!["firstname"] as! String, lastName: snapshot.value!["lastname"] as! String, taggies: [[],[]], messages: [])
                    print(currentUser.firstName)
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let initialViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
                    self.window?.rootViewController = initialViewController
                    self.window?.makeKeyAndVisible()
                })
            }
        }*/

        
        let font = UIFont(name: "OpenSans", size: 14)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.white]
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print(deviceToken)
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: .unknown)
        print(token)
        print(deviceToken)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if FIRInstanceID.instanceID().token() != nil {
            let refreshedToken = FIRInstanceID.instanceID().token()!
            print("InstanceID token: \(refreshedToken)")
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print("Failed to register:", error)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        FIRMessaging.messaging().connect { error in
            print(error)
        }
        if tb != nil {
            tb.tabBar.items![3].badgeValue = String(application.applicationIconBadgeNumber)
            if tb.tabBar.items![3].badgeValue == "0" {
                print("hi!34gr")
                tb.tabBar.items![3].badgeValue = nil
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        //print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
        let currentUserRef = ref.child("users").child(currentUser.userId)
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            let badgeCount = snapshot.childSnapshot(forPath: "badge").childrenCount
            var totalNumberOfBadges = 0
            var count = 0
            let currentUserBadgeRef = currentUserRef.child("badge")
            currentUserBadgeRef.observe(.childAdded, with: { data in
                totalNumberOfBadges += data.value as! Int
                count += 1
                if count == Int(badgeCount) {
                    tb.tabBar.items![3].badgeValue = String(totalNumberOfBadges)
                    application.applicationIconBadgeNumber = totalNumberOfBadges
                }
            })
        })
        print("%@", userInfo)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
