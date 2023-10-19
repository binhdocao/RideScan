import SwiftUI

struct HomeScreen: View {
	
	let maroonColor = Color(red: 0.5, green: 0, blue: 0)
	let darkGrayColor = Color(red: 0.5, green: 0.5, blue: 0.5)

	var body: some View {
		NavigationView{
			VStack(spacing: 40) {
				// Logo + "RideScan" are grouped together
				VStack(spacing: 15) {
					Image(systemName: "car.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 100, height: 100)
						.foregroundColor(maroonColor)
					
					Text("RideScan")
						.font(.largeTitle)
						.fontWeight(.bold)
						.foregroundColor(maroonColor)
				}
				
				// Spacing between the [logo & app name] and the welcome text
				Spacer().frame(height: 15)
				
				VStack(spacing: 10) {
					Text("Welcome!")
						.font(.title)
						.fontWeight(.bold)
						.foregroundColor(.black)
					
					Text("An easier way to get to your destination")
						.foregroundColor(.gray)
						.multilineTextAlignment(.center)
				}
				
				Spacer().frame(height: 50)
				
				VStack(spacing: 20) {
					NavigationLink(destination: UserProfile()) {
						Text("Create an account")
							.foregroundColor(.white)
							.padding()
							.background(maroonColor)
							.cornerRadius(8)
					}
					
					NavigationLink(destination: MapView()) {
						Text("Log In")
							.foregroundColor(.white)
							.padding()
							.background(Color.black)
							.cornerRadius(8)
					}
				}
			}
			.padding(.horizontal, 50)
		}
	}
}

struct HomeScreen_Previews: PreviewProvider {
	static var previews: some View {
		HomeScreen()
	}
}
