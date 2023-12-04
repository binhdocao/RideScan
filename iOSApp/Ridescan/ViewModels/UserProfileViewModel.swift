//
//  UserProfileViewModel.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Models
import Foundation
import SwiftBSON
import SwiftUI
import Security

class UserProfileViewModel: ObservableObject {
    
    /// The current user.
    @Published var user: User = User(firstname: "Place", lastname: "Holder", email: "placeholder@abc.com", phone: "9876543210", password: "password")
    
    /// Logs user in from the backend server.
    func login(emailOrPhone: String, password: String) async throws {
        
        let route = "api/user/login/\(emailOrPhone)/\(password)"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        // search for the user credentials in the database
        let user = try await HTTP.get(url: userURL, dataType: User.self)
        
        // save user data to UserDefaults
        do {
            let userData = try JSONEncoder().encode(user)
            try KeychainService.save(key: "userInfo", data: userData)
        } catch {
            print("Failed to encode and save user data: \(error)")
        }
        
        // set the user on the main thread to publish and update views
        DispatchQueue.main.async {
            self.user = user
        }
        
    }

    
    /// Create user on the backend server.
    func createUser(user: User) async throws {
        let route = "api/user/create"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        // Add user to the database.
        let userId: AddUserResponse = try await HTTP.post(url: userURL, body: user)
        
        print(userId.id)
        
        // Set the new properties for the user
        DispatchQueue.main.async {
            self.user = User(id: userId.id, firstname: user.firstname, lastname: user.lastname, email: user.email, phone: user.phone, password: user.password)
            
            // Save user data to UserDefaults
            do {
                let userData = try JSONEncoder().encode(self.user)
                try KeychainService.save(key: "userInfo", data: userData)
            } catch {
                print("Failed to encode and save user data: \(error)")
            }
        }
    }



    
    /// Update user info on the backend server.
    func updateUserInfo() async throws {
        
        let route = "api/user/update"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        // Create a dictionary with the updated user data.
        let updatedUserData = self.user
        
        // Send a PUT or PATCH request to update the user data.
        try await HTTP.patch(url: userURL, body: updatedUserData)
    }

    func deleteUser() async throws {

        try await HTTP.delete(url: self.user.resourceURL)
        
    }

    func handleAppleLogin(userIdentifier: String, fullName: PersonNameComponents?, email: String?) async throws {
        // Check if the user exists by querying the backend
        let userExists = await checkIfUserExists(userIdentifier: userIdentifier)

        if userExists != nil {
            // User exists, so log them in
            do {
                print("Userexists -handle")
                // Perform login with the existing user's identifier
                try await login(emailOrPhone: "\(userIdentifier)@appleid.com", password: "defaultApplePassword")
            } catch {
                print("Error logging in existing user: \(error)")
            }
        } else {
            // User does not exist, create a new user
            
            let firstname = fullName?.givenName ?? "Unknown"
            let lastname = fullName?.familyName ?? "Unknown"
            let userEmail = email ?? "\(userIdentifier)@appleid.com"  // Use unique email

            // Set the `_id` field of the new user to the `userIdentifier`
            let newUser = User(id: userIdentifier, firstname: firstname, lastname: lastname, email: userEmail, phone: "0000000000", password: "defaultApplePassword")

            do {
                // Attempt to create the new user
                try await createUser(user: newUser)
            } catch {
                print("Error creating a new user: \(error)")
            }
        }
    }

    // Method to check if user exists in backend
    private func checkIfUserExists(userIdentifier: String) async -> User? {
        let route = "api/user/apple-login/\(userIdentifier)"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
            
        do {
            // Attempt to get the user using the provided URL
            let user: User? = try await HTTP.get(url: userURL, dataType: User.self)
            return user  // Return the user object if found
        } catch {
            print("Error checking user existence: \(error)")
            return nil  // Return nil if there's an error or if no user is found
        }
    }

    /// Starts VEO authentication process
    func VEO() async throws {

        let authURL = URL(string: "https://cluster-prod.veoride.com/api/customers/auth/auth-code?phone=\(user.phone)")!

        try await HTTP.get(url: authURL, dataType: VEOVerificationRequest.self)
    }

    /// Finish VEO verification process
    func VEOVerify(verification: String) async throws {
        let verifyURL = URL(string: "https://cluster-prod.veoride.com/api/customers/auth/auth-code/verification")!
        
        // Retrieve and decode user data from Keychain
        guard let userData = try KeychainService.load(key: "userInfo"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }


        // Prepare JSON data for the request
        let json: [String: String] = [
            "phone": user.phone,
            "phoneModel": "iPhone 12",
            "appVersion": "4.1.5",
            "code": verification
        ]
                
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        

        // Create the request
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Perform the request
        let (data, _) = try await URLSession.shared.data(for: request)

        // Handle the response
        let responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
        if let responseJSON = responseJSON as? [String: Any],
           let tempJSON = responseJSON["data"] as? [String: Any],
           let veoToken = tempJSON["token"] as? String {
            UserDefaults.standard.set(veoToken, forKey: "veoToken")
        }
    }

}
