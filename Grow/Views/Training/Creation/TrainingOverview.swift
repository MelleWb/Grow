//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI

struct TrainingOverview: View {
    
    @State private var showAddSchema = false
    @ObservedObject var schemas = TrainingDataModel()
    
    var body: some View {
        VStack{
            List {
                
                ForEach(Array(schemas.fetchedSchemas.enumerated()), id: \.1) { index, schema in
                    
                    NavigationLink(destination: ReviewSchema(schema: schema).environmentObject(schemas)){
                        Text(schema.name)
                    }
                }
                 
            }.sheet(isPresented:$showAddSchema) {
                AddSchema()
                    .allowAutoDismiss { false }
            }
            
        }.onAppear(perform:{
            schemas.fetchData()
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
