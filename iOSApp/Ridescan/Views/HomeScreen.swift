import SwiftUI

class UserSettings: ObservableObject {
	@Published var isAuthenticated: Bool = false
}

struct HomeScreen: View {
	
	let maroonColor = Color(red: 0.5, green: 0, blue: 0)
	let darkGrayColor = Color(red: 0.5, green: 0.5, blue: 0.5)

	var body: some View {
		NavigationView{
			VStack(spacing: 40) {
				
				// Spacing between the top of the phone and the car
				Spacer()
				
                Image("RideScanLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
				
				VStack(spacing: 10) {
					Text("Welcome!")
						.font(.title)
						.fontWeight(.bold)
						.foregroundColor(.black)
					
					Text("Your ride, your way")
						.foregroundColor(.gray)
						.multilineTextAlignment(.center)
				}
				
				Spacer()
				
				VStack(spacing: 20) {
					NavigationLink(destination: SignUpView()) {
						Text("Sign Up")
                            .foregroundColor(maroonColor)
                            .background(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .overlay(
                                // Border with maroon color
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(maroonColor, lineWidth: 2)
                            )
					}
					
					NavigationLink(destination: LogInView()) {
                        Text("Log In")
                            .foregroundColor(.white)
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 50)
                            .background(maroonColor)
                            .cornerRadius(8)
                            .overlay(
                                // Border with maroon color
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(maroonColor, lineWidth: 2)
                            )
					}
				}
                Spacer()
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
