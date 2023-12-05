//
//  LogIn.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/24/23.
//

import SwiftUI
import Combine

struct LogInView: View {
	
	/// Model for the data in this view.
	@StateObject private var viewModel = UserProfileViewModel()
	
	@State private var busy = false
	@State private var errorMessage: String?
	
	@State private var emailOrPhone = ""
	@State private var password = ""
	
	@State private var loginSuccess = false
	@State private var isNavigationActive = false
	
	@EnvironmentObject var userSettings: UserSettings

	
	var body: some View {
		VStack(spacing: 20) {
			Text("Sign in with your email or phone number")
				.font(.title)
				.fontWeight(.bold)
			
			TextField("Email or Phone Number", text: $emailOrPhone)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.autocapitalization(.none)
				.onChange(of: emailOrPhone) { _ in
					errorMessage = nil // Clear the error message when the emailOrPhone field is edited
				}
			
			SecureField("Password", text: $password)
				.textFieldStyle(RoundedBorderTextFieldStyle())
				.autocapitalization(.none)
				.onChange(of: password) { _ in
					errorMessage = nil // Clear the error message when the emailOrPhone field is edited
				}
			
			if errorMessage != nil { // Show error message conditionally
				Text(errorMessage!)
					.foregroundColor(.red)
					.font(.caption)
			}
			
			Button(action: {
				Task {
					do {
						try await viewModel.login(emailOrPhone: emailOrPhone, password: password)
						userSettings.isAuthenticated = true
						loginSuccess = true
					} catch {
						// Handle errors here (loginSuccess will be set in the ViewModel)
						loginSuccess = false
						errorMessage = "Invalid credentials" // Set error message
						print("Error updating user info: \(error)")
					}
				}
				
			}) {
				Text("Log In")
					.foregroundColor(.white)
					.frame(maxWidth: .infinity, maxHeight: 50)
					.background(maroonColor)
					.cornerRadius(8)
			}
			Spacer()
			
			NavigationLink(destination: MapView(), isActive: $loginSuccess) {
				EmptyView() // Use NavigationLink to navigate to VeoAuth View then MapView
			}
		}
		.padding(.horizontal, 20)
	}
}


