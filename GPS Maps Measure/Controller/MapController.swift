//
//  MapController.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import UIKit
import CoreData
import MapKit
import CocoaLumberjackSwift

class MapController: BaseMeasureMapController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tvMeasureInfo: UILabel!
    @IBOutlet weak var menuEdit: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private var fetchedResultsController: NSFetchedResultsController<Measure>!

    private var selectedMeasure: Measure? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogVerbose("viewDidLoad")
        loadLastPosition()
        setupFetchedResultsController()
        populateMeasures()

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onPointSelected(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)

        if UserPref.createDefaultGroupIsNeeded() {
            let group = Group(context: dataController.viewContext)

            group.name = "Default"
            group.color = Int64(UIColor.blue.rgb()!)
            group.updatedAt = Date()

            try? dataController.viewContext.save()
        }

        hideLoader()
    }

    override func viewWillDisappear(_ animated: Bool) {
        setLastMapLocation()
        super.viewWillDisappear(animated)
    }

    @IBAction func newMeasure(_ sender: Any) {
        setLastMapLocation()
        performMeasureSegue(withIdentifier: MeasureEditorController.FROM_MAP_SEGUE_ID, sender: nil)
    }

    @IBAction func editMeasure(_ sender: Any) {
        performMeasureSegue(withIdentifier: MeasureEditorController.FROM_MAP_SEGUE_ID, sender: selectedMeasure!)
    }

    @objc func onPointSelected(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            mapView.overlays.forEach { overlay in
                if overlay is CMKPolygon {
                    let polygon = overlay as! CMKPolygon
                    let isInside = polygon.isInside(coordinate: coordinate)
                    if isInside {
                        updateDetail(measure: polygon.measure!)
                    }
                } else if overlay is CMKPolyline {
                    let polyline = overlay as! CMKPolyline
                    let isInside = polyline.isInside(coordinate: coordinate)
                    if isInside {
                        updateDetail(measure: polyline.measure!)
                    }
                } else if overlay is CMKCircle {
                    let circle = overlay as! CMKCircle
                    let isInside = circle.isInside(coordinate: coordinate)
                    if isInside {
                        updateDetail(measure: circle.measure!)
                    }
                }
            }
        }
    }

    private func setLastMapLocation() {
        UserPref.setLastLocation(mapView.region.center.latitude, mapView.region.center.longitude)
        UserPref.setLastSpan(mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta)
    }

    private func loadLastPosition() {
        let lastLocation = UserPref.getLastLocation()
        let lastSpanLocation = UserPref.getLastSpanLocation()

        if lastLocation != nil && lastSpanLocation != nil {
            let center = CLLocationCoordinate2D(latitude: lastLocation!.latitude, longitude: lastLocation!.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: lastSpanLocation!.latitude, longitudeDelta: lastSpanLocation!.longitude))

            mapView.setRegion(region, animated: true)
        }
    }

    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Measure> = Measure.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "measures")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    private func populateMeasures() {
        DDLogVerbose("populateMeasures()")
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        tvMeasureInfo.text = ""
        menuEdit.isEnabled = false
        menuEdit.customView?.isHidden = true

        fetchedResultsController.fetchedObjects?.forEach({ measure in
            drawMeasure(measure)
        })
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.isDraggable = false
            pinView!.animatesDrop = false
        } else {
            pinView!.annotation = annotation
        }

        if annotation is CMKPointAnnotation {
            pinView?.pinTintColor = (annotation as! CMKPointAnnotation).measure?.group?.color.uiColor() ?? UIColor.blue
        }
        return pinView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = (overlay as! CMKPolyline).measure?.group?.color.uiColor() ?? UIColor.blue
            renderer.lineWidth = 5
            return renderer
        } else if overlay is CMKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = (overlay as! CMKPolygon).measure?.group?.color.uiColor() ?? UIColor.blue
            renderer.alpha = 0.6
            return renderer
        } else if overlay is CMKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = (overlay as! CMKCircle).measure?.group?.color.uiColor() ?? UIColor.blue
            renderer.alpha = 0.6
            return renderer
        }
        return MKPolylineRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        DDLogVerbose("mapView.didSelect")
        if view.annotation is CMKPointAnnotation {
            let measure = (view.annotation as! CMKPointAnnotation).measure!
            updateDetail(measure: measure)
        }
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        DDLogVerbose("mapViewDidFinishLoadingMap()")
        hideLoader()
    }

    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        DDLogVerbose("mapViewWillStartLoadingMap()")
        showLoader()
    }

    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        DDLogVerbose("mapViewDidFailLoadingMap()")
        showSingleViewAlertAction("Can't load map location")
    }

    private func drawMeasure(_ measure: Measure) {
        let points = measure.getLayLngPoints()

        switch measure.getMeasureType() {
        case .CIRCLE:
            if points.count < 2 {
                return
            }
            let center = CLLocationCoordinate2D(latitude: points[0].latitude, longitude: points[0].longitude)
            let secondPoint = CLLocationCoordinate2D(latitude: points[1].latitude, longitude: points[1].longitude)

            let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let secondPointLocation = CLLocation(latitude: secondPoint.latitude, longitude: secondPoint.longitude)

            let circle = CMKCircle(center: center, radius: centerLocation.distance(from: secondPointLocation))
            circle.measure = measure
            mapView.addOverlay(circle)
            break
        case .AREA:
            if points.isEmpty {
                return
            }
            let coordinates = points.map { point in
                CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            }
            let polygon = CMKPolygon(coordinates: coordinates, count: coordinates.count)
            polygon.measure = measure
            mapView.addOverlay(polygon)
            break
        case .DISTANCE:
            if points.isEmpty {
                return
            }
            let coordinates = points.map { point in
                CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            }
            let polyline = CMKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.measure = measure
            mapView.addOverlay(polyline)
            break
        case .POI:
            let coordinate = CLLocationCoordinate2D(latitude: points[0].latitude, longitude: points[0].longitude)
            let annotation = CMKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.measure = measure
            mapView.addAnnotation(annotation)
            break
        case .none: break

        }
    }

    private func updateDetail(measure: Measure) {
        selectedMeasure = measure
        menuEdit.customView?.isHidden = false
        menuEdit.isEnabled = true
        tvMeasureInfo.text = "\(measure.name ?? "")\n\(measure.getDescription())"
    }

    private func showLoader() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    private func hideLoader() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
}

extension MapController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        populateMeasures()
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
}
