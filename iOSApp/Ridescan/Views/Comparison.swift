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
    
    @ObservedObject var transportViewModel = TransportViewModel()
    @State var current_fetii_price = 15.0
    @State var current_fetii_min_people = 5
    @State var current_fetii_max_people = 15
    @State var current_veo_price = 0.5
    
    // BTD Bus
    @State var has_bus_data = "No data"
    @State private var buses: [BrazosDriver] = []

    struct RideService: Identifiable {
        var id = UUID()
        let name: String
        let price: Double
        let min_people: Int
        let max_people: Int
        let iconName: String
        let timeEstimate: Int
    }
    
    var rideServices: [RideService] {
        [
            RideService(name: "Uber", price: 10.0, min_people: 1, max_people: 4,iconName: "car",timeEstimate: 6),
            RideService(name: "Lyft", price: 12.0, min_people: 1, max_people: 4,iconName: "car.fill",timeEstimate: 8),
            RideService(name: "Walking", price: 0.0, min_people: 0, max_people: 0, iconName: "figure.walk", timeEstimate: 30),
            RideService(name: "Piggyback", price: Double.random(in: 5...20), min_people: 1, max_people: 1,iconName: "person.fill",timeEstimate: 23),
            RideService(name: "Fetii", price: current_fetii_price, min_people: current_fetii_min_people, max_people: current_fetii_max_people, iconName: "bus", timeEstimate: 26),
            RideService(name: "Brazos Bus Service", price: 1.0, min_people: 1, max_people: 1, iconName: "bus", timeEstimate: 20),
            RideService(name: "VeoRide", price: current_veo_price, min_people: 1, max_people: 1, iconName: "figure.walk", timeEstimate: 22),
            // ... Add more services as needed
        ]
    }
    
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
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
            do {
                let defaults = UserDefaults.standard
                let veoToken = defaults.string(forKey: "veoToken")
                let veo_result = try await transportViewModel.findVEO(veoToken: veoToken ?? "none")
                // Include unlockFee in initial price
                current_veo_price = (veo_result.price.price + veo_result.price.unlockFee)

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
