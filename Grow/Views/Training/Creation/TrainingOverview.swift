//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI

struct TrainingDashboardView : View {
    var body: some View {
        NavigationView{
            VStack{
                List{
                    Section(header:Text("Schemas en oefeningen")){
                        NavigationLink(destination: ExerciseOverview()){
                            HStack{
                                Image(systemName: "list.bullet").foregroundColor(Color.init("textColor"))
                                Text("Oefeningen").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingOverview()){
                            HStack{
                                Image(systemName: "square.and.pencil").foregroundColor(Color.init("textColor"))
                                Text("Training schemas maken").font(.subheadline)
                            }
                        }
                    }
                    Section(header:Text("Trainingsdagen")){
                        NavigationLink(destination: TrainingDaySelectionView()){
                            HStack{
                                Image(systemName: "calendar").foregroundColor(Color.init("textColor"))
                                Text("Selecteer trainingsdagen").font(.subheadline)
                            }
                        }
                    }
                }
            }.navigationTitle(Text("Trainingen"))
        }
    }
}

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
        .navigationBarTitle(Text("Schemas"), displayMode: .inline)
        .navigationBarItems(trailing:
               Button(action: {
                    self.showAddSchema = true
                   
               }) {
                   Image(systemName: "plus")
               }
           )
    }
}
