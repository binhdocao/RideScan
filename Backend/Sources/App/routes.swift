import Models
import MongoDBVapor
import Vapor

extension ReviewResponse: Content {}

// Adds API routes to the application.
func routes(_ app: Application) throws {
    /// Handles a request to load the list of users.
    app.get { req async throws -> [User] in
        try await req.findUsers()
    }

	/// Handles a request to load the list of services.
    app.get("api", "services") { req async throws -> [Service] in
        try await req.findServices(req: req)
    }

	// Route to handle review submission
    app.post("api", "services", "review") { req -> EventLoopFuture<ReviewResponse> in
        let reviewSubmission = try req.content.decode(ReviewRequest.self)
        guard let serviceObjectId = try? BSONObjectID(reviewSubmission.serviceId) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }

        let filter: BSONDocument = ["_id": .objectID(serviceObjectId)]
        let update: BSONDocument = ["$push": ["reviews": .document(try BSONEncoder().encode(reviewSubmission.review))]]

        return req.serviceCollection.updateOne(filter: filter, update: update).flatMapThrowing { updateResult in
        guard let result = updateResult, result.modifiedCount == 1 else {
                throw Abort(.notFound, reason: "Service not found or no update made")
            }
			return ReviewResponse(success: true, message: "Service review updated successfully")
        }
    }

    /// Handles a request to load info about a particular user.
    app.get(":_id") { req async throws -> User in
        try await req.findUser()
    }

    app.delete(":_id") { req async throws -> Response in
        try await req.delUser()
    }

    app.get("api", "user", "login", ":emailOrPhone", ":password") { req async throws -> User in
        try await req.userExists()
    }


    app.post("api", "user", "create") { req async throws -> AddUserResponse in
        let newUser = try req.content.decode(User.self)
        
        // Check for existing user by Apple Identifier
        let filter: BSONDocument = ["_id": .string(newUser.id ?? "")]
        if let existingUser = try await req.userCollection.findOne(filter) {
            // User already exists, return their ID
            return AddUserResponse(id: existingUser.id ?? "Unknown ID")
        } else {
            // Proceed with creating a new user
            try await req.userCollection.insertOne(newUser)
            return AddUserResponse(id: newUser.id ?? "Unknown ID")
        }
    }


    app.patch("api", "user", "update") { req async throws -> UpdateUserResponse in
        try await req.updateUser()
    }

    app.post("api", "fetii", "find") { req async throws -> FindFetiiResponse in
        try await req.findFetii(req: req)
    }

    app.get("api", "fetii", "locate") { req async throws -> LocateFetiiResponse in
        try await req.locateFetii(req: req)
    }
    // Route to grab veoride information
    app.post("api", "veoride", "find") { req async throws -> VEOPriceLocation in
        try await req.findVEO(req: req)
    }

    // Apple Login Stuff
    // Apple Login Stuff
    app.get("api", "user", "apple-login", ":appleIdentifier") { req async throws -> User in
        print("Apple Login Request Received")

        guard let appleIdentifier = req.parameters.get("appleIdentifier", as: String.self) else {
            print("Apple Login: Bad Request - Missing Apple Identifier")
            throw Abort(.badRequest)
        }

        print("Apple Login: Received Apple Identifier - \(appleIdentifier)")


        do {
            // Check if a user with the given Apple Identifier exists
            let user = try await req.findUserByAppleIdentifier(appleIdentifier)

            if let user = user {
                print("Apple Login: User Found - \(user)")
                return user
            } else {
                // If user not found, you can throw a notFound error or handle it as needed
                throw Abort(.notFound, reason: "User not found")
            }
        } catch {
            // Handle errors
            throw error
        }
    }
}

extension User: Content {}
extension Service: Content {}
extension FindFetiiResponse: Content {}
extension LocateFetiiResponse: Content {}
extension AddUserResponse: Content {}
extension UpdateUserResponse: Content {}
extension FindVEOResponse: Content {}
extension VEOBikeResponse: Content {}
extension BikeDistance: Content {}
extension VEOPriceLocation: Content {}

extension Request {
    /// Convenience extension for obtaining a collection.

    var userCollection: MongoCollection<User> {
        self.application.mongoDB.client.db("ridescan").collection("users", withType: User.self)
    }

    var serviceCollection: MongoCollection<Service> {
        self.application.mongoDB.client.db("ridescan").collection("transportation", withType: Service.self)
    }

	/// Constructs a document using the _id from this request which can be used a filter for MongoDB
	/// reads/updates/deletions.
	func getIDFilter(forUserId userId: String) throws -> BSONDocument {
		guard let objectId = try? BSONObjectID(userId) else {
			throw Abort(.badRequest, reason: "Invalid user ID")
		}
		return ["_id": .objectID(objectId)]
	}

	func findUsers() async throws -> [User] {
		do {
			return try await self.userCollection.find().toArray()
		} catch {
			throw Abort(.internalServerError, reason: "Failed to load users: \(error)")
		}
	}

    func findServices(req: Request) async throws -> [Service] {
        do {
            var services = try await self.serviceCollection.find().toArray()
            
            // Loop through each service and call a different function
            for index in services.indices {
                var service = services[index]

                // We can assume that we only need to obtain data for non-user proposed services
                if service.user_proposed == false {

                    // Fetii information
                    if service.name == "Fetii" {
						
                        let findFetiiResponse = try await findFetii(req: req)

                        if findFetiiResponse.no_vehicles_available {
                            services.remove(at: index)
                            break
                        }

                        // set price
                        service.criteria.price = findFetiiResponse.data.first!.min_charge_per_person

                        // set time
                        if let max_time = findFetiiResponse.data.first!.arriveIn_max_time, let min_time = findFetiiResponse.data.first!.arriveIn_min_time {
                          if max_time != 0 && min_time != 0 {
                            service.criteria.time = (max_time + min_time) / 2
                          }
                        }
                        
                    }

                    // set calories burned
                    if service.ride_method == "walking" {
                        service.criteria.calories_burned = service.criteria.time * 5
                    } else if service.ride_method == "biking" {
                        service.criteria.calories_burned = service.criteria.time * 10
                    }

                    services[index] = service
                } else {
					// // Calculate the average rating for user-proposed services
					// let totalRating = service.reviews.reduce(0) { $0 + $1.rating }
					// let averageRating = service.reviews.isEmpty ? 5 : Double(totalRating) / Double(service.reviews.count)

					// // Filter out services with an average rating less than 2
					// if !service.reviews.isEmpty && averageRating >= 2.0 {
					// 	// ... you might want to set other criteria here ...
					// 	services[index] = service
					// } else {
					// 	// Remove the service with an average rating below 2
					// 	services.remove(at: index)
					// }
				}
            }

            return services

        } catch {
            throw Abort(.internalServerError, reason: "Failed to load services: \(error)")
        }
    }
	
	func appleUserExists(appleIdentifier: String) async throws -> Bool {
		let filter: BSONDocument = [
			"_id": .string(appleIdentifier)]
			

		do {
			// Try to find an existing user by Apple Identifier
			return try await self.userCollection.countDocuments(filter) > 0
		} catch {
			throw Abort(.internalServerError, reason: "Failed to check user existence: \(error)")
		}
	}

	func findUserByAppleIdentifier(_ appleIdentifier: String) async throws -> User? {
		print("Searching for User with Apple Identifier: \(appleIdentifier)")
		
		let filter: BSONDocument = [
			"_id": .string(appleIdentifier)
			
		]

		do {
			print("Executing database query...")
			if let user = try await self.userCollection.findOne(filter) {
				print("User found with Apple Identifier: \(appleIdentifier)")
				return user
			} else {
				print("User not found with Apple Identifier: \(appleIdentifier)")
				return nil
			}
		} catch {
			print("Error while searching for user with Apple Identifier: \(appleIdentifier), Error: \(error)")
			throw error
		}
	}

	
	func userExists() async throws -> User {
		guard let emailOrPhone = self.parameters.get("emailOrPhone", as: String.self),
			  let password = self.parameters.get("password", as: String.self) else {
			throw Abort(.badRequest)
		}

		// Use the `$or` operator to match either email or phone
		let filter: BSONDocument = [
			"$or": [
				["email": .string(emailOrPhone)],
				["phone": .string(emailOrPhone)]
			],
			"password": .string(password) // Match the password as well
		]

		// Perfo rm the query to find a user with matching email/phone and password
		guard let user = try await self.userCollection.findOne(filter) else {
			throw Abort(.notFound, reason: "No user with matching credentials")
		}
		return user
	}

	func findUser() async throws -> User {
		let idString = self.parameters.get("_id", as: String.self) ?? ""
		let idFilter = try self.getIDFilter(forUserId: idString)
		guard let user = try await self.userCollection.findOne(idFilter) else {
			throw Abort(.notFound, reason: "No user with matching _id")
		}
		return user
	}

	func addUser() async throws -> AddUserResponse {
		var newUser = try self.content.decode(User.self)

		if let appleId = newUser.id {
			// Check if appleIdentifier is a valid BSONObjectID format
			if let objectId = try? BSONObjectID(appleId) {
				// If it's a valid format, set it as the id
				newUser.id = objectId.hex
			} else {
				throw Abort(.badRequest, reason: "Invalid appleIdentifier format")
			}
		} else {
			// If appleIdentifier is nil, MongoDB will auto-generate the id
		}

		do {
			// Insert the user into MongoDB
			if let insertResult: InsertOneResult = try await self.userCollection.insertOne(newUser) {
				let insertedID = insertResult.insertedID
				let stringID = extractStringInParentheses(string: String(describing: insertedID))
				return AddUserResponse(id: stringID)
			} else {
				throw Abort(.internalServerError, reason: "Inserted ID is not an ObjectId.")
			}
		} catch {
			throw Abort(.internalServerError, reason: "Failed to save new user: \(error)")
		}
	}

	func delUser() async throws -> Response {
		print("Starting user deletion process")

		// Retrieve the user ID from the path parameters
		guard let userId = self.parameters.get("_id", as: String.self) else {
			print("User ID is missing in the request")
			throw Abort(.badRequest, reason: "User ID is missing")
		}
		print("User ID to delete: \(userId)")

		let filter: BSONDocument
		if userId.hasPrefix("ObjectId('") && userId.hasSuffix("')") {
			let startIndex = userId.index(userId.startIndex, offsetBy: 11)
			let endIndex = userId.index(userId.endIndex, offsetBy: -2)
			let objectIdString = String(userId[startIndex..<endIndex])

			if let objectId = try? BSONObjectID(objectIdString) {
				filter = ["_id": .objectID(objectId)]
				print("Using ObjectId filter: \(filter)")
			} else {
				print("Invalid ObjectId format for user ID: \(userId)")
				throw Abort(.badRequest, reason: "Invalid ObjectId format")
			}
		} else {
			filter = ["_id": .string(userId)]
			print("Using string filter: \(filter)")
		}

		do {
			guard let result = try await self.userCollection.deleteOne(filter) else {
				print("Got unexpectedly nil response from database")
				throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
			}
			print("Delete operation result: \(result)")

			guard result.deletedCount == 1 else {
				print("No user found with matching _id: \(userId)")
				throw Abort(.notFound, reason: "No user with matching _id")
			}
			print("User with ID \(userId) deleted successfully")
			return Response(status: .ok, body: .init(string: "User with ID \(userId) deleted successfully"))
		} catch {
			print("Failed to delete user: \(error)")
			throw Abort(.internalServerError, reason: "Failed to delete user: \(error)")
		}
	}





	    func updateUser() async throws -> UpdateUserResponse {
        // Decode the User from the request's JSON body
        let userToUpdate = try self.content.decode(User.self)

        guard let userId = userToUpdate.id else {
          throw Abort(.badRequest, reason: "User ID is missing")
        }

        do {
          // Create a filter based on the _id format
          let filter: BSONDocument
          if userId.hasPrefix("ObjectId('") && userId.hasSuffix("')") {
            // If the userId is in ObjectId format, extract the ObjectId value
            let startIndex = userId.index(userId.startIndex, offsetBy: 11)
            let endIndex = userId.index(userId.endIndex, offsetBy: -2)
            let objectIdString = String(userId[startIndex..<endIndex])
            if let objectId = try? BSONObjectID(objectIdString) {
              filter = ["_id": .objectID(objectId)]
            } else {
              throw Abort(.badRequest, reason: "Invalid ObjectId format")
            }
          } else {
            // If the userId is not in ObjectId format, treat it as a string
            filter = ["_id": .string(userId)]
          }

          // Create an update document with the fields you want to update
          let updateDocument: BSONDocument = [
            "$set": .document(try BSONEncoder().encode(userToUpdate))
          ]

          // Update the user in MongoDB
          let result = try await self.userCollection.updateOne(filter: filter, update: updateDocument)

          // Check if a document was actually updated
          guard let matchedCount = result?.matchedCount, matchedCount > 0 else {
            throw Abort(.notFound, reason: "No user with matching _id")
          }

          // You can create a custom response or return a success message
          // For simplicity, let's just return a success message with the updated user's ID
          return UpdateUserResponse(id: userId, message: "User updated successfully")
        } catch {
          // If something goes wrong, throw an internal server error
          throw Abort(.internalServerError, reason: "Failed to update user: \(error)")
        }
	  }


	  func extractStringInParentheses(string: String) -> String {
        let startIndex = string.firstIndex(of: "(")
        let endIndex = string.firstIndex(of: ")")

        let extractionStart = string.index(after: startIndex!)
        return String(string[extractionStart..<endIndex!])
	  }

    func findFetii(req: Request) async throws -> FindFetiiResponse {

        let locationInfo = try req.query.decode(LocationInformation.self)
        
        let baseURL = "https://www.fetii.com/api/v29/vehicle-types-list"

        guard var urlComponents = URLComponents(string: baseURL) else {
          throw Abort(.internalServerError, reason: "Invalid URL")
        }

        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "pickup_latitude", value: "\(locationInfo.userLatitude)"),
            URLQueryItem(name: "pickup_longitude", value: "\(locationInfo.userLongitude)"),
            URLQueryItem(name: "dropoff_latitude", value: "\(locationInfo.destLatitude)"),
            URLQueryItem(name: "dropoff_longitude", value: "\(locationInfo.destLongitude)"),
            URLQueryItem(name: "dropoff_long_address", value: "\(locationInfo.dropoff_long_address)"),
            URLQueryItem(name: "dropoff_short_address", value: "\(locationInfo.dropoff_short_address)"),
            URLQueryItem(name: "pickup_long_address", value: "\(locationInfo.pickup_long_address)"),
            URLQueryItem(name: "pickup_short_address", value: "\(locationInfo.pickup_short_address)"),
            URLQueryItem(name: "radius_id", value: "1"),
            URLQueryItem(name: "ride_type", value: "normal")
        ]

         guard let url = urlComponents.url else {
            throw Abort(.internalServerError, reason: "Failed to compose url with parameters")
        }

        // Convert URL to URI
        let uri = URI(string: url.absoluteString)

        // Use Vapor's HTTP client
        let clientResponse = try await req.client.get(uri) { getReq in
            // Set the Authorization header
            getReq.headers.bearerAuthorization = BearerAuthorization(token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImNlNjA5MDY2ZDZjZTc3OTkyZDgxYjZhZDEwNWQyZDBkN2Q0NGQ1MjIxNDQyMTU1NThlZTc2ZmVmMTJjYjQwMzcwOTIzODNlOWIxMWM4MTI1In0.eyJhdWQiOiIzIiwianRpIjoiY2U2MDkwNjZkNmNlNzc5OTJkODFiNmFkMTA1ZDJkMGQ3ZDQ0ZDUyMjE0NDIxNTU1OGVlNzZmZWYxMmNiNDAzNzA5MjM4M2U5YjExYzgxMjUiLCJpYXQiOjE2OTQ3Mzg5MzYsIm5iZiI6MTY5NDczODkzNiwiZXhwIjoxNzI2MzYxMzM2LCJzdWIiOiIxOTY0NjIiLCJzY29wZXMiOltdfQ.cfLhUNZr95dy_QxDAb82AXvE2XtgVqwrQK0EOg_Uaa3NgiMqDV-F0z14ecSXWkm9ALYobzmZqpp68uXzoEsIsQW6yNrqcCYulrIBGFy0tZtObuaeOpmzKV8rEqq2lXWxzxFDpvNd678QIOH2LIpE_Gr1VlrAWGeA6rj9JV6boAaqfpPpDddeT-ThbXecNehsSyUeS_lbmkKSzFMjbeFiX6WP4TbR7ozeJokv47GHJkhJyZoQodpoWPlOCFmy9U7l1JHH4PvQxmvrdYscetPp-d_bQgNn59W9QN-EZUaiSQ5E-mUsTp6ZP320vgG5eOKpTgvANjiUd9bZ17eyQ8160LzDOmnDdynBvjBYLUmIJaRQ2xVnR5TL7XsFkdak0xfIYYWQNpIM4cEsvXyey9Hya7yRf06ZdIDeWnxT5YcIi4PDOMU8JQ38RLRSDCNUTS1x5_qQvcPGuirIbPStNlnIPfoNdAg_GpKuBH931LpzEtD7I6AX-p8DtIuXx1CkKHHTkbviK0CSgkLM2mxVPpCNMGxP5rUVIDL3KRzUvYqyGjFJilWX4fL8Fv5rXWXF8F5T0YWbWLAO5TEn6IMqawaFzzAjAcQnopbG1Tiq9gBF0ZPZCmoOgS54af2IBW_XC9NQyDFqNp_wV_XgKH9GD89ANXElaedhmB5yDtnwGQ0oWW0")
        }

        guard clientResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        // Decode the response
        let decodedData = try clientResponse.content.decode(FindFetiiResponse.self)
        return decodedData
	  }

	  func locateFetii(req: Request) async throws -> LocateFetiiResponse {

		    let locationInfo = try req.query.decode(LocationInformation.self)

        // Replace with your endpoint
        let baseURL = "https://www.fetii.com/api/v29/nearest-drivers-list"

        guard var urlComponents = URLComponents(string: baseURL) else {
          throw Abort(.internalServerError, reason: "Invalid URL")
        }

        // Add query parameters
        urlComponents.queryItems = [
          URLQueryItem(name: "latitude", value: "\(locationInfo.userLatitude)"),
          URLQueryItem(name: "longitude", value: "\(locationInfo.userLongitude)"),
          URLQueryItem(name: "radius_id", value: "1")
        ]

        guard let url = urlComponents.url else {
          throw Abort(.internalServerError, reason: "Failed to compose url with parameters")
        }

        // Convert URL to URI
        let uri = URI(string: url.absoluteString)

        // Use Vapor's HTTP client
        let clientResponse = try await req.client.get(uri) { getReq in
            // Set the Authorization header
            getReq.headers.bearerAuthorization = BearerAuthorization(token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImNlNjA5MDY2ZDZjZTc3OTkyZDgxYjZhZDEwNWQyZDBkN2Q0NGQ1MjIxNDQyMTU1NThlZTc2ZmVmMTJjYjQwMzcwOTIzODNlOWIxMWM4MTI1In0.eyJhdWQiOiIzIiwianRpIjoiY2U2MDkwNjZkNmNlNzc5OTJkODFiNmFkMTA1ZDJkMGQ3ZDQ0ZDUyMjE0NDIxNTU1OGVlNzZmZWYxMmNiNDAzNzA5MjM4M2U5YjExYzgxMjUiLCJpYXQiOjE2OTQ3Mzg5MzYsIm5iZiI6MTY5NDczODkzNiwiZXhwIjoxNzI2MzYxMzM2LCJzdWIiOiIxOTY0NjIiLCJzY29wZXMiOltdfQ.cfLhUNZr95dy_QxDAb82AXvE2XtgVqwrQK0EOg_Uaa3NgiMqDV-F0z14ecSXWkm9ALYobzmZqpp68uXzoEsIsQW6yNrqcCYulrIBGFy0tZtObuaeOpmzKV8rEqq2lXWxzxFDpvNd678QIOH2LIpE_Gr1VlrAWGeA6rj9JV6boAaqfpPpDddeT-ThbXecNehsSyUeS_lbmkKSzFMjbeFiX6WP4TbR7ozeJokv47GHJkhJyZoQodpoWPlOCFmy9U7l1JHH4PvQxmvrdYscetPp-d_bQgNn59W9QN-EZUaiSQ5E-mUsTp6ZP320vgG5eOKpTgvANjiUd9bZ17eyQ8160LzDOmnDdynBvjBYLUmIJaRQ2xVnR5TL7XsFkdak0xfIYYWQNpIM4cEsvXyey9Hya7yRf06ZdIDeWnxT5YcIi4PDOMU8JQ38RLRSDCNUTS1x5_qQvcPGuirIbPStNlnIPfoNdAg_GpKuBH931LpzEtD7I6AX-p8DtIuXx1CkKHHTkbviK0CSgkLM2mxVPpCNMGxP5rUVIDL3KRzUvYqyGjFJilWX4fL8Fv5rXWXF8F5T0YWbWLAO5TEn6IMqawaFzzAjAcQnopbG1Tiq9gBF0ZPZCmoOgS54af2IBW_XC9NQyDFqNp_wV_XgKH9GD89ANXElaedhmB5yDtnwGQ0oWW0")
        }

        guard clientResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        // Decode the response
        let decodedData = try clientResponse.content.decode(LocateFetiiResponse.self)
        return decodedData
	  }
    
    func findDistance(userLat: Double, userLng: Double, bikeLat: Double, bikeLng: Double) -> Double {
        let xDist = userLat - bikeLat
        let yDist = userLng - bikeLng
        let sumSquares = (xDist * xDist) + (yDist * yDist)
        return sqrt(sumSquares)
    }

    func findVEO(req: Request) async throws -> VEOPriceLocation {
        
        let findVEO = try req.content.decode(FindVEORequest.self)

        // Construct the base URL for the first request
        let baseURL = "https://cluster-prod.veoride.com/api/customers/vehicles"
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw Abort(.internalServerError, reason: "Invalid URL")
        }

        // Add query parameters for the first request
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: findVEO.userLatitude),
            URLQueryItem(name: "lng", value: findVEO.userLongitude)
        ]

        guard let url = urlComponents.url else {
            throw Abort(.internalServerError, reason: "Failed to compose URL with parameters")
        }

        let uri = URI(string: url.absoluteString)

        // Make the first request
        let clientResponse = try await req.client.get(uri) { getReq in
            getReq.headers.bearerAuthorization = BearerAuthorization(token: "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxOjc1MjYiLCJpYXQiOjE3MDE3NjQ1NzUsImV4cCI6MTcwOTU0MDU3NX0.7-2ykZIgAnWfE9SeHqXyc-thw3PB0ig0zPAPiL96oivN_pyo2sYzESnuXbOfV2THFXvjUp1NsXfyujOyLK_oLw")
        }

        guard clientResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        let decodedData = try clientResponse.content.decode(FindVEOResponse.self)

        do {
            if decodedData.msg == "Request Success" {
                // sort bikes by distance to user
                var bikeLocations = [BikeDistance]()
                let userLat = Double(findVEO.userLatitude)!
                let userLng = Double(findVEO.userLongitude)!
                
                for bike in decodedData.data {
                    let bikeLat = bike.location.lat
                    let bikeLng = bike.location.lng
                    let bikeDist = findDistance(userLat: userLat, userLng: userLng, bikeLat: bikeLat, bikeLng: bikeLng)
                                        
                    let bikeLocation = BikeDistance(lat: bikeLat, lng: bikeLng, distance: bikeDist)
                    bikeLocations.append(bikeLocation)
                }
                
                bikeLocations = bikeLocations.sorted(by:{$0.distance < $1.distance})
                
                // after sorting bikes, make request for closest bike
                let bikeURL = "https://cluster-prod.veoride.com/api/customers/vehicles/number/\(decodedData.data.first!.vehicleNumber)"
                let bikeUri = URI(string: bikeURL)

                // Make the second request
                let bikeClientResponse = try await req.client.get(bikeUri) { getReq in
                    getReq.headers.bearerAuthorization = BearerAuthorization(token: "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxOjc1MjYiLCJpYXQiOjE3MDE3NjQ1NzUsImV4cCI6MTcwOTU0MDU3NX0.7-2ykZIgAnWfE9SeHqXyc-thw3PB0ig0zPAPiL96oivN_pyo2sYzESnuXbOfV2THFXvjUp1NsXfyujOyLK_oLw")
                }

                guard bikeClientResponse.status == .ok else {
                    throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
                }

                let bikeData = try bikeClientResponse.content.decode(VEOBikeResponse.self)

                // Assuming you process this response to create your final data
                let finalData = VEOPriceLocation(price: bikeData.data.price, closestBikes: bikeLocations)

                return finalData

            } else {
                throw Abort(.notFound, reason: "No bikes found")
            }
        } catch {
            throw Abort(.internalServerError, reason: "Error decoding JSON: \(error)")
        }
    }
}

// Define a structure that matches the expected query parameters
struct LocationInformation: Content {
    var userLatitude: String
    var userLongitude: String
    var pickup_long_address: String
    var pickup_short_address: String
    var destLatitude: String
    var destLongitude: String
    var dropoff_long_address: String
    var dropoff_short_address: String
}
