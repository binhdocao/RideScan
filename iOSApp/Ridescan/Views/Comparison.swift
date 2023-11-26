//
//  Comparison.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/31/23.
//

import Foundation
import SwiftUI
import Models
import CoreLocation
enum SortingOption: String, CaseIterable {
	case name = "Name"
	case price = "Price"
	case time = "Time"
}

enum TransportationMode: String, CaseIterable {
	case walking = "Walking"
	case driving = "Driving"
	case uber = "Uber"
	case lyft = "Lyft"
	case bike = "Rideshare Bike"
	case allS = "All"
	// ... Add more modes as needed
}

struct ComparisonView: View {
    @Binding var showBusRoute : Bool // create a function that changes value to true when you press on the bus button. in the do part of the button, add this function
    @Binding var fromTo : FromTo
    @ObservedObject var transportViewModel = TransportViewModel()
    @State var current_fetii_price = 15.0
    @State var current_fetii_min_people = 5
    @State var current_fetii_max_people = 15
    @State var destination : CLLocationCoordinate2D
    @ObservedObject var locationManager = LocationManager()
    
    // BTD Bus
    @State var has_bus_data = "No data"
    
    //dont need anymore
    @State private var buses: [BrazosDriver] //[BrazosDriver(RouteId: 40, lat: 30.00, lng: -97.32,stops: [CLLocationCoordinate2D(latitude: 29.749907, longitude: -95.358421)])]

	struct RideService: Identifiable {
		var id = UUID()
		let name: String
		let price: Double
        var min_people: Int
        var max_people: Int
		let iconName: String
		var timeEstimate: Int
        var distanceEstimate: Double = 0
	}
	
    var rideServices: [RideService]
    @State var BusStop1 : CLLocationCoordinate2D //= CLLocationCoordinate2D(latitude: 29.749907, longitude: -95.358421)
        
    
	
	@State private var refreshView: Bool = false

	
	var sortedRideServices: [RideService] {
		switch selectedSortOption {
		case .time:
			return rideServices.sorted { $0.timeEstimate < $1.timeEstimate }
		case .name:
			return rideServices.sorted { $0.name < $1.name }
		case .price:
			return rideServices.sorted { $0.price < $1.price }
		}
	}
	
	@State private var selectedSortOption: SortingOption = .time
	@State private var selectedTransportation: TransportationMode = .allS
	@State private var showTransportationPicker: Bool = false
	@State private var showSortingPicker: Bool = false
    init(destination: CLLocationCoordinate2D, showBusRoute: Binding<Bool>, fromTo: Binding<FromTo>, distance: Double, bestStop: CLLocationCoordinate2D, buses: [BrazosDriver] ) {
            self.destination = destination
        _showBusRoute = showBusRoute
        _fromTo = fromTo
        self.rideServices = [
            RideService(name: "Uber", price: 10.0, min_people: 1, max_people: 4,iconName: "car",timeEstimate: 6),
            RideService(name: "Lyft", price: 12.0, min_people: 1, max_people: 4,iconName: "car.fill",timeEstimate: 8),
            RideService(name: "Walking", price: 0.0, min_people: 0, max_people: 0, iconName: "figure.walk", timeEstimate: 30),
            RideService(name: "Piggyback", price: Double.random(in: 5...20), min_people: 1, max_people: 1,iconName: "person.fill",timeEstimate: 23),
            /*RideService(name: "Fetii", price: current_fetii_price, min_people: current_fetii_min_people, max_people: current_fetii_max_people, iconName: "bus", timeEstimate: 26),*/

        ]
        //buses = self.fetchBusData()
        //let driver = BrazosDriver(RouteId: 40, lat: 30.00, lng: -97.32, stops: [CLLocationCoordinate2D(latitude: 30.23456565, longitude: -97.4342342)])
        //buses.append(driver)
        //print("buses ---", buses)
        //buses[0].stops = [CLLocationCoordinate2D(latitude: 29.749907, longitude: -95.358421)]
       // print("buses ---", buses)
        //readInputFromFile(filePath: "/data/bus_stops")
        //let distance = distance
        self.buses = buses
        self.BusStop1 = bestStop
        rideServices.append(RideService(name: "Brazos Bus Service", price: 1.0, min_people: 1, max_people: 1, iconName: "bus", timeEstimate: 20, distanceEstimate: distance))
        
        }
    
	var body: some View {
        
		VStack(spacing: 0) {
			Capsule()
				.fill(Color.gray)
				.frame(width: 40, height: 5)
				.padding(.top, 8)
			
			// Transportation Mode Picker
			HStack {
				Text("Mode: \(selectedTransportation.rawValue)")
					.foregroundColor(Color.white)
				Spacer()
				Image(systemName: "car.fill") // Icon for transportation
					.resizable()
					.frame(width: 20, height: 20)
					.onTapGesture {
						showTransportationPicker = true
					}
					.foregroundColor(Color.white)
			}
			.actionSheet(isPresented: $showTransportationPicker) {
				ActionSheet(title: Text("Select Transportation Mode"), buttons: TransportationMode.allCases.map { mode in
					.default(Text(mode.rawValue)) {
						selectedTransportation = mode
					}
				})
			}
			.padding(.horizontal)

			// Sorting Picker
			HStack {
				Text("Sort by: \(selectedSortOption.rawValue)")
					.foregroundColor(Color.white)
				Spacer()
				Image(systemName: "arrow.up.arrow.down.square.fill") // Icon for sorting
					.resizable()
					.frame(width: 20, height: 20)
					.onTapGesture {
						showSortingPicker = true
					}
					.foregroundColor(Color.white)
			}
			.actionSheet(isPresented: $showSortingPicker) {
				ActionSheet(title: Text("Sort by"), buttons: SortingOption.allCases.map { option in
					.default(Text(option.rawValue)) {
						selectedSortOption = option
					}
				})
			}
			.padding(.horizontal)

            // Service List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(sortedRideServices) { service in
                        Button(action: {
                            if service.name == "Brazos Bus Service" {
                                print("houston lat", BusStop1)
                                fromTo.to = BusStop1
                                changeShowBusRoute()
                            }
                            //fetchBusData()
                            //print(findBestRoute())
                        }) {
                            HStack {
                                // Image on the left
                                Image(systemName: service.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50) // Set the image size as needed
                                    .padding(.trailing, 10)
                                
                                // Name in the middle with min and max person counts
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.headline)
                                    Text("Time:\(service.timeEstimate)")
                                        .font(.subheadline)
                                }
                                
                                Spacer() // This will push the following elements to the right
                                
                                // Cost per person and minimum number of passengers on the right
                                VStack(alignment: .trailing) {
                                    Text(String(format: "$%.2f /person", service.price))
                                        .font(.body)
                                    Text("Min Passengers: \(service.min_people)")
                                        .font(.subheadline)
                                    Text("Distance: \(service.distanceEstimate)")
                                        .font(.subheadline)
                                }
                            }
                            
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(20)
                .onChange(of: selectedSortOption) { _ in
                    refreshView.toggle() // Force a view refresh
                }
            }
			Spacer() // Push content to the top
		}
		.background(maroonColor.opacity(0.8))
		.cornerRadius(20, corners: [.topLeft, .topRight])

		.frame(maxWidth: .infinity, maxHeight:(UIScreen.main.bounds.height / 3))
		
		.edgesIgnoringSafeArea(.all)
        .task {
            //print("before")
            //fetchBusData()
            //print(buses)
            //print("after")
            do {
                let result = try await transportViewModel.findFetii()
                current_fetii_price = result.data.first?.min_charge_per_person ?? 15.0
                current_fetii_min_people = result.data.first?.direct_min_passengers ?? 1
                current_fetii_max_people = result.data.first?.direct_max_passengers ?? 4

//                let result = try await transportViewModel.locateFetii()
                // Handle the result here, possibly setting it to another @State or @Published property
            } catch {
                // Handle the error here. Perhaps by showing an alert to the user or logging the error.
                print("Error fetching data: \(error)")
            }
        }
	}
    
    /*func updateBusService(min_people: Int, max_people: Int, timeEstimate: Int,distanceEstimate: Double ) {
        if let index = rideServices.firstIndex(where: { $0.name == "Brazos Bus Service" }) {
            rideServices[index].distanceEstimate = distanceEstimate
                    rideServices[index].min_people = min_people
                    rideServices[index].max_people = max_people
                }
    }*/
    
    func fetchBusData() -> [BrazosDriver]{
        var newBuses : [BrazosDriver] = [BrazosDriver(RouteId: 40, lat: 30.00, lng: -97.32,stops: [CLLocationCoordinate2D(latitude: 29.749907, longitude: -95.358421)])]
        /* idea: have users enter their location. after they hit enter, do algorithm below on background. when options are displayed, only displayed best time. if they press on bus option. show the bus route in red or green and show in blue how to get to the bus stop.
         approach for bus routes:
                var best_route
                var best_route_time
                var pickup_stop
                var dropoff_stp
                for each bus route
                    find stop near your destination and stop near you
                    calculate how much time it would take for you to walk to and from the bus stop
                    if time < best_route_time
                        best_route = current route
                        best_route_time = time
                        ... rest of variables
         This will find the bus route that will take you the less time to walk (from curr location to bus stop and from bus stop to destination)
*/
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
    
     func findBestRoute() -> CLLocationCoordinate2D{
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
            print("My route id", bus.RouteId)
            for stop in bus.stops {
                print(stop)
                if distance(from: coordinates, to: stop) < currToStop {
                    currToStop = distance(from : coordinates, to: stop)
                    coordinatesStop1 = stop
                    
                    print("goes in")
                }
                if distance(from : stop, to : destination) < StopToDest {
                    StopToDest = distance(from: stop, to: destination)
                    coordinatesStop2 = stop
                    
                    print("goes in")
                }
            }
            if totalDistance > currToStop + StopToDest {
                print("goes in")
                totalDistance = currToStop + StopToDest
                routeID = bus.RouteId
                busStop1 = coordinatesStop1
                busStop2 = coordinatesStop2
            }

        }
        //BusStop1 = busStop1
        print("The distance is: ", totalDistance)
        return busStop1
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
    func readInputFromFile( filePath: String) {
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
    }
    
    func distance(from : CLLocationCoordinate2D, to : CLLocationCoordinate2D) -> Double{
        let myLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceMiles = myLocation.distance(from: toLocation) / 1609.34
        return distanceMiles
    }
}


struct ServiceModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.padding(.horizontal) // Add horizontal padding here
			.padding(.vertical)
			.background(Color.white)
			.cornerRadius(8)
			.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
	}
}

/*func findBestRoute(buses: [BrazosDriver], cords: CLLocationCoordinate2D) -> CLLocationCoordinate2D{
   //print("curr location is ",locationManager.region.center)
   
   if buses.count == 0 {
       print( "error - no buses nearby")
   }
   let coordinates = cords
   var totalDistance: Double  = 10000 // miles
   var busStop1 : CLLocationCoordinate2D = CLLocationCoordinate2D()
   var busStop2 : CLLocationCoordinate2D = CLLocationCoordinate2D()
   var routeID = 0
   
   for bus in buses {
       var currToStop : Double = 10000 //miles
       var StopToDest : Double = 10000 //miles
       var coordinatesStop1 : CLLocationCoordinate2D = CLLocationCoordinate2D()
       var coordinatesStop2 : CLLocationCoordinate2D = CLLocationCoordinate2D()
       print("My route id", bus.RouteId)
       for stop in bus.stops {
           print(stop)
           if distance(from: coordinates, to: stop) < currToStop {
               currToStop = distance(from : coordinates, to: stop)
               coordinatesStop1 = stop
               
               print("goes in")
           }
           if distance(from : stop, to : destination) < StopToDest {
               StopToDest = distance(from: stop, to: destination)
               coordinatesStop2 = stop
               
               print("goes in")
           }
       }
       if totalDistance > currToStop + StopToDest {
           print("goes in")
           totalDistance = currToStop + StopToDest
           routeID = bus.RouteId
           busStop1 = coordinatesStop1
           busStop2 = coordinatesStop2
       }

   }
   //BusStop1 = busStop1
   print("The distance is: ", totalDistance)
   return busStop1
   //find route from coordinates to coordinatesStop1 and the rest of the trip
}*/
