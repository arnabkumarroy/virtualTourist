//
//  MapLocation.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import Foundation
import MapKit

// Configure zoom on pinLocation
func centerMapOnLocation(location: CLLocationCoordinate2D, map: MKMapView, size: Double) {
    let regionRadius: CLLocationDistance = size
    let coordinateRegion = MKCoordinateRegion(center: location,
                                              latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
    
    map.setRegion(coordinateRegion, animated: true)
}
