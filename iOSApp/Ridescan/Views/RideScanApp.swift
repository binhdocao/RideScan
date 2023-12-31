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
	var userProfileVM = UserProfileViewModel()


	var body: some Scene {
		WindowGroup {
            if userSettings.isAuthenticated {
                NavigationView {
                    MapView()
                        .environmentObject(userSettings)
                }
            } else {
				NavigationView {
					HomeScreen()
//					MapView()
				}
				.environmentObject(userSettings)
				.environmentObject(userProfileVM)
				.accentColor(Color(red: 0.5, green: 0, blue: 0)) //All back buttons are now maroon
			}
		}
	}
}


