//
//  HomePageView.swift
//  test
//
//  Created by Gage Broberg on 9/18/23.
//

import SwiftUI

struct HomePageView: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image("RideScanLogo")
                    .resizable() // Make the image resizable
                    .frame(width: 275, height: 150) // Set the desired width and height
                
                NavigationLink(destination: BrazosTransitView()) {
                    Text("Get nearest bus driver")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 1
            .background(Color.white) // Set background color to white
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}
