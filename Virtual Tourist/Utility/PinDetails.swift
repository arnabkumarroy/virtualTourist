//
//  PinDetails.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class PinObject: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var pin: Pin
    
    init(pin: Pin, coordinate: CLLocationCoordinate2D){
        self.coordinate = coordinate
        self.pin = pin
    }
}
