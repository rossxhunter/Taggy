//
//  LostLocationViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 12/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LostLocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var checked = false
    let locationManager = CLLocationManager()
   
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func currentLocationButtonPressed(_ sender: AnyObject) {
        if checked == false {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
            }
            if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                checked = true
                currentLocationButton.setImage(UIImage(named:"boxChecked"), for: UIControlState())
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
        else {
            checked = false
            currentLocationButton.setImage(UIImage(named:"boxUnchecked"), for: UIControlState())
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "clearBlur"), object: self)
    }
    @IBAction func confirmButtonPressed(_ sender: UIBarButtonItem) {
        updateLost = true
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateLost"), object: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checked = false
        mapView.delegate = self
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(LostLocationViewController.addPin))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mapView.isHidden = false
        mapView.frame = CGRect(x: view.frame.width/2, y: view.frame.height/2, width: view.frame.width/1.2, height: view.frame.height/2.2)
        mapView.frame.origin.x -= mapView.frame.width/2
    }
    
    override func viewDidLayoutSubviews() {
        mapView.isHidden = false
        mapView.frame = CGRect(x: view.frame.width/2, y: view.frame.height/2, width: view.frame.width/1.2, height: view.frame.height/2.2)
        mapView.frame.origin.x -= mapView.frame.width/2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addPin(_ gestureRecognizer:UIGestureRecognizer) {
        doneButton.isEnabled = true
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        latitude = newCoordinates.latitude
        longitude = newCoordinates.longitude
        if checked == true {
            currentLocationButtonPressed(self)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        doneButton.isEnabled = true
        checked = true
        currentLocationButton.setImage(UIImage(named:"boxChecked"), for: UIControlState())
        let location = locations.last
        let coords = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegionMakeWithDistance(coords, 1000,1000)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        latitude = coords.latitude
        longitude = coords.longitude
        locationManager.stopUpdatingLocation()
    }
}
