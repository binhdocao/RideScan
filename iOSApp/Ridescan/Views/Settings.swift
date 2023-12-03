//
//  Settings.swift
//  Ridescan
//
//  Created by Binh Do-Cao on 10/30/23.
//

import SwiftUI

struct Criteria: Hashable, Codable {
    let name: String
    var isSelected: Bool = true
    var order: Int
    // Computed property for multiplier
    var multiplier: Int = 1
    var selectedVal: String = ""
    var possVals: [String] = []
}

struct SettingsView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    @State private var sortCriteriaArray: [Criteria] = [
        Criteria(name: "Price", order: 1, multiplier: 8, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
        Criteria(name: "Time", order: 2, multiplier: 7, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
        Criteria(name: "Safety", order: 3, multiplier: 6, selectedVal: "Highest", possVals: ["Highest"]),
        Criteria(name: "Calories Burned", order: 4, multiplier: 5, selectedVal: "Highest", possVals: ["Lowest", "Highest"]),
        Criteria(name: "Carbon Emissions", order: 5, multiplier: 4, selectedVal: "Lowest", possVals: ["Lowest", "Highest"]),
        Criteria(name: "Experience", order: 6, multiplier: 3, selectedVal: "True", possVals: ["True", "False"]),
        Criteria(name: "Small Businesses", order: 7, multiplier: 2, selectedVal: "True", possVals: ["True", "False"]),
        Criteria(name: "Public", order: 8, multiplier: 1, selectedVal: "True", possVals: ["True", "False"]),
    ]

    // Initialize with initially selected criteria
    @State private var selectedCriteria: [Criteria] = []
    
    // activate edit mode by default
    @State var editMode = EditMode.active
    
    // grab the default min list row height
    @Environment(\.defaultMinListRowHeight) var minRowHeight

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
                    ForEach(Array(selectedCriteria.enumerated()), id: \.1.name) { (index, criteria) in
                        HStack {
                            Text("\(index + 1).") // Display the rank
                            Text(criteria.name)
                            Picker(selection: $selectedCriteria[index].selectedVal, label: Text("")) {
                                ForEach(selectedCriteria[index].possVals, id: \.self) { val in
                                    Text(val)
                                }
                            }
                        }
                    }
                    .onMove(perform: moveCriteria)
                    .onChange(of: selectedCriteria) { _ in
                        savePreferences()
                    }
                }
                .environment(\.editMode, $editMode) /// bind it here!
                .listStyle(InsetListStyle())
                .frame(width: .infinity, height: 500)
            }
            
        }
        .background(Color.clear) // Set the background color of the Form to clear
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { 
            loadPreferences()
        }
    }
    
    func toggleCriterion(_ criterion: Criteria) {
        // If the cretireon is in the sortArray
        if let index = self.sortCriteriaArray.firstIndex(where: { $0.name == criterion.name }) {
            // toggle in the sort array
            self.sortCriteriaArray[index].isSelected.toggle()
            
            // if this results in selected
            if self.sortCriteriaArray[index].isSelected {
                // add to selected criteria
                if !self.selectedCriteria.contains(where: { $0.name == criterion.name }) {
                    self.selectedCriteria.append(self.sortCriteriaArray[index])
                    updateCriteriaOrder()
                    setMultipliers()
                }
            } else {
                // otherwise remove from selected criteria
                self.selectedCriteria.removeAll { $0.name == criterion.name }
                updateCriteriaOrder()
                setMultipliers()
            }
                        
            // save info - saves selected criteria
            savePreferences()
        }
    }

    func moveCriteria(from source: IndexSet, to destination: Int) {
        // Reorder the selectedCriteria based on user interaction
        self.selectedCriteria.move(fromOffsets: source, toOffset: destination)
        updateCriteriaOrder()
        setMultipliers()
        savePreferences() // Save updated preferences to database

    }
    
    // Function to load criteria
    func loadPreferences() {
        // Attempt to load saved preferences
        if let savedPreferences = UserDefaults.standard.data(forKey: "criteriaOrder"),
           let decodedPreferences = try? JSONDecoder().decode([Criteria].self, from: savedPreferences) {
            self.selectedCriteria = decodedPreferences
            
            // Update isSelected state in sortCriteriaArray based on selectedCriteria
            for (index, _) in sortCriteriaArray.enumerated() {
                self.sortCriteriaArray[index].isSelected = self.selectedCriteria.contains(where: { $0.name == self.sortCriteriaArray[index].name })
            }
        } else {
            
            // Initialize selectedCriteria with initially selected criteria
            self.selectedCriteria = self.sortCriteriaArray.filter { $0.isSelected }
        }
    }
    
    // Function to set the multipliers of criteria in the sortCriteriaArray
    func setMultipliers() {
        for (index, _ ) in self.selectedCriteria.enumerated() {
            self.selectedCriteria[index].multiplier = self.selectedCriteria.count + 1 - self.selectedCriteria[index].order
        }
    }
    
    // Function to update the order of each criterion
    func updateCriteriaOrder() {
        for (index, _) in self.selectedCriteria.enumerated() {
            self.selectedCriteria[index].order = index + 1
        }
    }

    // Function to save preferences to the UserPreferences
    func savePreferences() {
        if let encoded = try? JSONEncoder().encode(self.selectedCriteria) {
            UserDefaults.standard.set(encoded, forKey: "criteriaOrder")
        }
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
