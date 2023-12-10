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
    @Published var walkTimeEstimate: Int = 0
    
    // Calorie estimates
    @Published var walkCaloriesEstimate: Double = 0.0
    @Published var bikeCaloriesEstimate: Double = 0.0
    
    // Max values for normalization
    @Published var max_price: Double = 0.0
    @Published var max_time: Int = 0
    @Published var max_cals: Int = 0
    
    // Fetii
    @Published var fetiiInfo: LocateFetiiResponse = LocateFetiiResponse()
    @Published var fetiiRidesToDisplay: [Driver] = [Driver]()
    
    // veo
    @Published var veoInfo: VEOPriceLocation = VEOPriceLocation()
    @Published var bikesToDisplay: [BikeDistance] = [BikeDistance]()
    
    // bus
    @Published var busTimeEstimate: Double = 0
    @Published var has_bus_data: Bool = true
    
    // Reviews
    @Published var popoverService: Service = Service()
    @Published var reviewText: String = ""
    @Published var reviewRating: Int = 3 // Assuming a 5-star rating system
    
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
    
    func displayBikes() {
        // Ensure that there are enough bikes to extract the first 5
            if veoInfo.closestBikes.count >= 5 {
                // Get the first 5 bikes
                bikesToDisplay = Array(veoInfo.closestBikes.prefix(5))
            } else {
                // If there are less than 5 bikes, take as many as available
                bikesToDisplay = veoInfo.closestBikes
            }
    }
    
    func displayFetii() {
        // Ensure that there are enough bikes to extract the first 5
            if fetiiInfo.data.count >= 5 {
                // Get the first 5 bikes
                fetiiRidesToDisplay = Array(fetiiInfo.data.prefix(5))
            } else {
                // If there are less than 5 rides, take as many as available
                fetiiRidesToDisplay = fetiiInfo.data
            }
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
        walkTimeEstimate = time
        for (index, serviceTuple) in services.enumerated() {
            var service = serviceTuple.0
            if service.ride_method == "walking" {
                // Update the time criteria for the biking service
                service.criteria.time = walkTimeEstimate
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
    
    func submitReview() async throws -> ReviewResponse {
        // Create the review object
        let newReview = Review(
            id: UUID().uuidString, // Generate a new ID for the review
            date: Date().formatted(), // Use the current date
            rating: reviewRating,
            text: reviewText
        )

        popoverService.reviews.append(newReview)

        // Update the corresponding service in the services array
        if let index = services.firstIndex(where: { $0.0.id == popoverService.id }) {
            services[index].0 = popoverService
        }
        
        let route = "api/services/review"
        let reviewURL = HTTP.baseURL.appendingPathComponent(route)

        // Prepare the request body
        let requestBody: ReviewRequest = ReviewRequest(serviceId: popoverService.id.hex, review: newReview)
        
        // Perform the API call to submit the review
        // This might be a POST request, but adjust according to your API's specification
        let response: ReviewResponse = try await HTTP.post(url: reviewURL, body: requestBody)
        
        // Clear the input fields
        reviewText = ""
        reviewRating = 3
        
        return response
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
        var route = "api/services/"
        
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

        var servicesResponse = try await HTTP.get(url: urlWithQuery, dataType: [Service].self)
        
        
        // update time and calories for biking and walking
        var index = servicesResponse.count - 1
        while index >= 0 {
            var service = servicesResponse[index]

            if service.ride_method == "biking" {
                if service.name == "VeoRide" {
                    // veo ride
                    let defaults = UserDefaults.standard
                    let veoToken = defaults.string(forKey: "veoToken")
                    let veo_result = try await findVEO(veoToken: veoToken ?? "none")
                    
                    service.criteria.time = bikeTimeEstimate + 5
                    service.criteria.price = veo_result.price.unlockFee + (veo_result.price.price * (veo_result.closestBikes.first?.distance ?? 0))
                    servicesResponse[index] = service
                } else {
                    // Update the calories burned criteria for the biking service
                    service.criteria.calories_burned = Int(bikeCaloriesEstimate)
                    service.criteria.time = bikeTimeEstimate
                    servicesResponse[index] = service
                }
            } else if service.ride_method == "walking" {
                // Update the calories burned criteria for the walking service
                service.criteria.calories_burned = Int(walkCaloriesEstimate)
                service.criteria.time = walkTimeEstimate
                servicesResponse[index] = service
            } else if service.name == "Fetii" {
                service.criteria.time = service.criteria.time + Int(carRoute.expectedTravelTime / 60)
                servicesResponse[index] = service
            } else if service.name == "Brazos Bus Service" && !has_bus_data {
                servicesResponse.remove(at: index)
            } else if service.name == "Brazos Bus Service" {
                service.criteria.time = Int(busTimeEstimate)
                servicesResponse[index] = service
            }

            index -= 1
        }
        
        route = "api/fetii/locate"
        
        urlComponents = URLComponents(string: HTTP.baseURL.appendingPathComponent(route).absoluteString)
        
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
        
        do {
            fetiiInfo = try await HTTP.get(url: urlWithQuery, dataType: LocateFetiiResponse.self)
        } catch {
            print("Error fetching Fetii information: \(error.localizedDescription)")
        }

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
            print("Calculating score for: \(service.name)")
            let score = calculateScore(for: service.criteria, with: multipliers)
            return (service, score)
        }
        
        // Sort the services by score in descending order
        scoredServices.sort { $0.1 > $1.1 }
        self.services = scoredServices
        
            // Update the UI on the main thread with sorted services
            /*DispatchQueue.main.async {
                self.services = scoredServices
            } */
        

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
        let carbonEmissionsMax = 800.0
        
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
        var max_score = 0.0
        for case let (label?, value) in mirror.children {
            if let multiplier = multipliersDictionary[nameMappings[label]!] {
                // Standardize carbon emissions
                if label == "price" {
                    let price = value as? Double ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - price / max_price) : (price / max_price)
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for price")
                } else if label == "time" {
                    let time = value as? Int ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - Double(time) / Double(max_time)) : (Double(time) / Double(max_time))
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for time")

                } else if label == "calories_burned" {
                    let calories = value as? Int ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - Double(calories) / Double(max_cals)) : (Double(calories) / Double(max_cals))
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for calories_burned")

                } else if label == "experience" {
                    let experience = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && experience) || (!selectedVal && !experience) ? 0.7 : 0
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += 0.7 * exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for experience")

                } else if label == "small_business" {
                    let small_business = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && small_business) || (!selectedVal && !small_business) ? 0.7 : 0
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += 0.7 * exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for small_business")

                } else if label == "public" {
                    let is_public = value as? Bool ?? false
                    let selectedVal = selectedValDictionary[nameMappings[label]!] == "True"
                    let scoreContribution = (selectedVal && is_public) || (!selectedVal && !is_public) ? 0.7 : 0
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += 0.7 * exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for public")

                } else if label == "carbon_emissions" {
                    let emissions = value as? Int ?? 0
                    let scoreContribution = selectedValDictionary[nameMappings[label]!] == "Lowest" ? (1 - Double(emissions) / carbonEmissionsMax): (Double(emissions) / carbonEmissionsMax)
                    score += scoreContribution * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
//                    print("Adding \(scoreContribution * Double(multiplier)) for carbon_emissions")

                } else if label == "safety_rating" {
                    let rating = value as? Int ?? 0
                    let normalizedValue = Double(rating) / safetyRatingMax
                    score += normalizedValue * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
//                    print("Adding \(normalizedValue * Double(multiplier)) for safety_rating")

                } else {
                    // default
                    let doubleVal = value as? Double ?? 0
                    score += doubleVal * exp(Double(multiplier))
                    max_score += exp(Double(multiplier))
                }
            }
            // other data type conversions...
        }
        return 100 * (score / max_score)
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
        
        let veoRequest = FindVEORequest(userLatitude: String(pickupLocation.latitude), userLongitude: String(pickupLocation.longitude))
        
        // send the request to backend
        veoInfo = try await HTTP.post(url: userURL, body: veoRequest)
        
        return veoInfo
    }
    
}

enum ServiceError: Error {
    case badRequest(reason: String)
    case internalServerError(reason: String)
}

