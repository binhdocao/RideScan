//
//  MyAccount.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/30/23.
//

import Foundation
import SwiftUI
import Models

struct MyAccountView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $viewModel.user.firstname)
                TextField("Last Name", text: $viewModel.user.lastname)
                TextField("Email", text: $viewModel.user.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $viewModel.user.phone)
                    .keyboardType(.phonePad)
                SecureField("Password", text: $viewModel.user.password)
            }
            Section {
                Button("Save Changes") {
                    Task {
                        await saveUser()
                    }
                }
            }
        }
        .navigationTitle("My Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Load user data here
            loadUserData()
        }
    }
    
    private func loadUserData() {
        // Retrieve user data from the Keychain and update the viewModel
        if let userData = try? KeychainService.load(key: "userInfo"), let user = try? JSONDecoder().decode(User.self, from: userData) {
            viewModel.user = user
        }
    }

    private func saveUser() async {
        do {
            try await viewModel.updateUserInfo()
            
            // If the save is successful, set the alert to show a success message and save to Keychain
            let userData = try JSONEncoder().encode(viewModel.user)
            try KeychainService.save(key: "userInfo", data: userData)

            alertTitle = "Success"
            alertMessage = "Successfully updated!"
            showAlert = true
        } catch {
            // If an error occurs, set the alert to show an error message
            alertTitle = "Error"
            alertMessage = "Error updating user info."
            showAlert = true
        }
    }
}

// Preview of MyAccountView
struct MyAccountView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy user for the preview
        let dummyUser = User(firstname: "Jane", lastname: "Doe", email: "jane.doe@example.com", phone: "123-456-7890", password: "password")
        MyAccountView()
    }
}
