//
//  FetiiDriversView.swift
//  test
//
//  Created by Gage Broberg on 9/18/23.
//

import SwiftUI

struct FetiiDriversView: View {
    // State to hold the fetched data or error message
    @State private var responseData: String = "Fetching data..."

    // Placeholder values, replace with actual data or use as bindings
    @State private var fetchedLatitude: Double = 30.6
    @State private var fetchedLongitude: Double = -96.3
    @State private var radius_id: Int = 1
    
    // Handles navigation if successful request from fetii
    @State private var show_map: Bool = false

    var body: some View {
        VStack {
            Text(responseData)
                .padding()
        }
        .padding()
        .onAppear(perform: fetchData)
        
        // Invisible NavigationLink for programmatic navigation
        NavigationLink(destination: MapView(latitude: fetchedLatitude, longitude: fetchedLongitude), isActive: $show_map) {
            EmptyView()
        }

    }

    func fetchData() {
        
        // Replace with your endpoint
        let baseURL = "https://www.fetii.com/api/v29/nearest-drivers-list"

        guard var urlComponents = URLComponents(string: baseURL) else {
            responseData = "Invalid URL"
            return
        }

        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(fetchedLatitude)"),
            URLQueryItem(name: "longitude", value: "\(fetchedLongitude)"),
            URLQueryItem(name: "radius_id", value: "\(radius_id)")
        ]

        guard let url = urlComponents.url else {
            responseData = "Failed to compose URL with parameters"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Replace with your bearer token
        request.addValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImNlNjA5MDY2ZDZjZTc3OTkyZDgxYjZhZDEwNWQyZDBkN2Q0NGQ1MjIxNDQyMTU1NThlZTc2ZmVmMTJjYjQwMzcwOTIzODNlOWIxMWM4MTI1In0.eyJhdWQiOiIzIiwianRpIjoiY2U2MDkwNjZkNmNlNzc5OTJkODFiNmFkMTA1ZDJkMGQ3ZDQ0ZDUyMjE0NDIxNTU1OGVlNzZmZWYxMmNiNDAzNzA5MjM4M2U5YjExYzgxMjUiLCJpYXQiOjE2OTQ3Mzg5MzYsIm5iZiI6MTY5NDczODkzNiwiZXhwIjoxNzI2MzYxMzM2LCJzdWIiOiIxOTY0NjIiLCJzY29wZXMiOltdfQ.cfLhUNZr95dy_QxDAb82AXvE2XtgVqwrQK0EOg_Uaa3NgiMqDV-F0z14ecSXWkm9ALYobzmZqpp68uXzoEsIsQW6yNrqcCYulrIBGFy0tZtObuaeOpmzKV8rEqq2lXWxzxFDpvNd678QIOH2LIpE_Gr1VlrAWGeA6rj9JV6boAaqfpPpDddeT-ThbXecNehsSyUeS_lbmkKSzFMjbeFiX6WP4TbR7ozeJokv47GHJkhJyZoQodpoWPlOCFmy9U7l1JHH4PvQxmvrdYscetPp-d_bQgNn59W9QN-EZUaiSQ5E-mUsTp6ZP320vgG5eOKpTgvANjiUd9bZ17eyQ8160LzDOmnDdynBvjBYLUmIJaRQ2xVnR5TL7XsFkdak0xfIYYWQNpIM4cEsvXyey9Hya7yRf06ZdIDeWnxT5YcIi4PDOMU8JQ38RLRSDCNUTS1x5_qQvcPGuirIbPStNlnIPfoNdAg_GpKuBH931LpzEtD7I6AX-p8DtIuXx1CkKHHTkbviK0CSgkLM2mxVPpCNMGxP5rUVIDL3KRzUvYqyGjFJilWX4fL8Fv5rXWXF8F5T0YWbWLAO5TEn6IMqawaFzzAjAcQnopbG1Tiq9gBF0ZPZCmoOgS54af2IBW_XC9NQyDFqNp_wV_XgKH9GD89ANXElaedhmB5yDtnwGQ0oWW0", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    responseData = "Error: \(error.localizedDescription)"
                    return
                }

                if let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    do {
                        let decodedData = try JSONDecoder().decode(APIResponse.self, from: data)
                        print(decodedData)
                        if let firstDriver = decodedData.data.first {
                            
                            // Set lat and long
                            fetchedLatitude = firstDriver.lat
                            fetchedLongitude = firstDriver.lng
                            
                            // Trigger navigation
                            show_map = true
                        } else {
                            // No drivers found in response
                            responseData = "It's 11am, there aren't any parties. Spoofing driver data..."
                            
                            // Delay for 3 seconds and then navigate to MapView
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                show_map = true
                            }
                            
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }
        }
        task.resume()
    }
}

struct FetiiDrivers_Previews: PreviewProvider {
    static var previews: some View {
        FetiiDriversView()
    }
}
