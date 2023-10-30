//
//  RideScanApp.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import SwiftUI

@main
struct RideScanApp: App {
	@StateObject var userSettings = UserSettings()

	var body: some Scene {
		WindowGroup {
			if userSettings.isAuthenticated {
				MapView()
					.environmentObject(userSettings)
			} else {
				NavigationView {
					HomeScreen()
				}
				.environmentObject(userSettings)
			}
		}
	}
}


