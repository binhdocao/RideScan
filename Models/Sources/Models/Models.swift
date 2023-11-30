//
//  Models.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Foundation
import SwiftBSON
import CoreLocation
/**
 * Represents a user.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 * This type conforms to `Identifiable` so that SwiftUI is able to uniquely identify instances of this type when they
 * are used in the iOS interface.
 */

public struct User: Identifiable, Codable {
    
    /// Unique identifier.
    public var id: String?
    public var firstname: String
    public var lastname: String
    public var email: String
    public var phone: String
    public var password: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id", firstname, lastname, email, phone, password
    }

    /// Initializes a new `User` instance. If an `id` is not provided, a new one will be generated automatically.
    public init(
        id: String? = nil,
        firstname: String,
        lastname: String,
        email: String,
        phone: String,
        password: String
    ) {
        self.id = id ?? BSONObjectID().hex
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.phone = phone
        self.password = password
    }
}


public struct AddUserResponse: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

/**
 * Models the information set in a PATCH request by the frontend and an `updateOne` query by the backend to update user first and email.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 */
public struct UpdateUserResponse: Codable {
    public let id: String // Use String instead of BSONObjectID
    public let message: String

    public init(id: String, message: String) {
        self.id = id
        self.message = message
    }
}


/// User location
public struct FindFetiiRequest: Codable {
    public let userLatitude: String
    public let userLongitude: String
    public let pickup_long_address: String
    public let pickup_short_address: String
    
    public let destLatitude: String
    public let destLongitude: String
    public let dropoff_long_address: String
    public let dropoff_short_address: String
    
    /// Initializes a new `UserLoc` instance.
    public init(userLatitude: String, userLongitude: String, pickup_long_address: String, pickup_short_address: String, destLatitude: String, destLongitude: String, dropoff_long_address: String, dropoff_short_address: String) {
        self.userLatitude = userLatitude
        self.userLongitude = userLongitude
        self.pickup_long_address = pickup_long_address
        self.pickup_short_address = pickup_long_address
        
        self.destLatitude = destLatitude
        self.destLongitude = destLongitude
        self.dropoff_long_address = dropoff_long_address
        self.dropoff_short_address = dropoff_short_address
    }
}

public struct UserLoc: Codable {
    public let lat: String
    public let lng: String
    
    /// Initializes a new `UserUpdate` instance.
    public init(lat: String, lng: String) {
        self.lat = lat
        self.lng = lng
    }
}
///

/// Fetii Models
public struct FindFetiiResponse: Codable {
    public let status: Int
    public let message: String
    public let msg: String
    public let data: [Ride]
    public let booking_data_collection_id: Int
    public let no_vehicles_available: Bool
    public let max_schedule_days: Int
}

public struct Ride: Codable {
    public let id: Int
    public let radius_id: Int
    public let name: String
    public let image: String
    public let status: String
    public let display_order: Int
    public let direct_max_passengers: Int
    public let min_charge_per_person: Double
    public let direct_min_passengers: Int
    public let radius_surge_rate: Int
    public let vehicles_count: Int
    public let running_vehicles_count: Int
    public let km: Double
    public let age_surge_charge: Int
   
}

public struct LocateFetiiResponse: Codable {
    public let status: Int
    public let message: String
    public let msg: String
    public let data: [Driver]
}

public struct Driver: Codable {
    public let id: Int
    public let lat: Double
    public let lng: Double
    public let angle: String
    public let distance: Double
    public let vehicle_type: Vehicletype
}

public struct Vehicletype: Codable {
    public let id: Int
    public let top_image: String
}
///
///
public struct BrazosAPIResponse: Codable {
    public let status: Int
    public let message: String
    public let msg: String
    public var data: [BrazosDriver]
}
//
public struct BrazosDriver: Codable {
    public let RouteId: Int
    public let lat: Double
    public let lng: Double
    public var stops: [CLLocationCoordinate2D] = [] // stops is not decodable. hardcoded instead
    
    public init(RouteId: Int, lat: Double, lng: Double, stops: [CLLocationCoordinate2D] = [] ) {
        self.RouteId = RouteId
        self.lat = lat
        self.lng = lng
        self.stops = stops
    }
    
    private enum CodingKeys: String, CodingKey {
        case RouteId, lat, lng
        // Exclude 'stops' from coding
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        RouteId = try container.decode(Int.self, forKey: .RouteId)
        lat = try container.decode(Double.self, forKey: .lat)
        lng = try container.decode(Double.self, forKey: .lng)
        // Do not decode stops
    }
        
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(RouteId, forKey: .RouteId)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        // Do not encode stops
    }
    
}
//
public struct BrazosVehicleType: Codable {
    public let id: Int
    public let top_image: String
}
///
///
public struct VEOVerificationRequest: Codable {
    public let msg: String
    public let code: Int
    public let data: String
}

public struct VEOVerificationResponseData: Codable {
    public let token: String
    public let isLogin: Bool
}

public struct VEOVerificationResponse: Codable {
    public let msg: String
    public let code: Int
    public let data: VEOVerificationResponseData
}

public struct VEOPrice: Codable {
    public let price: Double
    public let frequency: Int
    public let unlockFee: Double
    public let freeRideMinutes: String?
}

public struct VEOPriceLocation: Codable {
    public let price: VEOPrice
    public let closestBikes: [BikeDistance]
    
    /// Initializes a new `UserLoc` instance.
    public init(price: VEOPrice, closestBikes: [BikeDistance]) {
        self.price = price
        self.closestBikes = closestBikes
    }
}

public struct VEOBikeInfo: Codable {
    public let vehicleNumber: Int
    public let vehicleType: Int
    public let vehicleVersion: String
    public let locked: Bool
    public let chainLocked: String?
    public let mac: String
    public let connected: Bool
    public let vehicleBattery: Int
    public let price: VEOPrice
    public let chainLock: String?
}

public struct VEOBikeResponse: Codable {
    public let msg: String
    public let code: Int
    public let data: VEOBikeInfo
}

public struct BikeDistance: Codable {
    public let lat: Double
    public let lng: Double
    public let distance: Double
    
    /// Initializes a new `UserLoc` instance.
    public init(lat: Double, lng: Double, distance: Double) {
        self.lat = lat
        self.lng = lng
        self.distance = distance
    }
}

public struct BikeLoc: Codable {
    public let lat: Double
    public let lng: Double
}

public struct FindVEORequest: Codable {
    public let userLatitude: String
    public let userLongitude: String
    public let veoToken: String
    
    /// Initializes a new `UserLoc` instance.
    public init(userLatitude: String, userLongitude: String, veoToken: String) {
        self.userLatitude = userLatitude
        self.userLongitude = userLongitude
        self.veoToken = veoToken
    }
}

public struct FindVEOResponseData: Codable {
    public let vehicleNumber: Int
    public let vehicleType: Int
    public let vehicleVersion: String
    public let iotBattery: Int
    public let vehicleBattery: Int
    public let location: BikeLoc
}

public struct FindVEOResponse: Codable {
    public let msg: String
    public let code: Int
    public let data: [FindVEOResponseData]
}
