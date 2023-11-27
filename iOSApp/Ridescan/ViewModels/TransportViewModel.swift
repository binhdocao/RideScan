//
//  TransportViewModel.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/26/23.
//

import Models
import SwiftUI
import Security
import MapKit

class TransportViewModel: ObservableObject {
    
    /// The current user.
    @Published var driverFound: Bool = false
    @Published var pickupLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @Published var dropoffLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @Published var pickup_long_address: String = ""
    @Published var pickup_short_address: String = ""
    @Published var dropoff_long_address: String = ""
    @Published var dropoff_short_address: String = ""
    @Published var image_url: String = ""
    
    func setLocation(_ newLocation: CLLocationCoordinate2D, type: String) {
        if type == "dropoff" {
            self.dropoffLocation = newLocation
        } else {
            self.pickupLocation = newLocation
        }
    }
    
    func setAddresses(long_address: String, short_address: String, type: String) {
        if type == "dropoff" {
            self.dropoff_long_address = long_address
            self.dropoff_short_address = short_address
        } else {
            self.pickup_long_address = long_address
            self.pickup_short_address = short_address
        }
    }
    
    func setImage(image_url: String) {
        self.image_url = image_url
    }
        
    /// Logs user in from the backend server.
    func findFetii() async throws -> FindFetiiResponse {
        
        let route = "api/fetii/find/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let fetiiRequest = FindFetiiRequest(userLatitude: String(pickupLocation.latitude), userLongitude: String(pickupLocation.longitude), pickup_long_address: pickup_long_address, pickup_short_address: pickup_short_address, destLatitude: String(dropoffLocation.latitude), destLongitude: String(dropoffLocation.longitude), dropoff_long_address: dropoff_long_address, dropoff_short_address: dropoff_short_address)
        
        // send the request to backend
        let response: FindFetiiResponse = try await HTTP.post(url: userURL, body: fetiiRequest)
        
        return response
        
//        driverFound = !response.no_vehicles_available
        
        
        
//        // save user data to Keychain
//        do {
//            let userData = try JSONEncoder().encode(user)
//            try KeychainService.save(key: "userInfo", data: userData)
//        } catch {
//            print("Failed to encode and save user data: \(error)")
//        }
//        
//        // set the user on the main thread to publish and update views
//        DispatchQueue.main.async {
//            self.user = user
//        }
    }
    
    /// Logs user in from the backend server.
    func locateFetii() async throws -> LocateFetiiResponse {
        
        let route = "api/fetii/locate/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let fetiiRequest = UserLoc(lat: String(pickupLocation.latitude), lng: String(pickupLocation.longitude))
        
        // send the request to backend
        let response: LocateFetiiResponse = try await HTTP.post(url: userURL, body: fetiiRequest)
        
        return response
        
        
        
//        // save user data to Keychain
//        do {
//            let userData = try JSONEncoder().encode(user)
//            try KeychainService.save(key: "userInfo", data: userData)
//        } catch {
//            print("Failed to encode and save user data: \(error)")
//        }
//
//        // set the user on the main thread to publish and update views
//        DispatchQueue.main.async {
//            self.user = user
//        }
    }

    /// Logs user in from the backend server.
    func findVEO(veoToken: String) async throws -> VEOBikeResponse {
        
        let route = "api/veoride/find/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let veoRequest = FindVEORequest(userLatitude: String(pickupLocation.latitude), userLongitude: String(pickupLocation.longitude), veoToken: veoToken)
        
        // send the request to backend
        let response: VEOBikeResponse = try await HTTP.post(url: userURL, body: veoRequest)
        
        return response
    }
    
}

