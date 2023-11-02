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

    app.get("api", "user", "login", ":emailOrPhone", ":password") { req async throws -> User in
        try await req.userExists()
    }

    app.post("api", "user", "create") { req async throws -> AddUserResponse in
        try await req.addUser()
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
}

/// Extend the `Kitten` model type to conform to Vapor's `Content` protocol so that it may be converted to and
/// initialized from HTTP data.
extension User: Content {}
extension FindFetiiResponse: Content {}
extension LocateFetiiResponse: Content {}
extension AddUserResponse: Content {}
extension UpdateUserResponse: Content {}

extension Request {
    /// Convenience extension for obtaining a collection.

    var userCollection: MongoCollection<User> {
        self.application.mongoDB.client.db("ridescan").collection("users", withType: User.self)
    }

    /// Constructs a document using the _id from this request which can be used a filter for MongoDB
    /// reads/updates/deletions.
    func getIDFilter() throws -> BSONDocument {
        // We only call this method from request handlers that have _id parameters so the value
        // should always be available.
        guard let idString = self.parameters.get("_id", as: String.self) else {
            throw Abort(.badRequest, reason: "Request missing _id for user")
        }
        guard let _id = try? BSONObjectID(idString) else {
            throw Abort(.badRequest, reason: "Invalid _id string \(idString)")
        }
        return ["_id": .objectID(_id)]
    }

    func findUsers() async throws -> [User] {
        do {
            return try await self.userCollection.find().toArray()
        } catch {
            throw Abort(.internalServerError, reason: "Failed to load users: \(error)")
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

        // Perform the query to find a user with matching email/phone and password
        guard let user = try await self.userCollection.findOne(filter) else {
            throw Abort(.notFound, reason: "No user with matching credentials")
        }
        return user
    }

    func findUser() async throws -> User {
        let idFilter = try self.getIDFilter()
        guard let user = try await self.userCollection.findOne(idFilter) else {
            throw Abort(.notFound, reason: "No user with matching _id")
        }
        return user
    }

    func addUser() async throws -> AddUserResponse {
        let userToInsert = try self.content.decode(User.self)
        do {
            // Insert the user into MongoDB
            if let insertResult: InsertOneResult = try await self.userCollection.insertOne(userToInsert) {
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

    func updateUser() async throws -> UpdateUserResponse {
        // Decode the User from the request's JSON body
        let userToUpdate = try self.content.decode(User.self)

        print(userToUpdate.id)

        // Create a filter to find the document with the matching _id
        let filter: BSONDocument = ["_id": .objectID(userToUpdate.id)]
        
        // Create an update document with the fields you want to update
        let updateDocument: BSONDocument = [
            "$set": .document(try BSONEncoder().encode(userToUpdate))
        ]
        
        do {
            // Update the user in MongoDB
            let result = try await self.userCollection.updateOne(filter: filter, update: updateDocument)
            
            // Check if a document was actually updated
            guard let matchedCount = result?.matchedCount, matchedCount > 0 else {
                throw Abort(.notFound, reason: "No user with matching _id")
            }
            
            // You can create a custom response or return a success message
            // For simplicity, let's just return a success message with the updated user's ID
            return UpdateUserResponse(id: userToUpdate.id, message: "User updated successfully")
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
        request.addValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImNlNjA5MDY2ZDZjZTc3OTkyZDgxYjZhZDEwNWQyZDBkN2Q0NGQ1MjIxNDQyMTU1NThlZTc2ZmVmMTJjYjQwMzcwOTIzODNlOWIxMWM4MTI1In0.eyJhdWQiOiIzIiwianRpIjoiY2U2MDkwNjZkNmNlNzc5OTJkODFiNmFkMTA1ZDJkMGQ3ZDQ0ZDUyMjE0NDIxNTU1OGVlNzZmZWYxMmNiNDAzNzA5MjM4M2U5YjExYzgxMjUiLCJpYXQiOjE2OTQ3Mzg5MzYsIm5iZiI6MTY5NDczODkzNiwiZXhwIjoxNzI2MzYxMzM2LCJzdWIiOiIxOTY0NjIiLCJzY29wZXMiOltdfQ.cfLhUNZr95dy_QxDAb82AXvE2XtgVqwrQK0EOg_Uaa3NgiMqDV-F0z14ecSXWkm9ALYobzmZqpp68uXzoEsIsQW6yNrqcCYulrIBGFy0tZtObuaeOpmzKV8rEqq2lXWxzxFDpvNd678QIOH2LIpE_Gr1VlrAWGeA6rj9JV6boAaqfpPpDddeT-ThbXecNehsSyUeS_lbmkKSzFMjbeFiX6WP4TbR7ozeJokv47GHJkhJyZoQodpoWPlOCFmy9U7l1JHH4PvQxmvrdYscetPp-d_bQgNn59W9QN-EZUaiSQ5E-mUsTp6ZP320vgG5eOKpTgvANjiUd9bZ17eyQ8160LzDOmnDdynBvjBYLUmIJaRQ2xVnR5TL7XsFkdak0xfIYYWQNpIM4cEsvXyey9Hya7yRf06ZdIDeWnxT5YcIi4PDOMU8JQ38RLRSDCNUTS1x5_qQvcPGuirIbPStNlnIPfoNdAg_GpKuBH931LpzEtD7I6AX-p8DtIuXx1CkKHHTkbviK0CSgkLM2mxVPpCNMGxP5rUVIDL3KRzUvYqyGjFJilWX4fL8Fv5rXWXF8F5T0YWbWLAO5TEn6IMqawaFzzAjAcQnopbG1Tiq9gBF0ZPZCmoOgS54af2IBW_XC9NQyDFqNp_wV_XgKH9GD89ANXElaedhmB5yDtnwGQ0oWW0", forHTTPHeaderField: "Authorization")

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
        request.addValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImNlNjA5MDY2ZDZjZTc3OTkyZDgxYjZhZDEwNWQyZDBkN2Q0NGQ1MjIxNDQyMTU1NThlZTc2ZmVmMTJjYjQwMzcwOTIzODNlOWIxMWM4MTI1In0.eyJhdWQiOiIzIiwianRpIjoiY2U2MDkwNjZkNmNlNzc5OTJkODFiNmFkMTA1ZDJkMGQ3ZDQ0ZDUyMjE0NDIxNTU1OGVlNzZmZWYxMmNiNDAzNzA5MjM4M2U5YjExYzgxMjUiLCJpYXQiOjE2OTQ3Mzg5MzYsIm5iZiI6MTY5NDczODkzNiwiZXhwIjoxNzI2MzYxMzM2LCJzdWIiOiIxOTY0NjIiLCJzY29wZXMiOltdfQ.cfLhUNZr95dy_QxDAb82AXvE2XtgVqwrQK0EOg_Uaa3NgiMqDV-F0z14ecSXWkm9ALYobzmZqpp68uXzoEsIsQW6yNrqcCYulrIBGFy0tZtObuaeOpmzKV8rEqq2lXWxzxFDpvNd678QIOH2LIpE_Gr1VlrAWGeA6rj9JV6boAaqfpPpDddeT-ThbXecNehsSyUeS_lbmkKSzFMjbeFiX6WP4TbR7ozeJokv47GHJkhJyZoQodpoWPlOCFmy9U7l1JHH4PvQxmvrdYscetPp-d_bQgNn59W9QN-EZUaiSQ5E-mUsTp6ZP320vgG5eOKpTgvANjiUd9bZ17eyQ8160LzDOmnDdynBvjBYLUmIJaRQ2xVnR5TL7XsFkdak0xfIYYWQNpIM4cEsvXyey9Hya7yRf06ZdIDeWnxT5YcIi4PDOMU8JQ38RLRSDCNUTS1x5_qQvcPGuirIbPStNlnIPfoNdAg_GpKuBH931LpzEtD7I6AX-p8DtIuXx1CkKHHTkbviK0CSgkLM2mxVPpCNMGxP5rUVIDL3KRzUvYqyGjFJilWX4fL8Fv5rXWXF8F5T0YWbWLAO5TEn6IMqawaFzzAjAcQnopbG1Tiq9gBF0ZPZCmoOgS54af2IBW_XC9NQyDFqNp_wV_XgKH9GD89ANXElaedhmB5yDtnwGQ0oWW0", forHTTPHeaderField: "Authorization")

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
}
