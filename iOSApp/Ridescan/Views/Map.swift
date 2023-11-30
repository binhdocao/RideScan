//  Map.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/19/23.
//

import SwiftUI
import MapKit
import CoreLocation
import URLImage
import Models

let maroonColor = Color(red: 0.5, green: 0, blue: 0)


struct MapView: View {
	@ObservedObject var transportViewModel = TransportViewModel()
	@ObservedObject var locationManager = LocationManager()
	@State private var destination: String = ""
    @State private var destinationCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
	@State private var isSideMenuOpened = false
    @State var has_bus_data = "No data"
    @State var timeAll : Double = 0
    @State var distanceAll : Double = 0
	@ObservedObject var searchCompleter = SearchCompleter()
	@State private var showResults: Bool = false
	@State private var shouldAdjustZoom: Bool = false

	@State private var annotations: [IdentifiablePointAnnotation] = []
    @State private var annotations1: [IdentifiablePointAnnotation] = []
    
	
	@State private var route: MKRoute?
	
	@State private var showComparisonSheet: Bool = false

	@State private var isRouteDisplayed: Bool = false
	@State private var isRouteConfirmed: Bool = false
	
	@State private var isRouteCalculationComplete = false
    @State private var showBusRoute : Bool = false //if true, which comparison should change, then add another if in body where it will call
    @State private var fromTo = FromTo()
    

	
	func confirmRoute() {
		isRouteConfirmed = true
		showComparisonSheet = true
	}

	func denyRoute() {
		isRouteConfirmed = false
		showComparisonSheet = false
	}
	
    func calculateDistanceAndTimeBetweenPoints(coordinates: [CLLocationCoordinate2D], currentIndex: Int = 0, totalDistance: CLLocationDistance = 0.0, totalTime: TimeInterval = 0.0, completion: @escaping ((distance: CLLocationDistance, time: TimeInterval)?) -> Void) {
        guard currentIndex < coordinates.count - 1 else {
            // When all segments have been processed
            let result = (distance: totalDistance / 1609.344, time: totalTime / 60.0) // Convert meters to miles, seconds to minutes
            completion(result)
            return
        }

        let sourceCoordinate = coordinates[currentIndex]
        let destinationCoordinate = coordinates[currentIndex + 1]

        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem

        if currentIndex == 0 || currentIndex == 2 {
            directionRequest.transportType = .walking
        } else if currentIndex == 1 {
            directionRequest.transportType = .automobile
        }

        let directions = MKDirections(request: directionRequest)

        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }

            let updatedTotalDistance = totalDistance + route.distance
            let updatedTotalTime = totalTime + route.expectedTravelTime

            // Calculate next segment recursively
            calculateDistanceAndTimeBetweenPoints(
                coordinates: coordinates,
                currentIndex: currentIndex + 1,
                totalDistance: updatedTotalDistance,
                totalTime: updatedTotalTime,
                completion: completion
            )
        }
    }
    func calculateRoute(from: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, forBus: Bool = false) -> Int{
        
		let request = MKDirections.Request()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
		request.transportType = .automobile
		
		let directions = MKDirections(request: request)
        directions.calculate { response, error in
            
            
            guard let newRoute = response?.routes.first else {
                print("Failed to get route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async { // M
                self.route = newRoute
                self.updateRouteDistance(with: newRoute)
                
                let startAnnotation = IdentifiablePointAnnotation()
                startAnnotation.coordinate = from
                startAnnotation.title = "Start"
                
                let destinationAnnotation = IdentifiablePointAnnotation()
                destinationAnnotation.coordinate = destination
                destinationAnnotation.title = "Destination"
                
                
                self.annotations = [startAnnotation, destinationAnnotation]
                if forBus {
                    self.annotations.append(contentsOf: annotations1)
                    self.annotations[1].title = "Your Stop"
                }
                
                
                
                self.shouldAdjustZoom = true
                
                
                
                self.isRouteCalculationComplete = true
                
                isRouteDisplayed = true
                //showBusRoute = false
            }
        }
		return 1
	}

	@State private var routeDistance: String = ""

	func updateRouteDistance(with route: MKRoute) {
		let distanceInMiles = route.distance / 1609.344 // Convert meters to miles
		routeDistance = String(format: "%.2f miles", distanceInMiles)
	}

    func addpins(pin1: CLLocationCoordinate2D, pin2: CLLocationCoordinate2D) -> Int{
        DispatchQueue.main.async {
            let startAnnotation = IdentifiablePointAnnotation()
            startAnnotation.coordinate = pin1
            startAnnotation.title = "get off here"
            
            let destinationAnnotation = IdentifiablePointAnnotation()
            destinationAnnotation.coordinate = pin2
            destinationAnnotation.title = "Destination"
            
            
            self.annotations1 = []
            annotations1.append(startAnnotation)
            annotations1.append(destinationAnnotation)
        }
        return 1
    }
	var body: some View {
        //var extrapins : [IdentifiablePointAnnotation] = []
		ZStack {
            //calculateRoute(from: fromTo.from ,to: fromTo.to)
            /*if showBusRoute {
                var status = calculateRoute(from: fromTo.from ,to: fromTo.to)
                
            }*/
			WrappedMapView(region: $locationManager.region,shouldAdjustZoom: $shouldAdjustZoom, annotations: annotations, route: route)
				.edgesIgnoringSafeArea(.all)
			SideMenu(isSidebarVisible: $isSideMenuOpened)
            
			VStack(alignment: .leading) {
				Spacer()
				if transportViewModel.driverFound {
					Text("Found Drivers")
						.font(.title)
						.fontWeight(.bold)
				}
                if showBusRoute && !isRouteDisplayed && !isRouteCalculationComplete {
                    //fromTo.from = self.annotations[0].coordinate
                    

                    var status = calculateRoute(from: fromTo.from ,to: fromTo.to, forBus: true)
                    //var idk = addpins(pin1: annotations1[0], pin2: annotations1[1])
                    //var i = IdentifiablePointAnnotation()
                    //var a = IdentifiablePointAnnotation()
                    
                    
                    
                  /* var buses = fetchBusData()
                    var newbuses = readInputFromFile(filePath: "/data/bus_stops", buses: &buses)

                    var bestroute = findBestRoute(buses: newbuses, destination: self.annotations[1].coordinate)
                    
                    ComparisonView(destination: self.annotations[1].coordinate,showBusRoute: $showBusRoute, fromTo: $fromTo, distance: bestroute.totalDistance,bestStop: bestroute.busStop1, buses: newbuses)
                    */
                    /*HStack {
                                            
                                            Button(action: {
                                                fromTo.from = locationManager.region.center
                                                calculateRoute(from: fromTo.from ,to: fromTo.to)
                                                /*WrappedMapView(region: $locationManager.region,shouldAdjustZoom: $shouldAdjustZoom, annotations: annotations, route: route)
                                                    .edgesIgnoringSafeArea(.all)
                                                SideMenu(isSidebarVisible: $isSideMenuOpened)*/
                                            }) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .padding()
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(maroonColor)
                                                    .background(Circle().fill(Color.white))
                                            }
                                        }*/
                    
                    
                   
                   
                }
				 if showComparisonSheet {
                    //fromTo.from = locationManager.region.center
                    //var status = calculateRoute(from: locationManager.region.center, to: self.annotations[1].coordinate)
                     HStack {
                         Button(action: {
                             showComparisonSheet = false
                             showBusRoute = false
                             
                             
                             
                         }) {
                             Image(systemName: "chevron.left")
                                 .font(.largeTitle)
                                 .foregroundColor(.green)
                         }
                         .padding()
                         .background(Color.white)
                         .cornerRadius(15)
                         .shadow(radius: 5)
                         //Text("Confirm")
                         .font(.headline)
                         
                     }
                    var buses = fetchBusData()
                    var newbuses = readInputFromFile(filePath: "/data/bus_stops", buses: &buses)
                    
                    var bestroute = findBestRoute(buses: newbuses, destination: destinationCoordinates)
                     
                     //var o = DispatchQueue.main.async {
                         var status = addpins(pin1: bestroute.busStop2, pin2: destinationCoordinates)
                     var t : Double = 1
                     var d : Double = 2
                     var finalResult: (distance: CLLocationDistance, time: TimeInterval)? = (99,98)
                     //var epp = calculateDistanceAndTimeBetweenPoints(coordinates : [CLLocationCoordinate2D(latitude: 30.601389, longitude: -96.314445), bestroute.busStop1, bestroute.busStop2, destinationCoordinates]) { result in
                     var epp = calculateDistanceAndTimeBetweenPoints(coordinates : [locationManager.region.center, bestroute.busStop1, bestroute.busStop2, destinationCoordinates]) { result in
                         if let result = result {
                             DispatchQueue.main.async {
                                 timeAll = result.time
                                 distanceAll = result.distance
                             }
                         }
                         
                     }
                          //ComparisonView(destination: destinationCoordinates,showBusRoute: $showBusRoute, fromTo: $fromTo, distance: result?.distance ?? 0,bestStop: bestroute.busStop1, buses: newbuses, time: result?.time ?? 0)
                     
                     //var tt = print("beforeee")
                     
                     ComparisonView(destination: destinationCoordinates,showBusRoute: $showBusRoute, fromTo: $fromTo, distance: distanceAll ?? 0,bestStop: bestroute.busStop1, buses: newbuses, time: timeAll ?? 0)
				}
                
                else {
					if isRouteDisplayed && isRouteCalculationComplete {
                        
						HStack(spacing: 50) {
							Text("Distance: \(routeDistance)")
								.padding(25)
								.background(Color.white)
								.cornerRadius(15)
								.shadow(radius: 5)
							VStack {
								Button(action: {
									confirmRoute()
                                    fromTo.from = self.annotations[0].coordinate
                                    destinationCoordinates = self.annotations[1].coordinate
                                    isRouteDisplayed = false
                                    isRouteCalculationComplete = false
                                    
                                    
								}) {
									Image(systemName: "checkmark.circle.fill")
										.font(.largeTitle)
										.foregroundColor(.green)
								}
								.padding()
								.background(Color.white)
								.cornerRadius(15)
								.shadow(radius: 5)
								Text("Confirm")
									.font(.headline)
							}
							
							VStack {
								Button(action: {
									denyRoute()
                                    isRouteDisplayed = false
                                    isRouteCalculationComplete = false
								}) {
									Image(systemName: "xmark.circle.fill")
										.font(.largeTitle)
										.foregroundColor(.red)
								}
								.padding()
								.background(Color.white)
								.cornerRadius(15)
								.shadow(radius: 5)
								Text("Deny")
									.font(.headline)
							}
						}
						.padding()
					}
                    
                    
 else {
						HStack {
							TextField("Enter destination...", text: $destination)
							.padding(.horizontal)
							
							Button(action: {
								// Implement search action here
								
								showResults = false
								searchCompleter.search(query: destination)
								DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
									if let firstResult = searchCompleter.results.first {
										searchCompleter.fetchDetails(for: firstResult)
										
										// Calculate the route to the selected location
										if let destinationCoordinate = searchCompleter.transportViewModel?.dropoffLocation {
                                            calculateRoute(from: locationManager.region.center, to: destinationCoordinate)
										}
										
										// Update the search bar with the selected address
										destination = "\(firstResult.title)"
									}
								}
							}) {
								Image(systemName: "magnifyingglass")
									.padding()
									.font(.system(size: 20, weight: .bold))
									.foregroundColor(maroonColor)
									.background(Circle().fill(Color.white))
							}
						}
						.background(Color.white)
						.cornerRadius(8)
						.padding(.horizontal, 16)
						.onChange(of: destination) { newValue in
							searchCompleter.search(query: newValue)
							showResults = !newValue.isEmpty
						}
					}
					if destination.count > 0 && showResults {
						SearchSheetView(destination: $destination, searchCompleter: searchCompleter)
							.transition(.move(edge: .bottom))
							.animation(.spring())
							.edgesIgnoringSafeArea(.all)
					}
                }
            }
		}
	
		.gesture(
			TapGesture()
				.onEnded { _ in
					dismissKeyboard()
				}
		)
		.task {
			// set users current location
			transportViewModel.setLocation(locationManager.region.center, type: "pickup")
		}
		.navigationBarBackButtonHidden(true) // Hide the back button
	}
	
	init() {
		searchCompleter.transportViewModel = transportViewModel
	}

	// Helper function to dismiss the keyboard
	func dismissKeyboard() {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
	
    func fetchBusData() -> [BrazosDriver] {
        var newBuses : [BrazosDriver] = []
        //var newBuses : [BrazosDriver] = [BrazosDriver(RouteId: 48, lat: 30.00, lng: -97.32)]

        let baseURL = "https://www.ridebtd.org/Services/JSONPRelay.svc/GetMapVehiclePoints?apiKey=8882812681"
        guard let url = URL(string: baseURL) else {
            has_bus_data = "Invalid URL"
            return newBuses
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Add your authorization header if needed
        // request.addValue("Bearer YOUR_BEARER_TOKEN", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    has_bus_data = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    has_bus_data = "No data received from the server"
                }
                return
            }
            
            do {
                // Parse the JSON response as an array of dictionaries
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    
                    for dict in jsonArray {
                        if let lat = dict["Latitude"] as? Double,
                           let lon = dict["Longitude"] as? Double,
                           let id = dict["RouteID"] as? Int {
                            //let driver = BrazosDriver(RouteId: id, lat: lat, lng: lon, stops: [])
                            let driver = BrazosDriver(RouteId: id, lat: lat, lng: lon)
                            newBuses.append(driver)
                        }
                    }
                    //let driver = BrazosDriver(RouteId: 40, lat: 30.00, lng: -97.32)
                    
                    
                    DispatchQueue.main.async {
                        
                        has_bus_data = "Data fetched successfully"
                    }
                } else {
                    DispatchQueue.main.async {
                        has_bus_data = "Failed to decode the response data"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    has_bus_data = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
        return newBuses
    }
    
    
    func findBestRoute(buses: [BrazosDriver], destination: CLLocationCoordinate2D) -> (totalDistance: Double, busStop1:CLLocationCoordinate2D, busStop2: CLLocationCoordinate2D) {
        //print("curr location is ",locationManager.region.center)
        
        if buses.count == 0 {
            print( "error - no buses nearby")
        }
        
        let coordinates = locationManager.region.center
        var totalDistance: Double  = 10000 // miles
        var busStop1 : CLLocationCoordinate2D = CLLocationCoordinate2D()
        var busStop2 : CLLocationCoordinate2D = CLLocationCoordinate2D()
        var routeID = 0
        
        for bus in buses {
            var currToStop : Double = 10000 //miles
            var StopToDest : Double = 10000 //miles
            var coordinatesStop1 : CLLocationCoordinate2D = CLLocationCoordinate2D()
            var coordinatesStop2 : CLLocationCoordinate2D = CLLocationCoordinate2D()
            //print("My route id", bus.RouteId)
            for stop in bus.stops {
                //print(stop)
                if distance(from: coordinates, to: stop) < currToStop {
                    currToStop = distance(from : coordinates, to: stop)
                    coordinatesStop1 = stop
                    
                }
                if distance(from : stop, to : destination) < StopToDest {
                    StopToDest = distance(from: stop, to: destination)
                    coordinatesStop2 = stop
                    
                }
            }
            if totalDistance > currToStop + StopToDest {
                totalDistance = currToStop + StopToDest
                routeID = bus.RouteId
                busStop1 = coordinatesStop1
                busStop2 = coordinatesStop2
            }

        }
        //BusStop1 = busStop1
        return (totalDistance,busStop1, busStop2)
        //find route from coordinates to coordinatesStop1 and the rest of the trip
    }
    func changeShowBusRoute() {
        if showBusRoute {
            showBusRoute = false
        }
        else {
            showBusRoute = true
        }
    }
    func readInputFromFile( filePath: String, buses: inout [BrazosDriver])  -> [BrazosDriver]{
        //let fileManager = FileManager.default
        
        // Check if the file exists at the given path
        if let file = Bundle.main.path(forResource: filePath, ofType: "txt") {
            let fileURL = URL(fileURLWithPath: file)
            do {
                // Read the contents of the file
                let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = fileContents.components(separatedBy: .newlines)
                for line in lines {
                    if line == "" {
                        continue
                    }
                    let components = line.components(separatedBy: " ")
                    let id = Int(components[0])
                    let lat : Double = Double(components[1])!
                    let lon : Double = Double(components[2])!
                    for i in 0..<buses.count {
                        
                        if buses[i].RouteId == id {
                            buses[i].stops.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        }
                    }
                }
                
            } catch {
                print("Error reading file: \(error)")
            }
        } else {
            print("File not found at path: \(filePath)")
        }
        return buses
    }
    
    func distance(from : CLLocationCoordinate2D, to : CLLocationCoordinate2D) -> Double{
        let myLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceMiles = myLocation.distance(from: toLocation) / 1609.34
        return distanceMiles
    }
	
}

struct SidebarView: View {
	@Binding var showSidebar: Bool
	
	var body: some View {
		VStack {
			Spacer()
			// Your sidebar content goes here
			Text("Sidebar Content")
				.foregroundColor(.black)
				.padding()
			Spacer()
		}
		.frame(width: 200)
		.background(Color.white)
		.offset(x: showSidebar ? 0 : -200) // Slide in from the left when open
	}
}

struct FromTo {
    var from : CLLocationCoordinate2D = CLLocationCoordinate2D()
    var to : CLLocationCoordinate2D = CLLocationCoordinate2D()
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	private var locationManager = CLLocationManager()

	@Published var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
		span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
	)

	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		// Update the @Published property within the ObservableObject
		DispatchQueue.main.async {
			self.region.center = location.coordinate
		}
	}
}

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
	var completer: MKLocalSearchCompleter
	@Published var results: [MKLocalSearchCompletion] = []
	weak var transportViewModel: TransportViewModel?
	
	override init() {
		completer = MKLocalSearchCompleter()
		super.init()  // Call super.init() after initializing properties
		completer.delegate = self
	}
	
	func search(query: String) {
		completer.queryFragment = query
	}
	
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.results = completer.results
	}
	
	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		// Handle error
	}
	
	func fetchDetails(for completion: MKLocalSearchCompletion) {
		let request = MKLocalSearch.Request(completion: completion)
		let search = MKLocalSearch(request: request)
		search.start { (response, error) in
			guard let response = response else {
				print("Error fetching details: \(error?.localizedDescription ?? "Unknown error")")
				return
			}
			
			if let item = response.mapItems.first {
				// Here you have detailed information about the selected place
				print(item.name ?? "No Name")
				print(item.placemark.coordinate)
				print(item.phoneNumber ?? "No Phone Number")
				// Accessing the complete address using properties
				let placemark = item.placemark
				var addressComponents: [String] = []
				
				if let thoroughfare = placemark.thoroughfare {
					addressComponents.append(thoroughfare)
				}
				if let locality = placemark.locality {
					addressComponents.append(locality)
				}
				if let country = placemark.country {
					addressComponents.append(country)
				}
				if let postalCode = placemark.postalCode {
					addressComponents.append(postalCode)
				}
				
				let completeAddress = addressComponents.joined(separator: ", ")
				let shortAddress = placemark.thoroughfare ?? ""
				print("Complete Address: \(completeAddress)")
				
				self.transportViewModel?.setLocation(item.placemark.coordinate, type: "dropoff")
				
				self.transportViewModel?.setAddresses(long_address: completeAddress, short_address: shortAddress, type: "dropoff")

			}
		}
	}
}




struct CustomAnnotationView: View {
	let image: Image
	
	var body: some View {
		image
			.resizable()
			.frame(width: 50, height: 50) // Or any other size
			.clipShape(Circle())
	}
}

class IdentifiablePointAnnotation: MKPointAnnotation, Identifiable {
	let id = UUID()
}

struct MapView_Previews: PreviewProvider {
	static var previews: some View {
		MapView()
	}
}

struct WrappedMapView: UIViewRepresentable {
	@Binding var region: MKCoordinateRegion
	@Binding var shouldAdjustZoom: Bool

	
	var annotations: [IdentifiablePointAnnotation]
	var route: MKRoute?
	
	func makeUIView(context: Context) -> MKMapView {
		let mapView = MKMapView()
		mapView.delegate = context.coordinator
		return mapView
	}
	
	func updateUIView(_ uiView: MKMapView, context: Context) {
		uiView.setRegion(region, animated: true)
		uiView.removeAnnotations(uiView.annotations)
		uiView.addAnnotations(annotations)
		
		if let routePolyline = route?.polyline {
			uiView.removeOverlays(uiView.overlays)
			uiView.addOverlay(routePolyline)
		}
		
		if shouldAdjustZoom, let routePolyline = route?.polyline {
			uiView.setVisibleMapRect(routePolyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
			shouldAdjustZoom = false
		}
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, MKMapViewDelegate {
		var parent: WrappedMapView
		
		init(_ parent: WrappedMapView) {
			self.parent = parent
		}
		
		func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
			if overlay is MKPolyline {
				let renderer = MKPolylineRenderer(overlay: overlay)
				renderer.strokeColor = .blue
				renderer.lineWidth = 3
				return renderer
			}
			return MKOverlayRenderer()
		}
	}
}


