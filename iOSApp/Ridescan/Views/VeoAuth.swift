//
//  VeoAuth.swift
//  Ridescan
//
//  Created by Kelsey Jackson on 11/25/23.
//

import SwiftUI
import Combine

struct VeoAuthView: View {
	
	/// Model for the data in this view.
	@StateObject private var viewModel = UserProfileViewModel()
	
	@State private var busy = false
	@State private var errorMessage: String?

	@State private var verification = ""	
	@EnvironmentObject var userSettings: UserSettings

	
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
						try await viewModel.VEOVerify(verification: verification)
						userSettings.isVerified = true
					} catch {
						// Handle errors here
						errorMessage = "VeoRide Verification Error" // Set error message
						print("Error verifying: \(error)")
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


