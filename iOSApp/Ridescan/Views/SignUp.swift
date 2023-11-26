//
//  CreateAccount.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/24/23.
//

import SwiftUI
import Models

struct SignUpView: View {
    
    /// Model for the data in this view.
    @StateObject private var viewModel = UserProfileViewModel()
    
    @State private var busy = false
    @State private var errorMessage: String?
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    
    @State private var createAccountSuccess = false
    @State private var isNavigationActive = false
	
	@State private var confirmPassword = ""
	@State private var passwordsMatch = true
    
    // validation states
    @State private var validEmail = true
    @State private var validPhone = true
    @State private var validPassword = true
	
	@EnvironmentObject var userSettings: UserSettings

	
	private func checkPasswordsMatch() {
		passwordsMatch = password == confirmPassword
	}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sign up with your email or phone number")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("First Name", text: $firstname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Last Name", text: $lastname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            VStack(alignment: .leading, spacing: 0) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .border(validEmail ? Color.clear : Color.red)
                    .onChange(of: email) { _ in
                        validEmail = true
                    }
                if !validEmail {
                    Text("Invalid email")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                TextField("Phone", text: $phone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .border(validPhone ? Color.clear : Color.red)
                    .onTapGesture {
                        validPhone = true
                    }
                
                if !validPhone {
                    Text("Invalid phone number")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
			VStack(alignment: .center) {
				SecureField("Password", text: $password)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.autocapitalization(.none)
					.border(validPassword ? Color.clear : Color.red)
				
				if !validPassword {
					Text("Password must contain a minimum of eight characters, at least one letter and one number")
						.foregroundColor(.red)
						.font(.caption)
				}
				
				SecureField("Confirm Password", text: $confirmPassword)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.autocapitalization(.none)
					.border(passwordsMatch ? Color.clear : Color.red)
				
				if !passwordsMatch {
					Text("Passwords don't match")
						.foregroundColor(.red)
						.font(.caption)
				}
			}
            
			Button(action: {
				if validate() {
					Task {
						do {
							let newUser = User(firstname: firstname, lastname: lastname, email: email, phone: phone, password: password)
							try await viewModel.createUser(user: newUser)
							userSettings.isAuthenticated = true
							createAccountSuccess = true
							try await viewModel.VEO()
						} catch {
							// Handle errors here
							createAccountSuccess = false
							print("Error creating user: \(error)")
						}
					}
				}
			}) {
				Text("Create Account")
					.foregroundColor(.white)
					.frame(maxWidth: .infinity, maxHeight: 50)
					.background(maroonColor)
					.cornerRadius(8)
			}

            Spacer()
            
            NavigationLink(destination: VeoAuthView(), isActive: $createAccountSuccess) {
                EmptyView() // Use NavigationLink to navigate to VeoAuthView then MapView
                    
            }
        }
        .padding(.horizontal, 20)
    }
    
	private func validate() -> Bool {
		validEmail = email.isValidEmail
		validPhone = phone.isValidPhone
		validPassword = password.isValidPassword
		checkPasswordsMatch()
		
		return validEmail && validPhone && validPassword && passwordsMatch
	}
    
    
}

