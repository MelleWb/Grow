//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI

struct TrainingOverview: View {
    
    @State private var showAddSchema = false
    @State var schemaIndex: Int = 0
    @ObservedObject var fetchedSchemas = TrainingDataModel()
    
    var body: some View {
        VStack{
            List {
                
                ForEach(Array(fetchedSchemas.fetchedSchemas.enumerated()), id: \.1) { index, schema in
                    
                    NavigationLink(destination: AddSchema(schema: schema)){
                        Text(schema.name)
                    }
                }
                 
            }.sheet(isPresented:$showAddSchema) {
                AddSchema()
                    .allowAutoDismiss { false }
            }
            
        }.onAppear(perform:{
            fetchedSchemas.fetchData()
        })
        .navigationBarTitle(Text("Schema overzicht"), displayMode: .inline)
        .navigationBarItems(trailing:
               Button(action: {
                    self.showAddSchema = true
                   
               }) {
                   Image(systemName: "plus")
               }
           )
    }
}
