//
//  Settings.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/30/23.
//

import Foundation
import SwiftUI

struct SettingsView: View {
	@AppStorage("isDarkMode") private var isDarkMode: Bool = false

	var body: some View {
		VStack {
			Text("Settings Page")
				.font(.largeTitle)
			
			Toggle("Dark Mode", isOn: $isDarkMode)
				.padding()
				.onChange(of: isDarkMode) { value in
					UIApplication.shared.windows.first?.overrideUserInterfaceStyle = value ? .dark : .light
				}
			
			// ... other settings and buttons ...

			Spacer()
		}
		.padding()
	}
}


struct Settings_Preview: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}

