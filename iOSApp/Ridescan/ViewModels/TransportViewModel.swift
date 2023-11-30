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
    
    // distance
    @Published var total_distance: Double = 0.0
    
    // Time estimates for car, bike, walk
    @Published var carRoute: MKRoute = MKRoute()
    @Published var walkRoute: MKRoute = MKRoute()
    @Published var bikeTimeEstimate: Int = 0
    
    // Calorie estimates
    @Published var walkCaloriesEstimate: Double = 0.0
    @Published var bikeCaloriesEstimate: Double = 0.0
    
    // Max values for normalization
    @Published var max_price: Double = 0.0
    @Published var max_time: Int = 0
    @Published var max_cals: Int = 0
    
    // current transport type
    @Published var currentTransportType: MKDirectionsTransportType = .automobile
    
    // List of services
    @Published var services = [(Service, Double)]()
    
    @Published var filteredServices = [(Service, Double)]()
        
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
    
    func setCarRoute(route: MKRoute) {
        carRoute = route
    }
    
    func setWalkRoute(route: MKRoute) {
        walkRoute = route
    }
    
    func setCaloriesBurnedEstimate(dist: Double) {
        walkCaloriesEstimate = dist * 170
        bikeCaloriesEstimate = dist * 50
    }
    
    func updateCaloriesEstimates() {
        for (index, serviceTuple) in services.enumerated() {
            var service = serviceTuple.0
            if service.ride_method == "biking" {
                // Update the time criteria for the biking service
                service.criteria.calories_burned = Int(bikeCaloriesEstimate)
                services[index] = (service, serviceTuple.1)
            } else if service.ride_method == "walking" {
                // Update the time criteria for the biking service
                service.criteria.calories_burned = Int(walkCaloriesEstimate)
                services[index] = (service, serviceTuple.1)
            }
        }
    }
    
    func updateBikeServiceTime(time: Int) {
        bikeTimeEstimate = time
        for (index, serviceTuple) in services.enumerated() {
            var service = serviceTuple.0
            if service.ride_method == "biking" {
                // Update the time criteria for the biking service
                service.criteria.time = bikeTimeEstimate
                services[index] = (service, serviceTuple.1)
            }
        }
    }
    
    func updateWalkServiceTime(time: Int) {
        for (index, serviceTuple) in services.enumerated() {
            var service = serviceTuple.0
            if service.ride_method == "walking" {
                // Update the time criteria for the biking service
                service.criteria.time = time
                services[index] = (service, serviceTuple.1)
            }
        }
    }
    
    func updateVeoInfo(info: VEOPriceLocation) {
        for (index, serviceTuple) in services.enumerated() {
            var service = serviceTuple.0
            if service.name == "VeoRide" {
                // Update the time criteria for the biking service
                service.criteria.time = bikeTimeEstimate + 5
                service.criteria.price = info.price.unlockFee + (info.price.price * (info.closestBikes.first?.distance ?? 0))
                services[index] = (service, serviceTuple.1)
            }
        }
    }
    
    func setTotalDistance(distance: Double) {
        total_distance = distance
    }
    
    func setImage(image_url: String) {
        self.image_url = image_url
    }
    
    func filterServices(modes: Set<TransportationMode>, sorting_options: Set<SortingFilters>) -> [(Service, Double)] {
        var filteredServices = services

        // Filter by transportation modes
        if !modes.isEmpty {
            filteredServices = filteredServices.filter { service in
                modes.contains { mode in
                    service.0.ride_method == mode.rawValue
                }
            }
        }

        // Additional filtering based on sorting options
        for sortingOption in sorting_options {
            switch sortingOption {
            case .experience:
                filteredServices = filteredServices.filter { service in
                    // Assuming 'experience' is a boolean or a comparable property
                    service.0.criteria.experience
                }
            case .public:
                filteredServices = filteredServices.filter { service in
                    // Assuming 'public' is a boolean or a comparable property
                    service.0.criteria.public
                }
            case .small_business:
                filteredServices = filteredServices.filter { service in
                    // Assuming 'small_business' is a boolean or a comparable property
                    service.0.criteria.small_business
                }
            }
        }

        return filteredServices
    }
    
    func sortServices(services: [(Service, Double)], for option: SortingOption, isAscending: Bool) -> [(Service, Double)] {
        print(services)
        switch option {
        case .name:
            return services.sorted { isAscending ? $0.0.name > $1.0.name : $0.0.name < $1.0.name }
        case .price:
            return services.sorted { isAscending ? $0.0.criteria.price > $1.0.criteria.price : $0.0.criteria.price < $1.0.criteria.price }
        case .time:
            return services.sorted { isAscending ? $0.0.criteria.time > $1.0.criteria.time : $0.0.criteria.time < $1.0.criteria.time }
        case .experience:
            return services.sorted {
                isAscending ? ($0.0.criteria.experience && !$1.0.criteria.experience) : (!$0.0.criteria.experience && $1.0.criteria.experience)
            }
        case .public:
            return services.sorted {
                isAscending ? ($0.0.criteria.public && !$1.0.criteria.public) : (!$0.0.criteria.public && $1.0.criteria.public)
            }
        case .small_business:
            return services.sorted {
                isAscending ? ($0.0.criteria.small_business && !$1.0.criteria.small_business) : (!$0.0.criteria.small_business && $1.0.criteria.small_business)
            }
        case .safety:
            return services.sorted { isAscending ? $0.0.criteria.safety_rating > $1.0.criteria.safety_rating : $0.0.criteria.safety_rating < $1.0.criteria.safety_rating }
        case .carbon_emissions:
            return services.sorted { isAscending ? $0.0.criteria.carbon_emissions > $1.0.criteria.carbon_emissions : $0.0.criteria.carbon_emissions < $1.0.criteria.carbon_emissions }
        case .calories_burned:
            return services.sorted { isAscending ? $0.0.criteria.calories_burned > $1.0.criteria.calories_burned : $0.0.criteria.calories_burned < $1.0.criteria.calories_burned }
        case .score:
            return services.sorted { isAscending ? $0.1 > $1.1 : $0.1 < $1.1 }
        }
    }
    
    func fetchServices() async throws {
        let route = "api/services/"
        
        var urlComponents = URLComponents(string: HTTP.baseURL.appendingPathComponent(route).absoluteString)
    
        // Pickup location and destination information
        urlComponents?.queryItems = [
            URLQueryItem(name: "userLatitude", value: String(pickupLocation.latitude)),
            URLQueryItem(name: "userLongitude", value: String(pickupLocation.longitude)),
            URLQueryItem(name: "pickup_long_address", value: pickup_long_address),
            URLQueryItem(name: "pickup_short_address", value: pickup_short_address),
            URLQueryItem(name: "destLatitude", value: String(dropoffLocation.latitude)),
            URLQueryItem(name: "destLongitude", value: String(dropoffLocation.longitude)),
            URLQueryItem(name: "dropoff_long_address", value: dropoff_long_address),
            URLQueryItem(name: "dropoff_short_address", value: dropoff_short_address)
        ]

        guard let urlWithQuery = urlComponents?.url else {
            throw ServiceError.badRequest(reason: "Invalid URL for fetching services")
        }

        let servicesResponse = try await HTTP.get(url: urlWithQuery, dataType: [Service].self)

        // Now that we have the services, we need to calculate the scores
        
        // Attempt to load saved preferences
        var multipliers: [Criteria]?
        if let savedPreferences = UserDefaults.standard.data(forKey: "criteriaOrder"),
           let decodedPreferences = try? JSONDecoder().decode([Criteria].self, from: savedPreferences) {
            multipliers = decodedPreferences
        } else {
            multipliers = [
                Criteria(name: "Price", order: 1, multiplier: 8, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
                Criteria(name: "Time", order: 2, multiplier: 7, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
                Criteria(name: "Safety", order: 3, multiplier: 6, selectedVal: "Highest", possVals: ["Highest"]),
                Criteria(name: "Calories Burned", order: 4, multiplier: 5, selectedVal: "Highest", possVals: ["Lowest", "Highest"]),
                Criteria(name: "Carbon Emissions", order: 5, multiplier: 4, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
                Criteria(name: "Experience", order: 6, multiplier: 3, selectedVal: "True", possVals: ["True", "False"]),
                Criteria(name: "Small Businesses", order: 7, multiplier: 2, selectedVal: "True", possVals: ["True", "False"]),
                Criteria(name: "Public", order: 8, multiplier: 1, selectedVal: "True", possVals: ["True", "False"]),
            ]
        }
        
        // set the max_price and max_time
        for service in servicesResponse {
            if service.criteria.price > max_price {
                max_price = service.criteria.price
            }
            if service.criteria.time > max_time {
                max_time = service.criteria.time
            }
            if service.criteria.calories_burned > max_cals {
                max_cals = service.criteria.calories_burned
            }
        }
        
        // Calculate the score for each service
        var scoredServices = servicesResponse.map { service -> (Service, Double) in
            let score = calculateScore(for: service.criteria, with: multipliers)
            return (service, score)
        }
        
        // Sort the services by score in descending order
        scoredServices.sort { $0.1 > $1.1 }
        
        // Update the UI on the main thread with sorted services
        DispatchQueue.main.async {
            self.services = scoredServices
        }

    }
    
    // we need to convert between UI criteria names and mongoDB names
    let nameMappings = [
        "price": "Price",
        "time": "Time",
        "safety_rating": "Safety",
        "calories_burned": "Calories Burned",
        "carbon_emissions": "Carbon Emissions",
        "experience": "Experience",
        "small_business": "Small Business",
        "public": "Public"
    ]
    
    // Given a `Criteria` instance and an array of `Criteria` with multipliers,
    // calculate the score for that set of criteria.
    func calculateScore(for serviceCriteria: Models.Criteria, with multipliers: [Criteria]?) -> Double {
        
        // Constants for standardizing carbon emissions
        let carbonEmissionsMax = 500.0
        
        // Constants for safety_rating
        let safetyRatingMax = 100.0

        guard let multipliers = multipliers else { return 0 }

        // Create a dictionary from the array of multipliers
        let multipliersDictionary = multipliers.reduce(into: [:]) { dict, criteria in
            dict[criteria.name] = criteria.multiplier
        }
        
        // Create a dictionary from the array of selectedVals
        let selectedValDictionary = multipliers.reduce(into: [:]) { dict, criteria in
            dict[criteria.name] = criteria.selectedVal
        }

        // Use reflection to iterate over the properties of `serviceCriteria`
        let mirror = Mirror(reflecting: serviceCriteria)
        var score = 0.0
        for case let (label?, value) in mirror.children {
            if let multiplier = multipliersDictionary[nameMappings[label]!] {
                // Standardize carbon emissions
                if label == "price" {
                    let price = value as? Double ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - price / max_price) : (price / max_price)
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for price")
                } else if label == "time" {
                    let time = value as? Double ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - time / Double(max_time)) : (time / Double(max_time))
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for time")

                } else if label == "calories_burned" {
                    let calories = value as? Double ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - calories / Double(max_cals)) : (calories / Double(max_cals))
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for calories_burned")

                } else if label == "experience" {
                    let experience = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && experience) || (!selectedVal && !experience) ? 0.7 : 0
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for experience")

                } else if label == "small_business" {
                    let small_business = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && small_business) || (!selectedVal && !small_business) ? 0.7 : 0
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for small_business")

                } else if label == "public" {
                    let is_public = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && is_public) || (!selectedVal && !is_public) ? 0.7 : 0
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for public")

                } else if label == "carbon_emissions" {
                    let emissions = value as? Double ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - emissions / carbonEmissionsMax): (emissions / carbonEmissionsMax)
                    score += scoreContribution * Double(multiplier)
//                    print("Adding \(scoreContribution * Double(multiplier)) for carbon_emissions")

                } else if label == "safety_rating" {
                    let rating = value as? Double ?? 0
                    let normalizedValue = rating / safetyRatingMax
                    score += normalizedValue * Double(multiplier)
//                    print("Adding \(normalizedValue * Double(multiplier)) for safety_rating")

                } else {
                    // default
                    let doubleVal = value as? Double ?? 0
                    score += doubleVal * Double(multiplier)
                }
            }
            // other data type conversions...
        }
        return score
    }
        
    /// Logs user in from the backend server.
    func findFetii() async throws -> FindFetiiResponse {
        
        let route = "api/fetii/find/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let fetiiRequest = FindFetiiRequest(userLatitude: String(pickupLocation.latitude), userLongitude: String(pickupLocation.longitude), pickup_long_address: pickup_long_address, pickup_short_address: pickup_short_address, destLatitude: String(dropoffLocation.latitude), destLongitude: String(dropoffLocation.longitude), dropoff_long_address: dropoff_long_address, dropoff_short_address: dropoff_short_address)
        
        // send the request to backend
        let response: FindFetiiResponse = try await HTTP.post(url: userURL, body: fetiiRequest)
        
        return response
    }
    
    /// Logs user in from the backend server.
    func locateFetii() async throws -> LocateFetiiResponse {
        
        let route = "api/fetii/locate/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let fetiiRequest = UserLoc(lat: String(pickupLocation.latitude), lng: String(pickupLocation.longitude))
        
        // send the request to backend
        let response: LocateFetiiResponse = try await HTTP.post(url: userURL, body: fetiiRequest)
        
        return response
    }

    /// Logs user in from the backend server.
    func findVEO(veoToken: String) async throws -> VEOPriceLocation {
        
        let route = "api/veoride/find/"
        let userURL = HTTP.baseURL.appendingPathComponent(route)
        
        let veoRequest = FindVEORequest(userLatitude: String(pickupLocation.latitude), userLongitude: String(pickupLocation.longitude), veoToken: veoToken)
        
        // send the request to backend
        let response: VEOPriceLocation = try await HTTP.post(url: userURL, body: veoRequest)
        
        return response
    }
    
}

enum ServiceError: Error {
    case badRequest(reason: String)
    case internalServerError(reason: String)
}

