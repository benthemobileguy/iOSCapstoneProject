//
//  PointLocation.swift
//  Created by Ben on July 06, 2023.
//

import Foundation


struct PointLocation {
    //latitude
    var latitude: Double = 0.0
    //latitude
    var longitude: Double = 0.0

    init(_ lat: Double, _ lon: Double) {
        //setters
        latitude = lat
        longitude = lon
    }
}
