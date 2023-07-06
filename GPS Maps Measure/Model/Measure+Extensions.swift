//
//  Measure+Extensions.swift
//  Created by Ben on July 06, 2023.
//

import MapKit
import CocoaLumberjackSwift
import Turf
import Foundation
import CoreData

extension Measure {

    static func newInstance(context: NSManagedObjectContext,
                            name: String,
                            group: Group,
                            type: MeasureType,
                            points: [PointLocation]) -> Measure {
        let measure = Measure(context: context)

        measure.name = name
        measure.group = group
        measure.type = type.rawValue

        measure.area = 0.0
        measure.perimeter = 0.0
        measure.distance = 0.0
        measure.radio = 0.0

        measure.setPointsList(points: points)

        measure.photo = nil
        measure.updatedAt = Date()

        measure.regenerateCalculations()

        return measure
    }

    func getLayLngPoints() -> [PointLocation] {
        var list: [PointLocation] = []

        guard let simplePoints = simplePoints else {
            return list
        }

        let pairPoints = simplePoints.split(separator: "|")

        pairPoints.forEach { pairPoint in
            let latLng = pairPoint.split(separator: ",")
            let lat = Double(latLng[0]) ?? 0
            let lon = Double(latLng[1]) ?? 0

            list.append(PointLocation(lat, lon))
        }

        return list
    }

    func setPointsList(points: [PointLocation]) {
        simplePoints = points.map { point in
                    "\(point.latitude),\(point.longitude)"
                }
                .joined(separator: "|")
    }

    func getMeasureType() -> MeasureType? {
        var measureType: MeasureType? = nil
        switch type {
        case MeasureType.AREA.rawValue:
            measureType = MeasureType.AREA
            break
        case MeasureType.DISTANCE.rawValue:
            measureType = MeasureType.DISTANCE
            break
        case MeasureType.CIRCLE.rawValue:
            measureType = MeasureType.CIRCLE
            break
        case MeasureType.POI.rawValue:
            measureType = MeasureType.POI
            break
        case .none:
            measureType = nil
        case .some(_):
            measureType = nil
        }
        return measureType
    }

    func regenerateCalculations() {
        area = 0.0
        perimeter = 0.0
        distance = 0.0
        radio = 0.0

        switch getMeasureType() {
        case .AREA:
            regenerateForArea()
            break
        case .DISTANCE:
            regenerateForDistance()
            break
        case .CIRCLE:
            regenerateForCircle()
            break
        case .POI:
            break
        case .none:
            break
        }
    }

    private func regenerateForCircle() {
        let points = getLayLngPoints()
        if points.count >= 2 {
            // Radio
            let centerLocation = CLLocation(latitude: points[0].latitude, longitude: points[0].longitude)
            let secondPointLocation = CLLocation(latitude: points[1].latitude, longitude: points[1].longitude)
            let locationDistance = centerLocation.distance(from: secondPointLocation)
            radio = locationDistance

            // Area
            // Disabled temporally
            let ring = Turf.Ring(coordinates: points.map({ point in
                LocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            }))
            // Using basic algorithm, needs to use earth circunference for big circles
            area = Double.pi * radio * radio

            perimeter = 2 * Double.pi * radio
        } else {
            area = 0.0
            perimeter = 0.0
            radio = 0.0
        }
    }

    private func regenerateForDistance() {
        let points = getLayLngPoints()
        if points.count >= 2 {
            var _distance = 0.0

            var oldLocation = CLLocation(latitude: points[0].latitude, longitude: points[0].longitude)

            for i in points.indices {
                let nextLocation = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
                _distance += oldLocation.distance(from: nextLocation)
                oldLocation = nextLocation
            }
            distance = _distance
        } else {
            distance = 0.0
        }
    }

    private func regenerateForArea() {
        let points = getLayLngPoints()
        if points.count >= 3 {
            var _perimeter = 0.0

            // Perimeter
            var newPoints = points
            newPoints.append(points.first!)

            var oldLocation = CLLocation(latitude: points[0].latitude, longitude: points[0].longitude)

            for i in newPoints.indices {
                let nextLocation = CLLocation(latitude: newPoints[i].latitude, longitude: newPoints[i].longitude)
                _perimeter += oldLocation.distance(from: nextLocation)
                oldLocation = nextLocation
            }

            //area
            let pol = Turf.Polygon([points.map({ point in
                LocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            })])
            area = pol.area
            perimeter = _perimeter

        } else {
            area = 0.0
            perimeter = 0.0
        }
    }

//    func area(){
//        let points = getLayLngPoints()
//        let pol = Turf.Polygon([points.map({ point in
//            LocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
//        })])
//
//        pol.area
//    }


    func getDescription() -> String {
        var mDescription = ""
        switch getMeasureType() {
        case .AREA:
            mDescription = "Area: \(roundValue(area)) [m²]\nPerimeter: \(roundValue(perimeter)) [m]"
            break
        case .DISTANCE:
            mDescription = "Distance: \(roundValue(distance)) [m]"
            break
        case .CIRCLE:
            mDescription = "Area: \(roundValue(area)) [m²]\nRadio: \(roundValue(radio)) [m]\nCircumference: \(roundValue(perimeter)) [m]"
            break
        case .POI:
            let points = getLayLngPoints()
            mDescription = "Latitude: \(points.first?.latitude ?? 0.0)\nLongitude: \(points.first?.longitude ?? 0.0)"
            break
        case .none:
            break
        }
        return mDescription
    }

    private func roundValue(_ value: Double) -> String {
        String(format: "%.03f", value)
    }

    func needsFill() -> Bool {
        getMeasureType() == .AREA || getMeasureType() == .CIRCLE
    }
}
