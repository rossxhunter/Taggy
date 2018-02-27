//
//  HomeViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import CoreLocation

struct RGBA32: Equatable {
    var color: UInt32
    
    func red() -> UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    func green() -> UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    func blue() -> UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    func alpha() -> UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
}

func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
    return lhs.color == rhs.color
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = String.CharacterView.index(start, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}

var colorsArray = [String](repeating: "blank", count: 15)
var taggyCount = 0
var taggyFound = false
var x = 0
var y = 0
var size = 0
var picWidth = 0
var picHeight = 0
var globalIndex = 0
var colorsString = ""
var otherCodeForMessage = ""
var otherUserForMessage = ""
var otherTaggyIndexForMessage = ""
var otherTaggyNameForMessage = ""
var latitude : CLLocationDegrees!
var longitude : CLLocationDegrees!
var updateLost = false
var tb : UITabBarController!

class HomeViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource,UIPopoverPresentationControllerDelegate, CLLocationManagerDelegate, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var noTaggiesImageView: UIImageView!
    @IBOutlet weak var homeTableView: UITableView!
    var cellBounds : CGRect!
    var position : CGPoint!
    var alertView : UIView = UIView()
    var text : UILabel = UILabel()
    var indexPathGlobal : IndexPath!
    var scanning = false
    var arrayIndex = 0
    var timer : Timer!
    var statusChanged = false
    let locationManager = CLLocationManager()
    var blurEffectView : UIVisualEffectView = UIVisualEffectView()
    var displayStatus = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        removeOldTaggies()
        tb = tabBarController
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        self.alertView.frame = CGRect(x: view.frame.width/2-100, y: view.frame.height/2-150, width: 200.0, height: 200.0)
        self.alertView.backgroundColor = UIColor(red:44.0/255.0, green:44.0/255.0, blue:44.0/255.0, alpha:0.5)
        self.alertView.alpha = 0.7
        self.alertView.clipsToBounds = true
        self.alertView.layer.cornerRadius = 20
        noTaggiesImageView.isHighlighted = false
        self.homeTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        homeTableView.delegate = self
        homeTableView.dataSource = self
        print(text.text)
        text.textColor = UIColor.white
        text.font = UIFont(name: "OpenSans", size: 20)
        text.sizeToFit()
        text.adjustsFontSizeToFitWidth = true
        text.frame = CGRect(x: self.alertView.frame.width/2-75, y: self.alertView.frame.height/2-75, width: 150, height: 150)
        self.alertView.addSubview(text)
        text.numberOfLines = 0
        text.textAlignment = NSTextAlignment.center
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.askForConfirmation), name: NSNotification.Name(rawValue: "scanned"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.populateArray), name: NSNotification.Name(rawValue: "populateArrayHome"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.showLostStatusChange), name: NSNotification.Name(rawValue: "updateLost"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.removeOldTaggies), name: NSNotification.Name(rawValue: "removeOldTaggies"), object: nil)
        getNumberOfTaggies()
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
                    UIApplication.shared.applicationIconBadgeNumber = totalNumberOfBadges
                    tb.tabBar.items![3].badgeValue = String(UIApplication.shared.applicationIconBadgeNumber)
                    if tb.tabBar.items![3].badgeValue == "0" {
                        tb.tabBar.items![3].badgeValue = nil
                    }
                }
            })
        })
        
        // Do any additional setup after loading the view.
    }
    
   /* override func viewDidAppear(animated: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.homeTableView.reloadData()
        }
    }*/
    
    func removeOldTaggies() {
       /* let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        if taggyCount != 0 {
            taggiesRef.observeEventType(.ChildAdded, withBlock: { snapshot in
                if snapshot.value!["activated"] as! String != "" {
                    let date = snapshot.value!["activated"] as! String
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                    var convertedDate = dateFormatter.dateFromString(date)
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components([.Day, .Month, .Year], fromDate: convertedDate!)
                    components.day += 7
                    convertedDate = calendar.dateFromComponents(components)!
                    let currentDate = NSDate()
                    let convertedCurrentDate = dateFormatter.stringFromDate(currentDate)
                    let dateConvertedCurrentDate = dateFormatter.dateFromString(convertedCurrentDate)
                    print("haka",dateConvertedCurrentDate)
                    print("waka",convertedDate)
                    if convertedDate?.earlierDate(dateConvertedCurrentDate!) == convertedDate {
                        ref.child("users").child(currentUser.userId).child("userDetails").child("taggies").child(snapshot.key).removeValue()
                        ref.child("taggies").observeEventType(.ChildAdded, withBlock: { data in
                            if data.key == snapshot.value!["code"] as! String {
                                ref.child("taggies").child(data.key).removeValue()
                            }
                        })
                        for i in 0 ... currentUser.taggies[0].count-1 {
                            if currentUser.taggies[0][i]["code"] == snapshot.value!["code"] as! String {
                                currentUser.taggies[0].removeAtIndex(i)
                            }
                        }
                    }
                }
            })
        }*/
    }
    
    func getNumberOfTaggies() {
        let userDetailsRef = ref.child("users").child(currentUser.userId).child("userDetails")
        userDetailsRef.observeSingleEvent(of: .value, with: { snapshot in
            taggyCount = Int(snapshot.childSnapshot(forPath: "taggies").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "populateArrayHome"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "removeOldTaggies"), object: self)
        })
    }
    
    func populateArray() {
        print("hick")
        currentUser.taggies[0] = []
        currentUser.taggies[1] = []
        let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        if currentUser.taggies[0].count + currentUser.taggies[1].count == taggyCount {
            self.homeTableView.reloadData()
            if currentUser.taggies[1].count == 0 {
                noTaggiesImageView.isHidden = false
            }
            else {
                noTaggiesImageView.isHidden = true
            }
        }
        else{
            var count = 0
            print("plock")
            taggiesRef.observe(.childAdded, with: { snapshot in
                if (snapshot.value as? NSDictionary)?["activated"] as? String ?? "" == "" {
                    currentUser.taggies[1].append(["code":((snapshot.value as? NSDictionary)?["code"] as? String ?? ""), "name":(snapshot.value as? NSDictionary)?["name"] as? String ?? "", "description":(snapshot.value as? NSDictionary)?["description"] as? String ?? "", "status":((snapshot.value as? NSDictionary)?["status"] as? String ?? ""), "activated":(snapshot.value as? NSDictionary)?["activated"] as? String ?? ""])
                }
                else {
                    currentUser.taggies[0].append(["code":(snapshot.value as? NSDictionary)?["code"] as? String ?? "", "name":(snapshot.value as? NSDictionary)?["name"] as? String ?? "", "description":(snapshot.value as? NSDictionary)?["description"] as? String ?? "", "status":(snapshot.value as? NSDictionary)?["status"] as? String ?? "", "activated":(snapshot.value as? NSDictionary)?["activated"] as? String ?? ""])
                }
                count += 1
                print("check")
                print("hack!!!",currentUser.taggies)
                if currentUser.taggies[0].count + currentUser.taggies[1].count == taggyCount {
                    self.homeTableView.reloadData()
                    if currentUser.taggies[1].count == 0 {
                        self.noTaggiesImageView.isHidden = false
                    }
                    else {
                        self.noTaggiesImageView.isHidden = true
                        print("me" ,currentUser.taggies)
                    }
                    taggiesRef.removeAllObservers()
                }
            })
        }
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
        print("herrw!",currentUser.taggies[1].count)
        return currentUser.taggies[1].count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell", for: indexPath) as! HomeTableViewCell
        colorsString = currentUser.taggies[1][indexPath.row]["code"]!
        cell.taggyNameLabel.text = currentUser.taggies[1][indexPath.row]["name"]!
        if currentUser.taggies[1][indexPath.row]["status"]! == "lost" {
            cell.taggyLostStatusImageView.setImage(UIImage(named:"taggyLost"), for: UIControlState())
        }
        else if currentUser.taggies[1][indexPath.row]["status"]! == "notlost" {
            cell.taggyLostStatusImageView.setImage(UIImage(named:"taggyReturned"), for: UIControlState())
        }
        else {
            cell.taggyLostStatusImageView.setImage(UIImage(named:"taggyFound"), for: UIControlState())
        }
        cell.taggyLostStatusImageView.addTarget(self, action: #selector(displayLostStatus(_:)), for: .touchDown)
        cell.taggyLostStatusImageView.addTarget(self, action: #selector(liftedUp(_:)), for: [.touchUpInside, .touchUpOutside])
        cell.taggyLostStatusImageView.tag = indexPath.row
        print(cell.taggyNameLabel.text)
        print("he",currentUser.taggies)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        displayTaggyDetail(Int(indexPath.row))
        homeTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func displayTaggyDetail(_ index:Int) {
        globalIndex = index
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "homeToTaggyDetail", sender: self)
        }
    }
    
    func displayLostStatus(_ sender: UIButton) {
        statusChanged = false
        displayStatus = true
        arrayIndex = Int(sender.tag)
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkForLostStatus), userInfo: nil, repeats: true)
    }
    
    func liftedUp(_ sender: UIButton) {
        timer.invalidate()
        if statusChanged == false && displayStatus {
        if currentUser.taggies[1][arrayIndex]["status"] == "notlost" {
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " is not lost"
        }
        else if currentUser.taggies[1][arrayIndex]["status"] == "lost" {
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " is currently lost"
        }
        else {
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " has been found"
        }
        self.view.addSubview(self.alertView)
        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.hideLostStatusChange()
        }
        }
    }
    
    func checkForLostStatus() {
        displayStatus = false
        if currentUser.taggies[1][arrayIndex]["status"] == "notlost" {
            print("dsfg")
            timer.invalidate()
            performSegue(withIdentifier: "homeToLostLocation", sender: self)

        }
        else {
            showLostStatusChange()
        }
    }

    
    func showLostStatusChange() {
        var lostStatus = ""
        blurEffectView.removeFromSuperview()
        print("maz")
        if currentUser.taggies[1][arrayIndex]["status"] == "notlost" {
            lostStatus = "lost"
            print(currentUser.taggies[1])
            print(arrayIndex)
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " is now lost"
            if CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
                ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("latitude").setValue(latitude)
                ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("longitude").setValue(longitude)
                ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("taggyName").setValue(currentUser.taggies[1][arrayIndex]["name"]!)
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = DateFormatter.Style.long
                let convertedDate = dateFormatter.string(from: currentDate)
                ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("date").setValue(convertedDate)
            }
        }
        else if currentUser.taggies[1][arrayIndex]["status"] == "lost" {
            lostStatus = "notlost"
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " has been returned"
            ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("latitude").removeValue()
            ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("longitude").removeValue()
            ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("taggyName").removeValue()
            ref.child("taggies").child(currentUser.taggies[1][arrayIndex]["code"]!).child("date").removeValue()
        }
        else {
            lostStatus = "notlost"
            text.text = currentUser.taggies[1][arrayIndex]["name"]! + " has been returned"
        }
        let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
        let taggiesQuery = taggiesRef.queryOrderedByKey()
        taggiesQuery.observe(.childAdded, with: { snapshot in
            if (snapshot.value as? NSDictionary)?["code"] as? String ?? "" == currentUser.taggies[1][self.arrayIndex]["code"] {
                currentUser.taggies[1][self.arrayIndex]["status"] = lostStatus
                taggiesRef.child(snapshot.key).child("status").setValue(lostStatus)
                self.getNumberOfTaggies()
                self.homeTableView.reloadData()
            }
        })
        view.addSubview(self.alertView)
        statusChanged = true
        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.hideLostStatusChange()
            self.timer.invalidate()
        }
    }
    
    func hideLostStatusChange() {
        self.alertView.removeFromSuperview()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        print("center: ",center)
        locationManager.stopUpdatingLocation()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            position = touch.location(in: view)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            var codeToBeDeleted = ""
            let taggiesRef = ref.child("users").child(currentUser.userId).child("userDetails").child("taggies")
            let taggiesQuery = taggiesRef.queryOrderedByKey()
            taggiesQuery.observe(.childAdded, with: { snapshot in
                if (snapshot.value as? NSDictionary)?["code"] as? String ?? "" == currentUser.taggies[1][indexPath.row]["code"] {
                    codeToBeDeleted = currentUser.taggies[1][indexPath.row]["code"]!
                    currentUser.taggies[1][indexPath.row].removeAll()
                    taggiesRef.child(snapshot.key).removeValue()
                    self.getNumberOfTaggies()
                }
            })
            let allTaggiesRef = ref.child("taggies")
            allTaggiesRef.observe(.childAdded, with: { snapshot in
                if snapshot.key == codeToBeDeleted {
                    allTaggiesRef.child(snapshot.key).removeValue()
                }
            })
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
    func checkImage(_ inputImage: UIImage) {
        processPixelsInImage(inputImage)
        
        var taggyValid = true
        for i in 0 ... 14 {
            if colorsArray[i].contains("white") || colorsArray[i].contains("black") || colorsArray[i].contains("blank") {
                taggyValid = false
            }
        }
        taggyFound = taggyValid
    }
    
    func findTaggyInDatabase() {
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
        
        let allTaggiesRef = ref.child("taggies")
        var taggyFoundInTaggiesRef = false
        var count = 0
        ref.observeSingleEvent(of: .value, with: { data in
        let totalNumberOfTaggies = data.childSnapshot(forPath: "taggies").childrenCount
        allTaggiesRef.observe(.childAdded, with:  { snapshot in
            count += 1
            if snapshot.key == newTaggyCode {
                taggyFoundInTaggiesRef = true
                if (snapshot.value as? NSDictionary)?["user"] as? String ?? "" == currentUser.userId {
                    if (snapshot.value as? NSDictionary)?["activated"] as? String ?? "" == "false" {
                        self.performSegue(withIdentifier: "homeToCreateTaggy", sender: self)
                    }
                    else {
                        self.text.text = "Taggy already activated"
                        self.view.addSubview(self.alertView)
                        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            self.alertView.removeFromSuperview()
                        }
                    }
                }
                else {
                    if (snapshot.value as? NSDictionary)?["activated"] as? String ?? "" == "false" {
                        self.text.text = "Taggy not activated yet"
                        self.view.addSubview(self.alertView)
                        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            self.alertView.removeFromSuperview()
                        }
                    }
                    else {
                        otherCodeForMessage = snapshot.key
                        otherUserForMessage = (snapshot.value as? NSDictionary)?["user"] as? String ?? ""
                        
                        ref.child("users").child(otherUserForMessage).child("userDetails").child("taggies").observe(.childAdded, with: { data in
                            if (data.value as? NSDictionary)?["code"] as? String ?? "" == otherCodeForMessage {
                                if (data.value as? NSDictionary)?["status"] as? String ?? "" == "found" {
                                    self.text.text = "Taggy already found"
                                    self.view.addSubview(self.alertView)
                                    let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                                    DispatchQueue.main.asyncAfter(deadline: time) {
                                        self.alertView.removeFromSuperview()
                                    }
                                }
                                else {
                                    otherTaggyIndexForMessage = data.key
                                    otherTaggyNameForMessage = (data.value as? NSDictionary)?["name"] as? String ?? ""
                                    self.performSegue(withIdentifier: "homeToSendMessage", sender: self)
                                }
                            }
                        })
                    }
                }
            }
            if count == Int(totalNumberOfTaggies) && taggyFoundInTaggiesRef == false {
                self.text.text = "Taggy not released yet"
                self.view.addSubview(self.alertView)
                let time = DispatchTime(uptimeNanoseconds: DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.alertView.removeFromSuperview()
                }
            }
        })
        })
        
    }
    
    func askForConfirmation() {
        let validAlert = UIAlertController(title: "Is this it?", message: "\n\n\n\n\n", preferredStyle: UIAlertControllerStyle.alert)
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.findTaggyInDatabase()
        }
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            self.performSegue(withIdentifier: "homeToScanner", sender: self)
        }
        let taggyCheckImageView = UIImageView(frame: CGRect(x: 100, y: 60, width: 80, height: 80))
        taggyCheckImageView.image = drawTaggy("array")
        validAlert.view.addSubview(taggyCheckImageView)
        validAlert.addAction(yesAction)
        validAlert.addAction(noAction)
        self.present(validAlert, animated: true, completion: nil)
    }
    
    func drawTaggy(_ arrayOrString:String) -> UIImage{
        let size = CGSize(width: 1200, height: 1200)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setFillColor(UIColor.red.cgColor)
        context?.setLineWidth(2.0)
        
        var newColorsArray = [String]()
        if arrayOrString == "string" {
            for i in 0 ... 14 {
                newColorsArray.append(colorsString[i])
            }
        }
        else {
            newColorsArray = colorsArray
        }
        
        for j in 0...3 {
            for i in 0...3 {
                if i==0 && j==0 {
                    context?.setFillColor(UIColor.red.cgColor)
                }
                else{
                    switch newColorsArray[(i-1)+(4*j)] {
                    case "red", "r" :
                        context?.setFillColor(UIColor.red.cgColor)
                    case "blue", "b":
                        context?.setFillColor(UIColor.blue.cgColor)
                    case "green", "g":
                        context?.setFillColor(UIColor.green.cgColor)
                    case "yellow", "y":
                        context?.setFillColor(UIColor.yellow.cgColor)
                    case "purple", "p":
                        context?.setFillColor(UIColor.purple.cgColor)
                    case "orange", "o":
                        context?.setFillColor(UIColor.orange.cgColor)
                    case "blank", "white":
                        context?.setFillColor(UIColor.gray.cgColor)
                    default:
                        context?.setFillColor(UIColor.black.cgColor)
                    }
                }
                let square = CGRect(x: CGFloat(0+(i*300)), y: CGFloat(0+(j*300)), width: 300, height: 300)
                context?.fill(square)
            }
            context?.setFillColor(UIColor.white.cgColor)
            let square = CGRect(x: 100, y: 100, width: 100, height: 100)
            context?.fill(square)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func processPixelsInImage(_ inputImage: UIImage) -> UIImage? {
        let inputCGImage     = inputImage.cgImage
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage?.width
        let height           = inputCGImage?.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width!
        let bitmapInfo       = RGBA32.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width!, height: height!, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }
        context.draw(inputCGImage!, in: CGRect(x: 0, y: 0, width: CGFloat(width!), height: CGFloat(height!)))
        
        let pixelBuffer = UnsafeMutablePointer<RGBA32>(context.data)
        
        var currentPixel = pixelBuffer
        var count = 0
        var found = false
        var redcoord = 0
        var whitecoord = 0
        var redcoord2 = 0
        let topleft = pixelBuffer
        currentPixel = topleft
        
        repeat {
            redcoord = logoSearch(currentPixel, colorToFind: "red", minCurrentPixel: pixelBuffer, maxCount: (width/2))
            if  redcoord != 0 {
                currentPixel += redcoord
                whitecoord = logoSearch(currentPixel, colorToFind: "white", minCurrentPixel: pixelBuffer, maxCount: 200)
                if whitecoord != 0 {
                    currentPixel += whitecoord
                    redcoord2 = logoSearch(currentPixel, colorToFind: "red", minCurrentPixel: pixelBuffer, maxCount: 200)
                    if redcoord2 != 0 {
                        found = true
                    }
                    currentPixel -= whitecoord
                    
                }
                currentPixel -= redcoord
            }
            currentPixel += width
            count += 1
        } while count < (height!/2) && found == false
        x = redcoord
        y = count - whitecoord
        size = whitecoord * 12
        picWidth = width!
        picHeight = height!
        colorsArray = [String](repeating: "blank", count: 15)
        if found == true {
            
            var centreOfLogo = topleft + (count*width) + ((whitecoord/2)*width)
            centreOfLogo = centreOfLogo + (redcoord+whitecoord+(whitecoord/2))
            
            currentPixel = centreOfLogo
            for j in 0 ... 2 {
                currentPixel += (whitecoord*3)
                colorsArray[j] = getColorOfPixel(currentPixel)
            }
            currentPixel = centreOfLogo
            currentPixel = currentPixel + (whitecoord*3*width)
            let groundState = currentPixel
            for k in 1 ... 3 {
                for i in 0 ... 3 {
                    colorsArray[(k*4)-1+i] = getColorOfPixel(currentPixel)
                    print(currentPixel.pointee.red())
                    print(currentPixel.pointee.green())
                    print(currentPixel.pointee.blue())
                    currentPixel += (whitecoord*3)
                }
                currentPixel = groundState
                currentPixel = currentPixel + (whitecoord*3*k*width)
            }
            print(colorsArray)
        }
        
        let outputCGImage = context.makeImage()
        let outputImage = UIImage(cgImage: outputCGImage!, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        
        return outputImage
        
    }
    
    func getColorOfPixel(_ currentPixel:UnsafeMutablePointer<RGBA32>) -> String {
        currentPixel.hashValue
        let red = Float(currentPixel.pointee.red())
        let green = Float(currentPixel.pointee.green())
        let blue = Float(currentPixel.pointee.blue())
        let totalcolor = red+blue+green
        let averagecolor = totalcolor/3
        
        if (abs(red-green)<40) && (abs(red-blue)<40) && (abs(blue-green)<40) {
            if totalcolor > 300 {
                return "white"
            }
            else {
                return "black"
            }
        }
        else if red > (averagecolor*1.2) && green < (averagecolor*0.8) && blue < (averagecolor*0.8) {
            return "red"
        }
        else if green > (averagecolor*1.2) && red < (averagecolor*0.8) {
            return "green"
        }
        else if blue > (averagecolor*1.2) && red < (averagecolor*0.8) {
            return "blue"
        }
        else if red > (averagecolor) && green > (averagecolor) && blue < (averagecolor*0.8) && abs(red-green) < 50 {
            return "yellow"
        }
        else {
            if green > blue {
                return "orange"
            }
            else{
                return "purple"
            }
        }
        
    }
    
    func logoSearch(_ currentPixel:UnsafeMutablePointer<RGBA32>, colorToFind:String, minCurrentPixel:UnsafeMutablePointer<RGBA32>, maxCount:Int) -> Int {
        var colorTotal = 0
        var count = 0
        var edge = 0
        var thePixel = currentPixel
        repeat {
            let pixelColor = getColorOfPixel(thePixel)
            if pixelColor == colorToFind {
                colorTotal += 1
            }
            count += 1
            if colorTotal == 10 {
                edge = count-10
            }
            
            thePixel += 1
        } while ((colorTotal < 100) && (count < maxCount) && thePixel > minCurrentPixel)
        if colorTotal >= 20 {
            return edge
        }
        else {
            return 0
        }
    }
}
