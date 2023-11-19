//
//  UserProfileViewModel.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Models
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
    func createUser(firstname: String, lastname: String, email: String, phone: String, password: String) async throws {
        
        let route = "api/user/create"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let newUser = User(firstname: firstname, lastname: lastname, email: email, phone: phone, password: password)
        
        // Add user to the database.
        let userId: AddUserResponse = try await HTTP.post(url: userURL, body: newUser)
        
        print(userId.id)
        
        // set the new properties for the user
        DispatchQueue.main.async {
            self.user = User(id: userId.id, firstname: firstname, lastname: lastname, email: email, phone: phone, password: password) ?? self.user
            
            // save user data to UserDefaults
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
    
}
