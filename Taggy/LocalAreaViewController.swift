//
//  LocalAreaViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

var currentRegion : MKCoordinateRegion!
var center : CLLocationCoordinate2D!

class LocalAreaViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        distanceLabel.text = String(distanceSlider.value) + "km"

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func distanceSliderChanged(_ sender: UISlider) {
        distanceSlider.setValue(round(distanceSlider.value), animated: true)
        distanceLabel.text = String(distanceSlider.value) + "km"
    }
    
    @IBAction func searchButtonPressed(_ sender: UIButton) {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            performSegue(withIdentifier: "localAreaToMap", sender: self)
        }
        else {
            let alert = UIAlertController(title: "Location Services not enabled", message: "Enable location services in Settings to view nearby taggies", preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: UIAlertActionStyle.default) {
                UIAlertAction in
                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                UIAlertAction in
                print("cancel!")
            }
            alert.addAction(settingsAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        currentRegion = MKCoordinateRegionMakeWithDistance(
            center, CLLocationDistance(distanceSlider.value*1000), CLLocationDistance(distanceSlider.value*1000))
        print("center: ",center)
        locationManager.stopUpdatingLocation()
    }
}
