//
//  SearchBar.swift
//  Grow
//
//  Created by Swen Rolink on 02/07/2021.
//

import SwiftUI
import UIKit

struct SearchBar: View {
    
    @Binding var searchText: String
    @Binding var searching: Bool
    
    var body: some View {
            ZStack{
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.accentColor)
                    TextField("Search ..", text: $searchText) { startedEditing in
                         if startedEditing {
                             withAnimation {
                                 searching = true
                             }
                         }
                     } onCommit: {
                         withAnimation {
                             searching = false
                         }
                     }.disableAutocorrection(true)
                    
                    if searching {
                                    Button("Annuleer") {
                                        searchText = ""
                                        withAnimation {
                                            searching = false
                                            UIApplication.shared.dismissKeyboard()
                                        }
                                    }
                                }
                 }
                     .foregroundColor(.gray)
                     .padding(.leading, 13)
                Rectangle()
                    .foregroundColor(Color("lightGrey"))
            }.frame(height: 40)
            .cornerRadius(13)
            .padding()
    }
}
