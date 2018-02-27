//
//  MapViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 12/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mapView.delegate = self
        mapView.setRegion(currentRegion, animated: true)
        placePins()
    }
    
    func placePins() {
        let taggiesRef = ref.child("taggies")
        taggiesRef.observe(.childAdded, with: { snapshot in
            if snapshot.childrenCount == 6 {
                let anotation = MKPointAnnotation()
                anotation.coordinate = CLLocationCoordinate2D(latitude: snapshot.value!["latitude"] as! CLLocationDegrees, longitude: snapshot.value!["longitude"] as! CLLocationDegrees)
                anotation.title = snapshot.value!["taggyName"] as? String
                anotation.subtitle = "Lost: " + (snapshot.value!["date"] as? String)!
                self.mapView.addAnnotation(anotation)
            }
        })
    }
}
