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
            RideService(name: "Fetii", price: current_fetii_price, min_people: current_fetii_min_people, max_people: current_fetii_max_people,iconName: "bus", timeEstimate: 26)
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
                                Text("Min - Max: \(service.min_people) - \(service.max_people)")
                                    .font(.subheadline)
                            }

                            Spacer() // This will push the following elements to the right

                            // Cost per person and minimum number of passengers on the right
                            VStack(alignment: .trailing) {
                                Text(String(format: "$%.2f /person", service.price))
                                    .font(.body)
								Text("Time: \(service.timeEstimate) mins")
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
                let result = try await transportViewModel.findFetii()
                print(result.data.first)
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
