//
//  testApp.swift
//  test
//
//  Created by Gage Broberg on 9/12/23.
//

import SwiftUI
import GoogleMaps

@main
struct testApp: App {
    init() {
        GMSServices.provideAPIKey("AIzaSyDAF8L1-gDo73VN7bVq0nSYOko9Z3mYIEY")
    }
    
    var body: some Scene {
        WindowGroup {
            HomePageView()
        }
    }
}
