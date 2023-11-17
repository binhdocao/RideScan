//
//  Settings.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/30/23.
//

import SwiftUI

struct Criteria: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var isSelected: Bool = true
}

struct SettingsView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    @State private var sortCriteriaArray: [Criteria] = [
        Criteria(name: "Price"),
        Criteria(name: "Cost"),
        Criteria(name: "Time"),
        Criteria(name: "Carbon Emmissions"),
        Criteria(name: "Safety"),
        Criteria(name: "Experience"),
        Criteria(name: "Small Businesses"),
        Criteria(name: "Public/Private"),
        Criteria(name: "Most Scenic")
    ]

    // Initialize with initially selected criteria
    @State private var selectedCriteria: [Criteria] = []
    
    // activate edit mode by default
    @State var editMode = EditMode.active
    
    // grab the default min list row height
    @Environment(\.defaultMinListRowHeight) var minRowHeight


    init() {
        // Initialize selectedCriteria with initially selected criteria
        _selectedCriteria = State(initialValue: sortCriteriaArray.filter { $0.isSelected })
    }

    var body: some View {
        Form {
            Section(header: Text("Switches")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
                .onChange(of: isDarkMode) { value in
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = value ? .dark : .light
                }
            }
            // Selectable Bubbles (LazyHGrid with dynamic columns)
            Section(header: Text("Which criteria are most important to you?")) {
                ScrollView {
                    FlowLayout {
                        ForEach(sortCriteriaArray, id: \.self) { criteria in
                            Button(action: {
                                toggleCriterion(criteria)
                            }) {
                                Text(criteria.name)
                                    .padding()
                                    .background(criteria.isSelected ? maroonColor : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .frame(maxHeight: 100)
                                
                            }
                            .padding(5)
                        }
                    }
                    .listStyle(InsetListStyle())
                }
            }
            .listRowBackground(Color.clear) // Set the background color of the section to clear

            Section(header: Text("Criteria sort")) {
                // Ranking List (Draggable)
                List {
                    ForEach(Array(selectedCriteria.enumerated()), id: \.1.id) { (index, object) in
                        HStack {
                            Text("\(index + 1).") // Display the rank
                            Text(object.name)
                        }
                    }
                    .onMove(perform: moveCriteria)
                }
                .listRowInsets(EdgeInsets()) // Remove extra space
                .frame(minHeight: minRowHeight * CGFloat(selectedCriteria.count))
                .listStyle(InsetListStyle())
                .environment(\.editMode, $editMode) /// bind it here!
            }

        }
        .background(Color.clear) // Set the background color of the Form to clear
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func toggleCriterion(_ criterion: Criteria) {
        if let index = sortCriteriaArray.firstIndex(where: { $0.id == criterion.id }) {
            sortCriteriaArray[index].isSelected.toggle()
            if sortCriteriaArray[index].isSelected {
                selectedCriteria.append(criterion)
            } else {
                selectedCriteria.removeAll { $0.id == criterion.id }
            }
        }
    }

    func moveCriteria(from source: IndexSet, to destination: Int) {
        // Reorder the selectedCriteria based on user interaction
        selectedCriteria.move(fromOffsets: source, toOffset: destination)
    }
}

struct FlowLayout: Layout {
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width
                lineHeight = max(lineHeight, size.height)
            }

            totalWidth = max(totalWidth, lineWidth)
        }

        totalHeight += lineHeight

        return .init(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            if lineX + sizes[index].width > (proposal.width ?? 0) {
                lineY += lineHeight
                lineHeight = 0
                lineX = bounds.minX
            }

            subviews[index].place(
                at: .init(
                    x: lineX + sizes[index].width / 2,
                    y: lineY + sizes[index].height / 2
                ),
                anchor: .center,
                proposal: ProposedViewSize(sizes[index])
            )

            lineHeight = max(lineHeight, sizes[index].height)
            lineX += sizes[index].width
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
