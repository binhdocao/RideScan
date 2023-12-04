import App
import MongoDBVapor
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
try configure(app)

// Configure the app for using a MongoDB server at the provided connection string.
try app.mongoDB.configure(Environment.get("MONGODB_URI") ?? "mongodb://localhost:27017")

app.http.server.configuration.hostname = "0.0.0.0" // allow connections from any IP
app.http.server.configuration.port = 8081  // backend running on port 8080 on linux server, so development application binds to 8081 instead 

defer {
    // Cleanup the application's MongoDB data.
    app.mongoDB.cleanup()
    // Clean up the driver's global state. The driver will no longer be usable from this program after this method is
    // called.
    cleanupMongoSwift()
    app.shutdown()
}

try app.run()
