//
//  ViewController.swift
//  test
//
//  Created by Gage Broberg on 9/19/23.
//
//

import SwiftUI
import MapKit

class ViewController: UIViewController {
    
    var routeData : Route?
    var routeCoordinates : [CLLocation] = []
    var routeOverlay : MKOverlay?
    
    let mapView : MKMapView = {
        let map = MKMapView()
        map.overrideUserInterfaceStyle = .dark
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        
        setMapConstraints()
        
        if let routeJSON = self.getJSON() {
            parseJSON(jsonData: routeJSON)
        }
        
        addPins()
        
        drawRoute(routeData: routeCoordinates)
    }
    
    func setMapConstraints() {
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
    func getJSON() -> Data? {
        if let path = Bundle.main.path(forResource: "data", ofType: "json") {
            do {
                let data =  try String(contentsOfFile: path).data(using: .utf8)
                print("🟢 SUCCESS: JSON read successfully")
                return data
            } catch {
                print("🛑 ERROR: Unable to read JSON")
            }
        }
        
        return nil
    }
    
    func parseJSON(jsonData: Data) {
        do {
            routeData = try JSONDecoder().decode(Route.self, from: jsonData)
            
            for feature in routeData?.features ?? [] {
                let loc = CLLocation(
                    latitude: feature.geometry.coordinates[1],
                    longitude: feature.geometry.coordinates[0]
                )
                routeCoordinates.append(loc)
            }
        } catch {
            print("🛑 ERROR: Unable to parse JSON")
        }
    }
    
    func addPins() {
        if routeCoordinates.count != 0  {
            let startPin = MKPointAnnotation()
            startPin.title = "start"
            startPin.coordinate = CLLocationCoordinate2D(
                latitude: routeCoordinates[0].coordinate.latitude,
                longitude: routeCoordinates[0].coordinate.longitude
            )
            mapView.addAnnotation(startPin)
            
            let endPin = MKPointAnnotation()
            endPin.title = "end"
            endPin.coordinate = CLLocationCoordinate2D(
                latitude: routeCoordinates.last!.coordinate.latitude,
                longitude: routeCoordinates.last!.coordinate.longitude
            )
            mapView.addAnnotation(endPin)
        }
    }
    
    func drawRoute(routeData: [CLLocation]) {
        if routeData.count == 0 {
            print("🟡 No Coordinates to draw")
            return
        }
        
        let coordinates = routeData.map { location -> CLLocationCoordinate2D in
            return location.coordinate
        }
        
        DispatchQueue.main.async {
            self.routeOverlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
            self.mapView.addOverlay(self.routeOverlay!, level: .aboveRoads)
            let customEdgePadding : UIEdgeInsets = UIEdgeInsets(
                top: 50,
                left: 50,
                bottom: 50,
                right: 50
            )
            self.mapView.setVisibleMapRect(self.routeOverlay!.boundingMapRect, edgePadding: customEdgePadding,animated: true)
        }
    }
}

extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "custom")
        
        if annotationView == nil {
            //CREATE VIEW
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "custom")
        } else {
            //ASSIGN ANNOTATION
            annotationView?.annotation = annotation
        }
        
        //SET CUSTOM ANNOTATION IMAGES
        switch annotation.title {
        case "end":
            annotationView?.image = UIImage(named: "pinEnd")
        case "start":
            annotationView?.image = UIImage(named: "pinStart")
        default:
            break
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKGradientPolylineRenderer(overlay: overlay)
        
        renderer.setColors([
            UIColor(red: 0.02, green: 0.91, blue: 0.05, alpha: 1.0),
            UIColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1.0),
            UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
        ], locations: [])
        renderer.lineCap = .round
        renderer.lineWidth = 3.0
        
        return renderer
    }
    
}
