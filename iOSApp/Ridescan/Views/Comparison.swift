//
//  Comparison.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/31/23.
//

import Foundation
import SwiftUI

enum SortingOption: String, CaseIterable {
	case name = "Name"
	case price = "Price"
}

enum TransportationMode: String, CaseIterable {
	case walking = "Walking"
	case driving = "Driving"
	case uber = "Uber"
	case lyft = "Lyft"
	case bike = "Rideshare Bike"
	// ... Add more modes as needed
}

struct ComparisonView: View {
	
	struct RideService: Identifiable {
		var id = UUID()
		let name: String
		let price: String
	}
	
	let rideServices: [RideService] = [
		RideService(name: "Uber", price: "$10"),
		RideService(name: "Lyft", price: "$12"),
		RideService(name: "Fetii", price: "$15")
		// ... Add more services as needed
	]
	
	@State private var refreshView: Bool = false

	
	var sortedRideServices: [RideService] {
		switch selectedSortOption {
		case .name:
			return rideServices.sorted { $0.name < $1.name }
		case .price:
			return rideServices.sorted { $0.price < $1.price }
		}
	}
	
	@State private var selectedSortOption: SortingOption = .name
	@State private var selectedTransportation: TransportationMode = .walking
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
							Text("\(service.name): $\(service.price)")
								.font(.body)
							Spacer()
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
		.frame(maxHeight: UIScreen.main.bounds.height / 3)
		.edgesIgnoringSafeArea(.all)
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
