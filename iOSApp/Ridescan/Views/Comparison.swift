//
//  Comparison.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/31/23.
//

import Foundation
import SwiftUI
import Models

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
    
    @ObservedObject var transportViewModel = TransportViewModel()
    
    // user criteria preferences
    @State private var criteriaPrefs: [Criteria] = []
    
    // Fetii info
    @State var current_fetii_price = 15.0
    @State var current_fetii_min_people = 5
    @State var current_fetii_max_people = 15
    
    // BTD Bus info
    @State var has_bus_data = "No data"
    @State private var buses: [BrazosDriver] = []
	    
    @State private var filteredServices: [(Service, Double)] = []
	
	@State private var refreshView: Bool = false
	
	@State private var selectedSortOption: SortingOption = .score
    @State private var selectedTransportationModes: Set<TransportationMode> = Set(TransportationMode.allCases)
    @State private var selectedSortingOptions: Set<SortingFilters> = []

    @State private var isAllSelected: Bool = false

	@State private var showTransportationPicker: Bool = false
	@State private var showSortingPicker: Bool = false
    @State private var isAscendingOrder = true

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
		.background(maroonColor.opacity(0.8))
        .frame(maxWidth: .infinity)
		
		.edgesIgnoringSafeArea(.all)
        .task {
            do {
                try await transportViewModel.fetchServices()
                transportViewModel.updateBikeServiceTime(time: transportViewModel.bikeTimeEstimate)
                transportViewModel.updateCaloriesEstimates()
                transportViewModel.updateWalkServiceTime(time: Int(transportViewModel.walkRoute.expectedTravelTime / 60))
                let filtered = transportViewModel.filterServices(modes: selectedTransportationModes, sorting_options: selectedSortingOptions)
                filteredServices = transportViewModel.sortServices(services: filtered, for: selectedSortOption, isAscending: isAscendingOrder)
                
            } catch {
                // Handle the error here. Perhaps by showing an alert to the user or logging the error.
                print("Error fetching data: \(error)")
            }
        }
	}
    
    func fetchBusData() {
        // Replace with your endpoint
        let baseURL = "https://www.ridebtd.org/Services/JSONPRelay.svc/GetMapVehiclePoints?apiKey=8882812681"
        guard let url = URL(string: baseURL) else {
            has_bus_data = "Invalid URL"
            return
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
                    var newBuses = [BrazosDriver]()
                    for dict in jsonArray {
                        if let lat = dict["Latitude"] as? Double,
                           let lon = dict["Longitude"] as? Double,
                           let id = dict["RouteID"] as? Int {
                            let driver = BrazosDriver(RouteId: id, lat: lat, lng: lon)
                            newBuses.append(driver)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        buses = newBuses
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
        default:
            return "questionmark" // or any default icon you prefer
        }
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
