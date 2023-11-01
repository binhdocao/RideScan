//
//  FetiiModels.swift
//  test
//
//  Created by Gage Broberg on 9/18/23.
//

struct APIResponse: Codable {
    let status: Int
    let message: String
    let msg: String
    let data: [Driver]
}

struct Driver: Codable {
    let id: Int
    let lat: Double
    let lng: Double
    let angle: String
    let distance: Double
    let vehicle_type: VehicleType
}

struct VehicleType: Codable {
    let id: Int
    let top_image: String
}
