//
//  Search.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 11/1/23.
//

import Foundation
import SwiftUI
import MapKit
import SwiftUI

struct SearchSheetView: View {
	@Binding var destination: String
	@ObservedObject var searchCompleter: SearchCompleter
	
	var body: some View {
		VStack(spacing: 0) {
			Capsule()
				.fill(Color.gray)
				.frame(width: 40, height: 5)
				.padding(.top, 8)
			ScrollView {
				ForEach(searchCompleter.results.filter { $0.subtitle != "Search Nearby" }, id: \.self) { result in
					HStack {
						VStack(alignment: .leading, spacing: 5) {
							Text(result.title)
								.font(.body)
							Text(result.subtitle)
								.font(.caption)
								.foregroundColor(.gray)
						}
						Spacer()
					}
					.padding()
					.background(Color.white)
					.cornerRadius(8)
					.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
					.onTapGesture {
						destination = result.title
						searchCompleter.fetchDetails(for: result)
					}
				}
			}
            .padding(.top)
			.padding(.horizontal)
		}
		.background(maroonColor.opacity(0.8))
		.cornerRadius(20, corners: [.topLeft, .topRight])
		.edgesIgnoringSafeArea(.all)
		
	}
}





struct RoundedCorners: ViewModifier {
	var radius: CGFloat
	var corners: UIRectCorner
	
	func body(content: Content) -> some View {
		content
			.clipShape(RoundedCorner(radius: radius, corners: corners))
	}
}

struct RoundedCorner: Shape {
	var radius: CGFloat = .infinity
	var corners: UIRectCorner = .allCorners
	
	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		return Path(path.cgPath)
	}
}
extension View {
	func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
		self.modifier(RoundedCorners(radius: radius, corners: corners))
	}
}
