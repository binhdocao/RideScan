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
    public let firstName: String
    public let lastName: String
    public let email: String
    public let phone: String

    private enum CodingKeys: String, CodingKey {
        // We store the identifier under the name `id` on the struct to satisfy the requirements of the `Identifiable`
        // protocol, which this type conforms to in order to allow usage with certain SwiftUI features. However,
        // MongoDB uses the name `_id` for unique identifiers, so we need to use `_id` in the extended JSON
        // representation of this type.
        case id = "_id", firstName, lastName, email, phone
    }

    /// Initializes a new `User` instance. If an `id` is not provided, a new one will be generated automatically.
    public init(
        id: BSONObjectID = BSONObjectID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
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

/**
 * Models the information set in a PATCH request by the frontend and an `updateOne` query by the backend to update user first and email.
 * This type conforms to `Codable` to allow us to serialize it to and deserialize it from extended JSON and BSON.
 */
public struct UserUpdate: Codable {
    /// The new first name.
    public let firstName: String

    /// The new email.
    public let email: String

    /// Initializes a new `UserUpdate` instance.
    public init(firstName: String, email: String) {
        self.firstName = firstName
        self.email = email
    }
}
