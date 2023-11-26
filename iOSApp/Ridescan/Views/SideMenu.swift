//
//  SideMenu.swift
//  RideScan
//
//  Created by Gage Broberg on 10/25/23.
//

import SwiftUI
import Models

var secondaryColor = Color.white

struct MenuItem: Identifiable {
    var id: Int
    var icon: String
    var text: String
}

var userActions: [MenuItem] = [
    MenuItem(id: 4001, icon: "person.circle.fill", text: "My Account"),
    MenuItem(id: 4002, icon: "car.fill", text: "Recent trips"),
    MenuItem(id: 4003, icon: "seal.fill", text: "Other"),
]

var profileActions: [MenuItem] = [
    MenuItem(id: 4004, icon: "wrench.and.screwdriver.fill", text: "Settings"),
    MenuItem(id: 4005, icon: "iphone.and.arrow.forward", text: "Logout"),
]

struct SideMenu: View {
    
    /// Model for the data in this view.
    @StateObject private var viewModel = UserProfileViewModel()
    
    // confirmations
    @State private var showingLogoutConfirmation = false
    
    // show screens
    @State private var shouldShowHomeScreen = false
	
	@Environment(\.presentationMode) var presentationMode
	@EnvironmentObject var userSettings: UserSettings

    
    @Binding var isSidebarVisible: Bool
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.6
    let menuColor = maroonColor

    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(.black.opacity(0.6))
            .opacity(isSidebarVisible ? 1 : 0)
            .animation(.easeInOut.delay(0.2), value: isSidebarVisible)
            .onTapGesture {
                isSidebarVisible.toggle()
            }
            
            content
            
            if shouldShowHomeScreen {
                HomeScreen()
                    .onDisappear {
                        shouldShowHomeScreen = false // Reset the state when the HomeScreen is dismissed
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showingLogoutConfirmation) {
            Alert(
                title: Text("Confirm Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .default(Text("Logout")) {
                    // Perform logout action here
					do {
						try KeychainService.delete(key: "userInfo")
						userSettings.isAuthenticated = false // This will trigger the root view to change.
					} catch {
						print("Error logging user out")
					}
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    var content: some View {
        HStack(alignment: .top) {
            ZStack(alignment: .top) {
                menuColor
                MenuChevron
                
                VStack(alignment: .leading, spacing: 20) {
                    userProfile
                    Divider()
                    MenuLinks(viewModel: viewModel, items: userActions, shouldShowHomeScreen: $shouldShowHomeScreen, showingLogoutConfirmation: $showingLogoutConfirmation)
                    Divider()
                    MenuLinks(viewModel: viewModel, items: profileActions, shouldShowHomeScreen: $shouldShowHomeScreen, showingLogoutConfirmation: $showingLogoutConfirmation)
                }
                .padding(.top, 80)
                .padding(.horizontal, 40)
            }
            .frame(width: sideBarWidth)
            .offset(x: isSidebarVisible ? 0 : -sideBarWidth)
            .animation(.default, value: isSidebarVisible)
            
            Spacer()
        }
    }
    
    var MenuChevron: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(menuColor)
                .frame(width: 60, height: 60)
                .rotationEffect(Angle(degrees: 45))
                .offset(x: isSidebarVisible ? -18 : -10)
                .onTapGesture {
                    isSidebarVisible.toggle()
                }
            
            Image(systemName: "chevron.right")
                .foregroundColor(secondaryColor)
                .rotationEffect(isSidebarVisible ? Angle(degrees: 180) : Angle(degrees: 0))
                .offset(x: isSidebarVisible ? -4 : 8)
                .foregroundColor(.blue)
        }
        .offset(x: sideBarWidth / 2, y: 80)
        .animation(.default, value: isSidebarVisible)
    }
    
    var userProfile: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
            
                AsyncImage(url: URL(string: "https://picsum.photos/100")) { image in
                    image
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white, lineWidth: 2)
                        }
                } placeholder: {
                    ProgressView()
                }
                .aspectRatio(3 / 2, contentMode: .fill)
                .shadow(radius: 4)
                
                Text("\(viewModel.user.firstname) \(viewModel.user.lastname)")
                    .foregroundColor(.white)
                    .bold()
                    .font(.title3)
                Text(verbatim: "\(viewModel.user.email)")
                    .foregroundColor(secondaryColor)
                    .font(.caption)
                    .padding(.bottom, 20)
            }
            Spacer()
        }
        .onAppear {
            // Retrieve user data from the Keychain and update the viewModel
            if let userData = try? KeychainService.load(key: "userInfo"), let user = try? JSONDecoder().decode(User.self, from: userData) {
                viewModel.user = user
				print("Loaded user from Keychain: \(user)")
            }
        }
    }
    
}

struct MenuLinks: View {
    @ObservedObject var viewModel: UserProfileViewModel
	
    var items: [MenuItem]
	
    @Binding var shouldShowHomeScreen: Bool
    @Binding var showingLogoutConfirmation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach(items) { item in
                menuLink(viewModel: viewModel, icon: item.icon, text: item.text, shouldShowHomeScreen: $shouldShowHomeScreen, showingLogoutConfirmation: $showingLogoutConfirmation)
            }
        }
        .padding(.vertical, 14)
        .padding(.leading, 8)
    }
}

struct menuLink: View {
    var viewModel: UserProfileViewModel
    var icon: String
    var text: String
	
    @Binding var shouldShowHomeScreen: Bool
    @Binding var showingLogoutConfirmation: Bool
	
	@State private var isActive: Bool = false
    
    @EnvironmentObject var userSettings: UserSettings
	
	var destinationView: some View {
		switch text {
		case "Settings":
			return AnyView(SettingsView())
		case "Recent trips":
			return AnyView(RecentTripsView())
		case "My Account":
            return AnyView(NavigationView {
                MyAccountView()
                    .environmentObject(userSettings) // Pass the environment object here
            })
		default:
			return AnyView(Text("Unknown"))
		}
	}

	var body: some View {
		HStack {
			Image(systemName: icon)
				.resizable()
				.frame(width: 20, height: 20)
				.foregroundColor(secondaryColor)
				.padding(.trailing, 18)
			Text(text)
				.foregroundColor(.white)
				.font(.body)
            NavigationLink("", destination: destinationView, isActive: $isActive)
				.opacity(0) // Hide the default NavigationLink arrow
		}
		.onTapGesture {
			switch text {
			case "Settings", "Recent trips", "My Account":
				isActive = true // Activate the NavigationLink
			case "Logout":
				showingLogoutConfirmation = true
			default:
				print("Tapped on \(text)")
			}
		}
	}
}

