//
//  BrazosTransitModels.swift
//  test
//
//  Created by Daniel Armenta on 10/26/23.
//

struct BrazosAPIResponse: Codable {
    let status: Int
    let message: String
    let msg: String
    var data: [BrazosDriver]
}
//
struct BrazosDriver: Codable {
    let RouteId: Int
    let lat: Double
    let lng: Double
    //let vehicle_type: BrazosVehicleType
}
//
struct BrazosVehicleType: Codable {
    let id: Int
    let top_image: String
}
