//  Map.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/19/23.
//

import SwiftUI
import MapKit
import CoreLocation
import URLImage

let maroonColor = Color(red: 0.5, green: 0, blue: 0)


struct MapView: View {
	@ObservedObject var transportViewModel = TransportViewModel()
	@ObservedObject var locationManager = LocationManager()
	@State private var destination: String = ""
	@State private var isSideMenuOpened = false
	
	@ObservedObject var searchCompleter = SearchCompleter()
	@State private var showResults: Bool = false
	@State private var shouldAdjustZoom: Bool = false

	@State private var annotations: [IdentifiablePointAnnotation] = []
	
	@State private var route: MKRoute?
	
	@State private var showComparisonSheet: Bool = false

	@State private var isRouteDisplayed: Bool = false
	@State private var isRouteConfirmed: Bool = false
	
	func confirmRoute() {
		isRouteConfirmed = true
		showComparisonSheet = true
	}

	func denyRoute() {
		isRouteConfirmed = false
		showComparisonSheet = false
	}
	

	func calculateRoute(to destination: CLLocationCoordinate2D) {
		let request = MKDirections.Request()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.region.center))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
		request.transportType = .automobile
		
		let directions = MKDirections(request: request)
		directions.calculate { response, error in
			guard let newRoute = response?.routes.first else {
				print("Failed to get route: \(error?.localizedDescription ?? "Unknown error")")
				return
			}
			
			self.route = newRoute
			
			let startAnnotation = IdentifiablePointAnnotation()
			startAnnotation.coordinate = locationManager.region.center
			startAnnotation.title = "Start"

			let destinationAnnotation = IdentifiablePointAnnotation()
			destinationAnnotation.coordinate = destination
			destinationAnnotation.title = "Destination"

			self.annotations = [startAnnotation, destinationAnnotation]
			
			self.shouldAdjustZoom = true
		}
		
		isRouteDisplayed = true
	}


	
	var body: some View {
		ZStack {
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
				if showComparisonSheet {
					ComparisonView(transportViewModel: transportViewModel)
				} else {
					if isRouteDisplayed {
						HStack(spacing: 50) {
							VStack {
								Button(action: {
									confirmRoute()
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
											calculateRoute(to: destinationCoordinate)
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

