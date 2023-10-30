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
    public let id: BSONObjectID
    public let firstname: String
    public let lastname: String
    public let email: String
    public let phone: String
    public let password: String

    private enum CodingKeys: String, CodingKey {
        // We store the identifier under the name `id` on the struct to satisfy the requirements of the `Identifiable`
        // protocol, which this type conforms to in order to allow usage with certain SwiftUI features. However,
        // MongoDB uses the name `_id` for unique identifiers, so we need to use `_id` in the extended JSON
        // representation of this type.
        case id = "_id", firstname, lastname, email, phone, password
    }

    /// Initializes a new `User` instance. If an `id` is not provided, a new one will be generated automatically.
    public init(
        id: BSONObjectID = BSONObjectID(),
        firstname: String,
        lastname: String,
        email: String,
        phone: String,
        password: String
    ) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.phone = phone
        self.password = password
    }

    /// Initializes a new `User` instance. If an `id` is not provided, a new one will be generated automatically.
    public init?(
        id: String,
        firstname: String,
        lastname: String,
        email: String,
        phone: String,
        password: String
    ) {
        guard let objectId = try? BSONObjectID(id) else { return nil }
        self.id = objectId
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.phone = phone
        self.password = password
    }
        
}

/**
 * Represents a kitten.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 * This type conforms to `Identifiable` so that SwiftUI is able to uniquely identify instances of this type when they
 * are used in the iOS interface.
 */
public struct Kitten: Identifiable, Codable {
    /// Unique identifier.
    public let id: BSONObjectID

    /// Name.
    public let name: String

    /// Fur color.
    public let color: String

    /// Favorite food.
    public let favoriteFood: CatFood

    /// Last updated time.
    public let lastUpdateTime: Date

    private enum CodingKeys: String, CodingKey {
        // We store the identifier under the name `id` on the struct to satisfy the requirements of the `Identifiable`
        // protocol, which this type conforms to in order to allow usage with certain SwiftUI features. However,
        // MongoDB uses the name `_id` for unique identifiers, so we need to use `_id` in the extended JSON
        // representation of this type.
        case id = "_id", name, color, favoriteFood, lastUpdateTime
    }

    /// Initializes a new `Kitten` instance. If an `id` is not provided, a new one will be generated automatically.
    /// If a `lastUpdateTime` is not provided, the last update time will be set to the the current date/time.
    public init(
        id: BSONObjectID = BSONObjectID(),
        name: String,
        color: String,
        favoriteFood: CatFood,
        lastUpdateTime: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.favoriteFood = favoriteFood
        self.lastUpdateTime = lastUpdateTime
    }
}

/**
 * Cat food choices.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 * This type conforms to `Identifiable` so that SwiftUI is able to uniquely identify instances of this type when they
 * are used in the iOS interface.
 * This type conforms to `CaseIterable` so that we can list of the possible values in a SwiftUI picker.
 */
public enum CatFood: String, Codable, CaseIterable, Identifiable {
    public var id: Self { self }

    case salmon,
         tuna,
         chicken,
         turkey,
         beef
}

/**
 * Models the information set in a PATCH request by the frontend and an `updateOne` query by the backend to update a
 * kitten's favorite food choice.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 */
public struct KittenUpdate: Codable {
    /// The new favorite food.
    public let favoriteFood: CatFood

    /// The new last update time.
    public let lastUpdateTime: Date

    /// Initializes a new `KittenUpdate` instance. If `lastUpdateTime` is not provided it will be set to the current
    /// date/time.
    public init(newFavoriteFood: CatFood, lastUpdateTime: Date = Date()) {
        self.favoriteFood = newFavoriteFood
        self.lastUpdateTime = lastUpdateTime
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
public struct UserUpdate: Codable {
    /// The new first name.
    public let firstname: String

    /// The new email.
    public let email: String

    /// Initializes a new `UserUpdate` instance.
    public init(firstname: String, email: String) {
        self.firstname = firstname
        self.email = email
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
