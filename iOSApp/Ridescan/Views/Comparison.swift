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
    case name = "name (A-Z)"
    case price = "price"
    case time = "time"
    case experience = "experience"
    case `public` = "public"
    case small_business = "small business"
    case safety = "safety rating"
    case carbon_emissions = "carbon emissions"
    case calories_burned = "calories burned"
    case score = "score"
}

enum TransportationMode: String, CaseIterable {
	  case walking = "walking"
    case biking = "biking"
	  case driving = "driving"
    case transit = "transit"
    case other = "other"
}

enum SortingFilters: String, CaseIterable {
    case experience = "experience"
    case `public` = "public"
    case small_business = "small business"
}

struct ComparisonView: View {
    @Binding var showBusRoute : Bool // create a function that changes value to true when you press on the bus button. in the do part of the button, add this function
    @Binding var fromTo : FromTo
    @ObservedObject var transportViewModel = TransportViewModel()
    
    // user criteria preferences
    @State private var criteriaPrefs: [Criteria] = []
    
    // Fetii info
    @State var current_fetii_price = 15.0
    @State var current_fetii_min_people = 5
    @State var current_fetii_max_people = 15
    @State var destination : CLLocationCoordinate2D
    @ObservedObject var locationManager = LocationManager()
    @State private var showAlert = false
    @State var current_veo_price = 0.5
    
    // BTD Bus info
    @State var has_bus_data = "No data"
	    
    @State private var filteredServices: [(Service, Double)] = []
    
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
	
    @State var rideServices: [RideService] = []
    @State var BusStop1 : CLLocationCoordinate2D //= CLLocationCoordinate2D(latitude: 29.749907, longitude: -95.358421)
        
	
    @State private var refreshView: Bool = false
	
    @State private var selectedSortOption: SortingOption = .score
    @State private var selectedTransportationModes: Set<TransportationMode> = Set(TransportationMode.allCases)
    @State private var selectedSortingOptions: Set<SortingFilters> = []

    @State private var isAllSelected: Bool = false

    @State private var showTransportationPicker: Bool = false
    @State private var showSortingPicker: Bool = false
    @State private var isAscendingOrder = true
  
    init(viewModel: TransportViewModel, destination: CLLocationCoordinate2D, showBusRoute: Binding<Bool>, fromTo: Binding<FromTo>, distance: Double, bestStop: CLLocationCoordinate2D, buses: [BrazosDriver]) {
        self.transportViewModel = viewModel
        self.destination = destination
        _showBusRoute = showBusRoute
        _fromTo = fromTo
        self.buses = buses
        self.BusStop1 = bestStop

        // Initialize rideServices after all properties are initialized
        var rideServices: [RideService] = [
            RideService(name: "Uber", price: 10.0, min_people: 1, max_people: 4,iconName: "car",timeEstimate: 6),
            RideService(name: "Lyft", price: 12.0, min_people: 1, max_people: 4,iconName: "car.fill",timeEstimate: 8),
            RideService(name: "Walking", price: 0.0, min_people: 0, max_people: 0, iconName: "figure.walk", timeEstimate: 30),
            RideService(name: "Piggyback", price: Double.random(in: 5...20), min_people: 1, max_people: 1,iconName: "person.fill",timeEstimate: 23)
        ]

        var myDistance: Double = 0
        if !buses.isEmpty {
            myDistance = distance
        }

        rideServices.append(RideService(name: "Brazos Bus Service", price: 1.0, min_people: 1, max_people: 1, iconName: "bus", timeEstimate: 20, distanceEstimate: myDistance))

        self.rideServices = rideServices
    }
    
	var body: some View {
        
		VStack(spacing: 0) {
            HStack {
                Menu {
                    // Submenu for Transport Types
                    Menu("Transport Types") {
                        ForEach(TransportationMode.allCases, id: \.self) { mode in
                            Toggle(isOn: Binding(
                                get: { self.selectedTransportationModes.contains(mode) },
                                set: { isSelected in
                                    if isSelected {
                                        self.selectedTransportationModes.insert(mode)
                                    } else {
                                        self.selectedTransportationModes.remove(mode)
                                    }
                                }
                            )) {
                                Text(mode.rawValue)
                            }
                        }
                    }

                    // Submenu for Criteria
                    Menu("Criteria") {
                        ForEach(SortingFilters.allCases, id: \.self) { option in
                            Toggle(isOn: Binding(
                                get: { self.selectedSortingOptions.contains(option) },
                                set: { isSelected in
                                    if isSelected {
                                        self.selectedSortingOptions.insert(option)
                                    } else {
                                        self.selectedSortingOptions.remove(option)
                                    }
                                }
                            )) {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Filters")
                            .foregroundColor(Color.white)
                        Image(systemName: "line.horizontal.3.decrease.circle") // This is a commonly used filter icon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color.white)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .padding(.top, 10)


            // Sorting Picker
            HStack {
                Menu {
                    ForEach(SortingOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedSortOption = option
                        }) {
                            Label(
                                title: { Text(option.rawValue) },
                                icon: {
                                    if option == selectedSortOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            )
                        }
                    }
                } label: {
                    HStack {
                        Text("Sort by: \(selectedSortOption.rawValue)")
                            .foregroundColor(Color.white)
                        Image(systemName: "chevron.down") // Dropdown icon
                            .resizable()
                            .frame(width: 10, height: 6)
                            .foregroundColor(Color.white)
                    }
                }

                Spacer()
                
                Image(systemName: isAscendingOrder ? "arrow.up.square.fill" : "arrow.down.square.fill") // Icon for sorting
                    .resizable()
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        isAscendingOrder.toggle()
                    }
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filteredServices, id: \.0.id) { (service, score) in
                        Button(action: {
                            if service.ride_method == "walking" {
                                transportViewModel.currentTransportType = .walking
                            } else if service.ride_method == "driving" {
                                transportViewModel.currentTransportType = .automobile
                            } else if service.ride_method == "biking" {
                                // using .any for biking right now
                                transportViewModel.currentTransportType = .walking
                            } else {
                                // default will be car for now
                                transportViewModel.currentTransportType = .automobile
                            }
                          
                            if service.name == "Brazos Bus Service" && self.buses.count != 0 {

                                fromTo.to = BusStop1
                                changeShowBusRoute()
                            }
                        }) {
                            HStack {
                                // Image on the left
                                Image(systemName: iconName(for: service.ride_method)) // Make sure to add `iconName` to your `Service` model
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50) // Set the image size as needed
                                    .padding(.trailing, 10)
                                    .foregroundColor(.black)
                                
                                // Name in the middle with min and max person counts
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    if service.name == "Walking" {
                                        Text("Time: \(Int(transportViewModel.walkRoute.expectedTravelTime / 60)) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    } else if service.name == "Biking" {
                                        Text("Time: \(transportViewModel.bikeTimeEstimate) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    } else {
                                        Text("Time: \(service.criteria.time) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    }
                                    Text(String(format: "Score: %.2f points", score))
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                }
                                
                                Spacer() // This will push the following elements to the right
                                
                                // Cost per person and minimum number of passengers on the right
                                VStack(alignment: .trailing) {
                                    // Format the price and timeEstimate as needed
                                    Text(String(format: "%.2f /person", service.criteria.price))
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Text("Carbon emissions: \(service.criteria.carbon_emissions) g/km") // Adjust based on actual data
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                }
                            }
                            .modifier(ServiceModifier()) // Use your ServiceModifier for consistent styling
                        }
                    }
                }
                .padding(.horizontal)
                .padding(20)
                .onChange(of: selectedSortOption) { _ in
                    refreshView.toggle() // Force a view refresh
                    
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("No Buses"),
                        message: Text("There are no buses available at this time!"),
                        primaryButton: .default(Text("OK")) {
                            // Additional action to perform when the OK button is tapped
                            
                        },
                        secondaryButton: .cancel() // Optional secondary button (e.g., for Cancel)
                    )
                }
            }
            .onChange(of: selectedTransportationModes) { _ in
                filteredServices = transportViewModel.filterServices(modes: selectedTransportationModes, sorting_options: selectedSortingOptions)
            }
            .onChange(of: selectedSortingOptions) { _ in
                filteredServices = transportViewModel.filterServices(modes: selectedTransportationModes, sorting_options: selectedSortingOptions)
            }
            .onChange(of: selectedSortOption) { newValue in
                filteredServices = transportViewModel.sortServices(services: filteredServices, for: newValue, isAscending: isAscendingOrder)
            }
            .onChange(of: isAscendingOrder) { _ in
                filteredServices = transportViewModel.sortServices(services: filteredServices, for: selectedSortOption, isAscending: isAscendingOrder)
            }
        }
        .frame(maxWidth: .infinity)
        .background(maroonColor.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
        .task {
            do {
                // all services
                try await transportViewModel.fetchServices()
              
                // update bike and walk info
                transportViewModel.updateBikeServiceTime(time: transportViewModel.bikeTimeEstimate)
                transportViewModel.updateCaloriesEstimates()
                transportViewModel.updateWalkServiceTime(time: Int(transportViewModel.walkRoute.expectedTravelTime / 60))
                
                // veo ride
                let defaults = UserDefaults.standard
                let veoToken = defaults.string(forKey: "veoToken")
                let veo_result = try await transportViewModel.findVEO(veoToken: veoToken ?? "none")
                // Include unlockFee in initial price
                transportViewModel.updateVeoInfo(info: veo_result)
                current_veo_price = (veo_result.price.price + veo_result.price.unlockFee)
              
                // sort and filter
                let filtered = transportViewModel.filterServices(modes: selectedTransportationModes, sorting_options: selectedSortingOptions)
                filteredServices = transportViewModel.sortServices(services: filtered, for: selectedSortOption, isAscending: isAscendingOrder)
                                

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
    
    // Helper function to map ride_method to systemName
    func iconName(for rideMethod: String) -> String {
        switch rideMethod {
        case "driving":
            return "car.fill"
        case "biking":
            return "bicycle"
        case "walking":
            return "figure.walk"
        // Add more cases as needed
        case "transit":
            return "bus.fill"
        default:
            return "questionmark" // or any default icon you prefer
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

struct AlertWrapper: UIViewControllerRepresentable {
    let title: String
    let message: String
    let actionTitle: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        
        // This is important to capture and manage the presentation in the SwiftUI environment
        let viewController = UIViewController()
        viewController.present(alert, animated: true, completion: nil)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
