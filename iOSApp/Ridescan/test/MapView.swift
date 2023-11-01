import MapKit
import SwiftUI
import CoreLocation

struct MapView: View {
    
    var latitude: Double?
    var longitude: Double?
    
    let locationManager = CLLocationManager()
    
    @State var pinLocation: Pin?
    @State private var isPinSelected: Bool = false
    @State var region = MKCoordinateRegion(
        center: .init(latitude: 30.6280,longitude: -96.3344),
        span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var body: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.none),
            annotationItems: pinLocation != nil ? [pinLocation!] : [],
            annotationContent: { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack() {
                        if isPinSelected {
                            VStack {
                                Text("Fetii Driver is here")
                                    .fixedSize()
                            }
                            .cornerRadius(8)
                            .shadow(radius: 10)
                        }
                        Image(systemName: "bus")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                isPinSelected.toggle()
                        }
                    }
                }
            }
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            
            // Set the pin location using provided latitude and longitude
            if let lat = latitude, let lon = longitude {
                pinLocation = Pin(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            
            
            
            
        }
    }
}

struct Pin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

