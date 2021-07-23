//
//  CustomPickerView.swift
//  Grow
//
//  Created by Swen Rolink on 20/07/2021.
//

import SwiftUI

protocol CustomPicker {
    func saveUpdates(_ newItem: String)
}

struct CustomPickerView: View {
    var items: [Exercise]
    @State private var filteredItems: [Exercise] = []
    @State private var filterString: String = ""
    @State private var frameHeight: CGFloat = 400
    @Binding var pickerField: String
    @Binding var presentPicker: Bool
    var saveUpdates: ((String) -> Void)?
    var body: some View {
        let filterBinding = Binding<String> (
            get: { filterString },
            set: {
                filterString = $0
                if filterString != "" {
                    filteredItems = items.filter{$0.name.lowercased().contains(filterString.lowercased())}
                } else {
                    filteredItems = items
                }
                setHeight()
            }
        )
        return ZStack {
            Color.black.opacity(0.4)
            VStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                presentPicker = false
                            }
                        }) {
                            Text("Cancel")
                        }
                        .padding(10)
                        Spacer()
                        if let saveUpdates = saveUpdates {
                            Button(action: {
                                
                                var itemContains: Bool = false
                                
                                for item in items {
                                    if item.name.contains(filterString) {
                                        itemContains = true
                                    }
                                }
                                
                                if itemContains {
                                    saveUpdates(filterString)
                                }
                                pickerField = filterString
                                withAnimation {
                                    presentPicker = false
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(filterString.isEmpty)
                        }
                    }
                    .background(Color(UIColor.darkGray))
                    .foregroundColor(.white)
                    Text("Tap an entry to select it, or type in a new entry.")
                        .font(.caption)
                        .padding(.leading,10)
                    TextField("Filter by entering text", text: filterBinding)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    List {
                        ForEach(filteredItems, id: \.self) { item in
                            Button(action: {
                                pickerField = item.name
                                withAnimation {
                                    presentPicker = false
                                }
                            }) {
                                Text(item.name)
                            }
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(maxWidth: 400)
                .padding(.horizontal,10)
                .frame(height: frameHeight)
                .padding(.top, 40)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            filteredItems = items
            setHeight()
        }
    }
    
    fileprivate func setHeight() {
        withAnimation {
            if filteredItems.count > 5 {
                frameHeight = 400
            } else if filteredItems.count == 0 {
                frameHeight = 130
            } else {
                frameHeight = CGFloat(filteredItems.count * 45 + 130)
            }
        }
    }
    
}
