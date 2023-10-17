//
//  UserProfile.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import SwiftUI

struct UserProfile: View {
    
    /// Model for the data in this view.
    @StateObject private var viewModel = UserProfileViewModel()
    
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var isEditing = false // State to track if the user is in edit mode
    @State private var editedFirstName = ""
    @State private var editedEmail = ""

    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill") // You can use an actual user profile image here
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.bottom, 20)

            Text("User Profile")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            VStack(alignment: .leading) {
                if isEditing {
                    TextField("First Name", text: $editedFirstName)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                    
                    TextField("Email", text: $editedEmail)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                } else {
                    Text("First Name:")
                        .font(.headline)
                    Text(viewModel.user.firstName)
                        .font(.body)
                        .padding(.bottom, 10)

                    Text("Email:")
                        .font(.headline)
                    Text(viewModel.user.email)
                        .font(.body)
                        .padding(.bottom, 10)
                }
                
                Button(action: {
                    Task {
                        if isEditing {
                            // Call the async function using Task
                            do {
                                try await viewModel.updateUserInfo(firstName: editedFirstName, email: editedEmail)
                            } catch {
                                // Handle errors here
                                print("Error updating user info: \(error)")
                            }
                        }
                        isEditing.toggle()
                    }
                }) {
                    Text(isEditing ? "Save" : "Edit")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 10)

            Spacer()
        }
        .padding()
        // When the view appears, retrieve an updated list of kittens.
        .onAppear(perform: fetchUserInfo)
    }
    
    private func fetchUserInfo() {
        self.busy = true
        self.errorMessage = nil
        Task {
            do {
                try await viewModel.fetchUserInfo()
                editedFirstName = viewModel.user.firstName // Initialize editedFirstName with the current first name
                editedEmail = viewModel.user.email // Initialize editedEmail with the current email
                busy = false
            } catch {
                busy = false
                errorMessage = "Failed to fetch user info: \(error.localizedDescription)"
            }
        }
    }
}


struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfile()
    }
}
