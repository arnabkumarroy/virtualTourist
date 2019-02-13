//
//  MapDashboardController.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import CoreData

class MapDashboardController: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    // MARK: Vars/Lets
    
    var pins: [Pin] = []
    let flickerClient = FlickrClient()
    var dataController: DataController!
    
    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapview.delegate = self
        activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        activityIndicator.startAnimating()
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
        }
        addPinsToMap()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centerMapOnLocation(location: CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "InitialLatitude"), longitude: UserDefaults.standard.double(forKey: "InitialLongitude")), map: mapview, size: 2350000)
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    //------------------------------------------------------------------------------
    // MARK: Actions
    
    @IBAction func longPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.began {
            // Create coordinate from touchpoint
            let touchPoint = gesture.location(in: mapview)
            let newCoordinate = mapview.convert(touchPoint, toCoordinateFrom: mapview)
            
            // Guard from being too high/low on map that when recentering map, it won't crash
            guard (newCoordinate.latitude > StructConstant.Flickr.SearchLatRange.0) && (newCoordinate.latitude < StructConstant.Flickr.SearchLatRange.1) else {
                print("Pin drop out of range")
                return
            }
            
            // Save pin data
            let pinToSave = Pin(context: dataController.viewContext)
            pinToSave.latitude = newCoordinate.latitude
            pinToSave.longitude = newCoordinate.longitude
            try? dataController.viewContext.save()
            
            // Create Annotation
            let pinAnnotation = PinObject(pin: pinToSave, coordinate: newCoordinate)
            self.mapview.addAnnotation(pinAnnotation)
            
            // Save coordinates of pin tapped for UserDefault
            UserDefaults.standard.set(newCoordinate.latitude, forKey: "InitialLatitude")
            UserDefaults.standard.set(newCoordinate.longitude, forKey: "InitialLongitude")
            UserDefaults.standard.synchronize()
        }
    }
    
    //------------------------------------------------------------------------------
    // MARK: Functions
    
    // push PhotoViewController when pin tapped
    func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
        
        // Storing the coordinate in UserDefault for relaunch
        UserDefaults.standard.set(didSelect.annotation!.coordinate.latitude, forKey: "InitialLatitude")
        UserDefaults.standard.set(didSelect.annotation!.coordinate.longitude, forKey: "InitialLongitude")
        UserDefaults.standard.synchronize()
        
        // goto  ImageCollectionViewController
        let goToPhotoViewController = storyboard?.instantiateViewController(withIdentifier: "ImageCollectionViewControllerStoryBoard") as! ImageCollectionViewController
        
        guard let annotation = didSelect.annotation as? PinObject else {
            fatalError("Incorrect Map Object")
        }
        
        // pass vars/lets to destination photoViewController
        let selectedMapPin = annotation.pin
        
        goToPhotoViewController.selectedPhotoPin = selectedMapPin
        goToPhotoViewController.dataController = self.dataController
        
        // Pass the created instance to navigation stack
        navigationController?.pushViewController(goToPhotoViewController, animated: true)
    }
    
    // For every pin in Pinarray, set annotation to map
    func addPinsToMap() {
        for pin in pins {
            let pinAnnotation = PinObject(pin: pin, coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude ))
            self.mapview.addAnnotation(pinAnnotation)
        }
    }
    
    // This changes changes the view of the pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}
