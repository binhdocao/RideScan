//
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
    
    @State private var annotations: [IdentifiablePointAnnotation] = []
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if let url = URL(string: transportViewModel.image_url) {
                        URLImage(url) { image in
                            image
                                .resizable()
                                .frame(width: 25, height: 40)
                        }
                    } else {
                        // Some placeholder content if the URL is not valid
                        Circle()
                            .fill(Color.red)
                            .frame(width: 25, height: 25)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                Spacer()
                if showResults {
                    List(searchCompleter.results, id: \.self) { result in
                        Text(result.title)
                            .onTapGesture {
                                searchCompleter.fetchDetails(for: result)
                                destination = result.title
                                showResults = false
                                dismissKeyboard()
                                
                                let userLocation = CLLocation(latitude: locationManager.region.center.latitude, longitude: locationManager.region.center.longitude)
                                    
                                let geocoder = CLGeocoder()
                                geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
                                    if let error = error {
                                        print("Error reverse geocoding: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    if let placemark = placemarks?.first {
                                        let street = placemark.thoroughfare ?? ""
                                        let city = placemark.locality ?? ""
                                        let country = placemark.country ?? ""
                                        let zipCode = placemark.postalCode ?? ""
                                        
                                        let formattedAddress = "\(street), \(city), \(country), \(zipCode)"

                                        transportViewModel.setAddresses(long_address: formattedAddress, short_address: street, type: "pickup")
                                        
                                        Task {
                                            do {
//                                                _ = try await transportViewModel.findFetii()
                                                let locateFetiiResponse = try await transportViewModel.locateFetii()
                                                transportViewModel.setImage(image_url: locateFetiiResponse.data[0].vehicle_type.top_image)
                                                
                                                print(locateFetiiResponse.data[0].vehicle_type.top_image)
                                                
                                                // Add a new annotation for this location
                                                let newAnnotation = IdentifiablePointAnnotation()
                                                newAnnotation.coordinate = CLLocationCoordinate2D(latitude: locateFetiiResponse.data[0].lat, longitude: locateFetiiResponse.data[0].lng)
                                                annotations.append(newAnnotation)
                                                
                                            } catch {
                                                print("Error submitting user information")
                                            }
                                        }
                                        
                                        
                                    }
                                }
                            }
                    }
                    .frame(height: 200)
                }
                if transportViewModel.driverFound {
                    Text("Found Drivers")
                        .font(.title)
                        .fontWeight(.bold)
                }
				
				HStack {
					TextField("Enter destination...", text: $destination, onEditingChanged: { isEditing in
						self.showResults = isEditing
					})
					.padding(.horizontal)
					
					Button(action: {
						// Implement search action here
						searchCompleter.search(query: destination)
					}) {
						Image(systemName: "magnifyingglass")
							.padding()
							.foregroundColor(maroonColor)
							.background(Circle().fill(Color.white))
					}
				}
				.background(Color.white)
				.cornerRadius(8)
				.padding(.horizontal, 16)
				.onChange(of: destination) { newValue in
					searchCompleter.search(query: newValue)
				}
            }
            
            SideMenu(isSidebarVisible: $isSideMenuOpened)
            
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
