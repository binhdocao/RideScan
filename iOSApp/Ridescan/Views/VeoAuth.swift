//
//  VeoAuth.swift
//  Ridescan
//
//  Created by Kelsey Jackson on 11/25/23.
//

import SwiftUI
import Combine

struct LogInView: View {
	
	/// Model for the data in this view.
	@StateObject private var viewModel = UserProfileViewModel()
	
	@State private var busy = false
	@State private var errorMessage: String?

	@State private var verification = ""
	@State private var VEOtoken = ""

	
	var body: some View {
		VStack(spacing: 20) {
			Text("Enter your VeoRide Verification code:")
				.font(.title)
				.fontWeight(.bold)
			
			TextField("Verification code", text: $verification)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.autocapitalization(.none)
				.onChange(of: verification) { _ in
					errorMessage = nil // Clear the error message when the verification field is edited
				}
			
			if errorMessage != nil { // Show error message conditionally
				Text(errorMessage!)
					.foregroundColor(.red)
					.font(.caption)
			}
			
			Button(action: {
				Task {
					do {
						VEOtoken = try await viewModel.VEOVerify(verification: verification)
					} catch {
						// Handle errors here
						errorMessage = "Invalid credentials" // Set error message
						print("Error updating user info: \(error)")
					}
				}
				
			}) {
				Text("Verify")
					.foregroundColor(.white)
					.frame(maxWidth: .infinity, maxHeight: 50)
					.background(maroonColor)
					.cornerRadius(8)
			}
			Spacer()
			
			NavigationLink(destination: MapView()) {
				EmptyView() // Use NavigationLink to navigate to MapView
			}
		}
		.padding(.horizontal, 20)
	}
}


