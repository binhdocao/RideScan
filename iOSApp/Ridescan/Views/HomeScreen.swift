import SwiftUI
import AuthenticationServices


class UserSettings: ObservableObject {
	
	@Published var isAuthenticated: Bool = false

	init() {
		isAuthenticated = isAuthenticatedUser()
	}

	private func isAuthenticatedUser() -> Bool {
		do {
			if let _ = try KeychainService.load(key: "userIdentifier") {
				return true
			}
		} catch {
			print("Error loading from keychain: \(error)")
		}
		return false
	}
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
					
					SignInWithAppleButton()
						.frame(width: 280, height: 44)
						.cornerRadius(8)
				}
				Spacer()
			}
			.padding(.horizontal, 50)
		}
	}
}


struct SignInWithAppleButton: UIViewRepresentable {
	@EnvironmentObject var userSettings: UserSettings

	func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
		let button = ASAuthorizationAppleIDButton()
		button.addTarget(context.coordinator, action: #selector(Coordinator.handleAppleIdRequest), for: .touchUpInside)
		return button
	}

	func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}

	class Coordinator: NSObject, ASAuthorizationControllerDelegate {
		var parent: SignInWithAppleButton

		init(_ parent: SignInWithAppleButton) {
			self.parent = parent
		}
		
		@objc func handleAppleIdRequest() {
			let appleIDProvider = ASAuthorizationAppleIDProvider()
			let request = appleIDProvider.createRequest()
			request.requestedScopes = [.fullName, .email]
			let authorizationController = ASAuthorizationController(authorizationRequests: [request])
			authorizationController.delegate = self
			authorizationController.performRequests()
		}

		func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
			if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
				let userIdentifier = appleIDCredential.user
				let fullName = appleIDCredential.fullName
				let email = appleIDCredential.email
				
				// Store user identifier in Keychain
				do {
					if let identifierData = userIdentifier.data(using: .utf8) {
						try KeychainService.save(key: "userIdentifier", data: identifierData)
						DispatchQueue.main.async {
							self.parent.userSettings.isAuthenticated = true
						}
					}
				} catch {
					print("Error saving to keychain: \(error)")
				}
				
				// Handle the authentication
				print("User id is \(userIdentifier) \n Full Name is \(String(describing: fullName)) \n Email id is \(String(describing: email))")
				DispatchQueue.main.async {
					self.parent.userSettings.isAuthenticated = true
				}
			}
		}

		func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
			// Handle error.
		}
	}
}


struct HomeScreen_Previews: PreviewProvider {
	
	
	static var previews: some View {
		HomeScreen()
	}
}
