//
//  UserProfileViewModel.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Models
import SwiftUI

/// Models the data used in the `KittenList` view.
class UserProfileViewModel: ObservableObject {
    /// The list of kittens to display.
    @Published var user: User = User(firstName: "Place", lastName: "Holder", email: "placeholder@abc.com", phone: "9876543210")

    /// Loads user from the backend server.
    func fetchUserInfo() async throws {
        
        let userID = "6524674ca26a5ad3e29b2960"
        let userURL = HTTP.baseURL.appendingPathComponent(userID)
        
        let user = try await HTTP.get(url: userURL, dataType: User.self)
        // we do this on the main queue so that when the value is updated the view will automatically be refreshed.
        DispatchQueue.main.async {
            self.user = user
        }
    }
    
    /// Update user info on the backend server.
    func updateUserInfo(firstName: String, email: String) async throws {
        let userID = "6524674ca26a5ad3e29b2960"
        let userURL = HTTP.baseURL.appendingPathComponent(userID)
        
        // Create a dictionary with the updated user data.
        let updatedUserData = UserUpdate(firstName: firstName, email: email)
        
        do {
            // Send a PUT or PATCH request to update the user data.
            try await HTTP.patch(url: userURL, body: updatedUserData)
            
            // set the new properties for the user
            DispatchQueue.main.async {
                self.user = User(id: self.user.id, firstName: firstName, lastName: self.user.lastName, email: email, phone: self.user.phone)
            }
            
        } catch {
            // Handle errors here
            print("Error updating user info: \(error)")
        }
    }

    
}
