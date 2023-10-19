//
//  Map.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/19/23.
//

import SwiftUI
import MapKit
import CoreLocation

let maroonColor = Color(red: 0.5, green: 0, blue: 0)

struct MapView: View {
	@ObservedObject var locationManager = LocationManager()
	@State private var destination: String = ""

	var body: some View {
		VStack {
			Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
				.edgesIgnoringSafeArea(.all)

			VStack(alignment: .leading) {
				TextField("Enter destination...", text: $destination)
					.padding()
					.background(Color.white)
					.cornerRadius(8)
					.padding(.horizontal, 16)
			}
			.padding(.top, -40) // Move the text box slightly up to overlay on the map

			Spacer()
		}
	}
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	private var locationManager = CLLocationManager()
	@Published var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
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
		region.center = location.coordinate
	}
}

struct MapView_Previews: PreviewProvider {
	static var previews: some View {
		MapView()
	}
}
