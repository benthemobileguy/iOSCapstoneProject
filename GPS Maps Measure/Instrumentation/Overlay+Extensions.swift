//
//  Overlay+Extensions.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import MapKit

class CMKPolygon: MKPolygon {
    var measure: Measure? = nil
    
    func isInside(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolygonRenderer(polygon: self)
        let mapPoint: MKMapPoint = MKMapPoint(coordinate)
        let viewPoint: CGPoint = renderer.point(for: mapPoint)
        if renderer.path == nil {
            return false
        } else {
            return renderer.path.contains(viewPoint)
        }
    }
}
class CMKPolyline: MKPolyline {
    var measure: Measure? = nil
    
    func isInside(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolylineRenderer(polyline: self)
        let mapPoint: MKMapPoint = MKMapPoint(coordinate)
        let viewPoint: CGPoint = renderer.point(for: mapPoint)
        
        if renderer.path == nil {
            return false
        } else {
            return renderer.path.contains(viewPoint)
        }
    }
}
class CMKCircle: MKCircle {
    var measure: Measure? = nil
    
    func isInside(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKCircleRenderer(circle: self)
        let mapPoint: MKMapPoint = MKMapPoint(coordinate)
        let viewPoint: CGPoint = renderer.point(for: mapPoint)
        if renderer.path == nil {
            return false
        } else {
            return renderer.path.contains(viewPoint)
        }
    }
}


class CMKPointAnnotation: MKPointAnnotation {
    var measure: Measure? = nil
}
