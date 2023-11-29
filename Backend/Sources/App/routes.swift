import Models
import MongoDBVapor
import Vapor

// Adds API routes to the application.
func routes(_ app: Application) throws {
    /// Handles a request to load the list of kittens.
    app.get { req async throws -> [User] in
        try await req.findUsers()
    }

    /// Handles a request to load info about a particular kitten.
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
        try await req.findFetii()
    }

    app.post("api", "fetii", "locate") { req async throws -> LocateFetiiResponse in
        try await req.locateFetii()
    }

    app.post("api", "veoride", "find") { req async throws -> VEOPriceLocation in
        try await req.findVEO()
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

    func findFetii() async throws -> FindFetiiResponse {

        let findFetii = try self.content.decode(FindFetiiRequest.self)
        print(findFetii)

        // Replace with your endpoint
        let baseURL = "https://www.fetii.com/api/v29/vehicle-types-list"

        guard var urlComponents = URLComponents(string: baseURL) else {
            throw Abort(.internalServerError, reason: "Invalid URL")
        }

        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "pickup_latitude", value: "\(findFetii.userLatitude)"),
            URLQueryItem(name: "pickup_longitude", value: "\(findFetii.userLongitude)"),
            URLQueryItem(name: "dropoff_latitude", value: "\(findFetii.destLatitude)"),
            URLQueryItem(name: "dropoff_longitude", value: "\(findFetii.destLongitude)"),
            URLQueryItem(name: "dropoff_long_address", value: "\(findFetii.dropoff_long_address)"),
            URLQueryItem(name: "dropoff_short_address", value: "\(findFetii.dropoff_short_address)"),
            URLQueryItem(name: "pickup_long_address", value: "\(findFetii.pickup_long_address)"),
            URLQueryItem(name: "pickup_short_address", value: "\(findFetii.pickup_short_address)"),
            URLQueryItem(name: "radius_id", value: "1"),
            URLQueryItem(name: "ride_type", value: "normal")
        ]

        guard let url = urlComponents.url else {
            throw Abort(.internalServerError, reason: "Failed to compose url with parameters")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Replace with your bearer token
        request.addValue("Bearer <#YourBearerToken#>", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        do {
            let decodedData = try JSONDecoder().decode(FindFetiiResponse.self, from: data)
            print(decodedData)
            if decodedData.status == 200 {
                return decodedData
            } else {
                throw Abort(.notFound, reason: "No drivers found")
            }
        } catch {
            throw Abort(.internalServerError, reason: "Error decoding JSON: \(error)")
        }
    }

    func locateFetii() async throws -> LocateFetiiResponse {

        // Replace with your endpoint
        let baseURL = "https://www.fetii.com/api/v29/nearest-drivers-list"
        let userLocation = try self.content.decode(UserLoc.self)

        guard var urlComponents = URLComponents(string: baseURL) else {
            throw Abort(.internalServerError, reason: "Invalid URL")
        }

        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(userLocation.lat)"),
            URLQueryItem(name: "longitude", value: "\(userLocation.lng)"),
            URLQueryItem(name: "radius_id", value: "1")
        ]

        guard let url = urlComponents.url else {
            throw Abort(.internalServerError, reason: "Failed to compose url with parameters")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Replace with your bearer token
        request.addValue("Bearer <#YourBearerToken#>", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        do {
            let decodedData = try JSONDecoder().decode(LocateFetiiResponse.self, from: data)
            print(decodedData)
            if decodedData.status == 200 {
                return decodedData
            } else {
                throw Abort(.notFound, reason: "No drivers found")
            }
        } catch {
            throw Abort(.internalServerError, reason: "Error decoding JSON: \(error)")
        }
    }
    
    func findDistance(userLat: Double, userLng: Double, bikeLat: Double, bikeLng: Double) -> Double {
        let xDist = userLat - bikeLat
        let yDist = userLng - bikeLng
        let sumSquares = (xDist * xDist) + (yDist * yDist)
        return sqrt(sumSquares)
    }

    func findVEO() async throws -> VEOPriceLocation {
        
        let findVEO = try self.content.decode(FindVEORequest.self)
        print(findVEO)

        let baseURL = URL(string: "https://cluster-prod.veoride.com/api/customers/vehicles?lat=\(findVEO.userLatitude)&lng=\(findVEO.userLongitude)")!
 
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"

        // Replace with your bearer token
        request.addValue("Bearer \(findVEO.veoToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
        }

        do {
            let decodedData = try JSONDecoder().decode(FindVEOResponse.self, from: data)
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
                let bikeURL = URL(string: "https://cluster-prod.veoride.com/api/customers/vehicles/number/\(decodedData.data.first!.vehicleNumber)")!
 
                var bike_request = URLRequest(url: bikeURL)
                bike_request.httpMethod = "GET"

                // Replace with your bearer token
                bike_request.addValue("Bearer \(findVEO.veoToken)", forHTTPHeaderField: "Authorization")

                let (data2, response2) = try await URLSession.shared.data(for: bike_request)
                guard let httpResponse = response2 as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        throw Abort(.internalServerError, reason: "Failed to get a valid response from the server")
                    }
                
                do {
                   let bikeData = try JSONDecoder().decode(VEOBikeResponse.self, from: data2)
                   if bikeData.msg == "Request Success" {
                       let finalData = VEOPriceLocation(price: bikeData.data.price, closestBikes: bikeLocations)
                       return finalData
                   } else {
                            throw Abort(.notFound, reason: "No bikes found")
                   }
                   } catch {
                        throw Abort(.internalServerError, reason: "Error decoding JSON: \(error)")
                }

            } else {
                throw Abort(.notFound, reason: "No bikes found")
            }
        } catch {
            throw Abort(.internalServerError, reason: "Error decoding JSON: \(error)")
        }
    }
}
