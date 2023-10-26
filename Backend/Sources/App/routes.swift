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
}

/// Extend the `Kitten` model type to conform to Vapor's `Content` protocol so that it may be converted to and
/// initialized from HTTP data.
extension Kitten: Content {}
extension User: Content {}

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
        print(newUser)
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
}
