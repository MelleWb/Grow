//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI

struct TrainingOverview: View {
    
    @ObservedObject var overview = TrainingDataModel()
    @State private var showAddSchema = false
    @State var schemaIndex: Int = 0
    
    var body: some View {
        VStack{
            List {
                ForEach(Array(overview.fetchedSchemas.enumerated()), id: \.1) { index, schema in
                    Button(action: {
                         self.showAddSchema = true
                    }) {
                        Text(schema.name)
                    }
                }
            }.sheet(isPresented:$showAddSchema) {
                AddSchema()
                    .allowAutoDismiss { false }
            }
            
        }.navigationBarTitle(Text("Schema overzicht"), displayMode: .inline)
        .navigationBarItems(trailing:
               Button(action: {
                    self.showAddSchema = true
                   
               }) {
                   Image(systemName: "plus")
               }
           )
    }
}
