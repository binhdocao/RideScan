import Models
import MongoDBVapor
import Vapor

// Adds API routes to the application.
func routes(_ app: Application) throws {
    /// Handles a request to load the list of kittens.
    app.get { req async throws -> [User] in
        try await req.findUsers()
    }

    /// Handles a request to add a new kitten.
    app.post { req async throws -> Response in
        try await req.addKitten()
    }

    /// Handles a request to load info about a particular kitten.
    app.get(":_id") { req async throws -> User in
        try await req.findUser()
    }

    app.delete(":_id") { req async throws -> Response in
        try await req.deleteKitten()
    }

    app.patch(":_id") { req async throws -> Response in
        try await req.updateKitten()
    }

    app.get("api", "user", "login", ":emailOrPhone", ":password") { req async throws -> User in
        try await req.userExists()
    }

    app.post("api", "user", "create") { req async throws -> Response in
        try await req.addUser()
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
extension Kitten: Content {}
extension User: Content {}
extension FindFetiiResponse: Content {}
extension LocateFetiiResponse: Content {}

extension Request {
    /// Convenience extension for obtaining a collection.
    var kittenCollection: MongoCollection<Kitten> {
        self.application.mongoDB.client.db("home").collection("kittens", withType: Kitten.self)
    }

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

    func findKitten() async throws -> Kitten {
        let idFilter = try self.getIDFilter()
        guard let kitten = try await self.kittenCollection.findOne(idFilter) else {
            throw Abort(.notFound, reason: "No kitten with matching _id")
        }
        return kitten
    }

    func findUser() async throws -> User {
        let idFilter = try self.getIDFilter()
        guard let user = try await self.userCollection.findOne(idFilter) else {
            throw Abort(.notFound, reason: "No user with matching _id")
        }
        return user
    }

    func addKitten() async throws -> Response {
        let newKitten = try self.content.decode(Kitten.self)
        do {
            try await self.kittenCollection.insertOne(newKitten)
            return Response(status: .created)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to save new kitten: \(error)")
        }
    }

    func addUser() async throws -> Response {
        let newUser = try self.content.decode(User.self)
        do {
            try await self.userCollection.insertOne(newUser)
            return Response(status: .created)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to save new user: \(error)")
        }
    }

    func deleteKitten() async throws -> Response {
        let idFilter = try self.getIDFilter()
        do {
            // since we aren't using an unacknowledged write concern we can expect deleteOne to return a non-nil result.
            guard let result = try await self.kittenCollection.deleteOne(idFilter) else {
                throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
            }
            guard result.deletedCount == 1 else {
                throw Abort(.notFound, reason: "No kitten with matching _id")
            }
            return Response(status: .ok)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to delete kitten: \(error)")
        }
    }

    func updateKitten() async throws -> Response {
        let idFilter = try self.getIDFilter()
        // Parse the update data from the request.
        let update = try self.content.decode(KittenUpdate.self)
        /// Create a document using MongoDB update syntax that specifies we want to set a field.
        let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]

        do {
            // since we aren't using an unacknowledged write concern we can expect updateOne to return a non-nil result.
            guard let result = try await self.kittenCollection.updateOne(
                filter: idFilter,
                update: updateDocument
            ) else {
                throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
            }
            guard result.matchedCount == 1 else {
                throw Abort(.notFound, reason: "No kitten with matching _id")
            }
            return Response(status: .ok)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to update kitten: \(error)")
        }
    }

    func findFetii() async throws -> FindFetiiResponse {
        
        let findFetii = try self.content.decode(FindFetiiRequest.self)
        print(findFetii)

        // Replace with your endpoint
        let baseURL = "https://www.fetii.com/api/v29/vehicle-types-list"
        var responseData = "No response data"

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
