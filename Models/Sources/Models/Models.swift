//
//  Models.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Foundation
import SwiftBSON

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


/**
 * Represents a service.
 */
public struct Service: Identifiable, Codable {
    
    public let id: BSONObjectID
    
    // Service details
    public var ride_method: String
    public var user_proposed: Bool
    public var send_to_application: Bool
    
    // Reviews is an array of Review objects
    public var reviews: [Review]
    
    // Criteria
    public var criteria: Criteria
    
    // Name of the service
    public var name: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ride_method
        case user_proposed
        case send_to_application
        case reviews
        case criteria
        case name
    }

    public init(
        id: BSONObjectID = BSONObjectID(),
        ride_method: String,
        user_proposed: Bool,
        send_to_application: Bool,
        reviews: [Review],
        criteria: Criteria,
        name: String
    ) {
        self.id = id
        self.ride_method = ride_method
        self.user_proposed = user_proposed
        self.send_to_application = send_to_application
        self.reviews = reviews
        self.criteria = criteria
        self.name = name
    }
    
    public init?(
        id: String,
        ride_method: String,
        user_proposed: Bool,
        send_to_application: Bool,
        reviews: [Review],
        criteria: Criteria,
        name: String
    ) {
        guard let objectId = try? BSONObjectID(id) else { return nil }
        self.id = objectId
        self.ride_method = ride_method
        self.user_proposed = user_proposed
        self.send_to_application = send_to_application
        self.reviews = reviews
        self.criteria = criteria
        self.name = name
    }
}

// Object to hold the service and calculated score
public struct RideService: Identifiable, Codable {
    public var id: UUID
    public var service: Service
    public var score: Int
}

// Review struct as seen in the MongoDB document
public struct Review: Codable {
    public var date: String
    public var rating: Int
    public var text: String
}

// Criteria struct based on the MongoDB document
public struct Criteria: Codable {
    public var price: Double
    public var time: Int
    public var calories_burned: Int
    public var carbon_emissions: Int
    public var experience: Bool
    public var `public`: Bool
    public var small_business: Bool
    public var safety_rating: Int
}

public struct BikeDirectionsResponse: Decodable {
    // Define your properties here
    // For example:
    public var routes: [Route]
    // ...

    public struct Route: Decodable {
        public var legs: [Leg]
        // ...
    }

    public struct Leg: Decodable {
        public var distance: Distance
        public var duration: Duration
        // ...
    }

    public struct Distance: Decodable {
        public var text: String
        public var value: Int
    }

    public struct Duration: Decodable {
        public var text: String
        public var value: Int
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
    public let arriveIn_min_time: Int?
    public let arriveIn_max_time: Int?
    public let is_all_vehicles_running: Bool?
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
    
    public init(RouteId: Int, lat: Double, lng: Double) {
        self.RouteId = RouteId
        self.lat = lat
        self.lng = lng
    }
}
//
public struct BrazosVehicleType: Codable {
    public let id: Int
    public let top_image: String
}
///
