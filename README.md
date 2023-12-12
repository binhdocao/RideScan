# RideScan

This directory contains the RideScan iOS, Backend, and Web code. The backend server is written using Vapor and the MongoDB Swift driver, which lives in the [Backend](./Backend) directory. The frontend is an iOS application as defined in [iOSApp](./iOSApp), which communicates with the backend via HTTP. 

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
