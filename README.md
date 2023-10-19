# Full-Stack Swift Example

This directory contains some basic swift code constructed from a kittens template project (hence all of the kittens files) via typical CRUD operations. The backend server is written using Vapor and the MongoDB Swift driver, which lives in the [Backend](./Backend) directory. The frontend is an iOS application as defined in [iOSApp](./iOSApp), which communicates with the backend via HTTP. 

The same `Codable` data model types are shared between the frontend and backend, and so they are defined in their own `Models` SwiftPM package.

For more details on each component, please review the corresponding README files: [backend](./Backend/README.md), [frontend](./iOSApp/README.md), [models](./Models/README.md).

## Building and Running the Application

### 1. Navigate to the Backend directory
```
cd ~/path/to/backend/Backend
```
### 2. Set the MONGODB_URI environment variable
```
source ./mongo_uri.sh
``` 
### 3. Run the backend server 
```
swift run
``` 
### Open the xcode project
Navigate to the iOSApp directory and open the xcode project by clicking on the `Ridescan.xcodeproj` file.

### Run the iOS application
You should see the prepopulated user with first name Jane and email Jane@abc.com


