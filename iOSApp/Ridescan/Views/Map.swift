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
    @State private var isSideMenuOpened = false

    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Spacer()
                TextField("Enter destination...", text: $destination)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
            }
            
            SideMenu(isSidebarVisible: $isSideMenuOpened)
            
        }
        .navigationBarBackButtonHidden(true) // Hide the back button
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

struct MapView_Previews: PreviewProvider {
	static var previews: some View {
		MapView()
	}
}
