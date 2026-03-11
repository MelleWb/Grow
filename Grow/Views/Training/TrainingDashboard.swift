//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI
import FirebaseFirestore

struct TrainingDashboardView : View {
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    
    var body: some View {
        
        NavigationStack{
            VStack{
                List{
                    Section(header:Text("Schemas, oefeningen en statistieken")){
                        NavigationLink(destination: ExerciseOverview()){
                            HStack{
                                Image(systemName: "list.bullet").foregroundColor(.accentColor)
                                Text("Oefeningen en statistieken").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingVolumeView()){
                            HStack{
                                Image(systemName: "chart.bar").foregroundColor(.accentColor)
                                Text("Trainingsvolume per trainingsdag").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingHistoryOverview()){
                            HStack{
                                Image(systemName: "clock.arrow.circlepath").foregroundColor(.accentColor)
                                Text("Training historie").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingOverview()){
                            HStack{
                                Image(systemName: "square.and.pencil").foregroundColor(.accentColor)
                                Text("Bekijk of maak trainingschemas").font(.subheadline)
                            }
                        }
                    }
                    Section(header:Text("Trainingsdagen")){
                        NavigationLink(destination: TrainingDaySelectionView()){
                            HStack{
                                Image(systemName: "calendar").foregroundColor(.accentColor)
                                Text("Selecteer je trainingsdagen").font(.subheadline)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Trainingen"))
        }
    }
}

struct TrainingOverview: View {
    
    @State private var showCreateSchema = false
    @EnvironmentObject var trainingModel: TrainingDataModel
    
    var body: some View {
        VStack{
            List {
                ForEach(Array(trainingModel.fetchedSchemas.enumerated()), id: \.1) { index, schema in
                    ZStack{
                        Button(""){}
                        NavigationLink(destination: ReviewSchema(newSchema: trainingModel, schema: schema)){
                            Text(schema.name)
                        }
                    }
                }.onDelete(perform:deleteSchema)
                 
            }
        }
        
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(Text("Schemas"), displayMode: .inline)
        .navigationDestination(isPresented: $showCreateSchema) {
            CreateSchema()
        }
        .navigationBarItems(trailing:
               Button(action: {
                    self.showCreateSchema = true
               }) {
                   Image(systemName: "plus")
               }
           )
    }
    func deleteSchema(at offsets: IndexSet){
        let index = offsets[offsets.startIndex]
        
        let documentID = trainingModel.fetchedSchemas[index].docID ?? ""
        
        let db = Firestore.firestore()
        
        db.collection("schemas").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                self.trainingModel.fetchedSchemas.remove(atOffsets: offsets)
            }
        }
    }
}

struct ProgressBarVertical: View {
    var value: Float
    var label: String
    
    var body: some View {
        VStack(alignment: .leading){
            Spacer()
                if value <= 0.98 {
                Rectangle()
                    .frame(width: 15, height: CGFloat(self.value) * 75)
                    .foregroundColor(Color.orange)
                    .animation(Animation.linear(duration: 0.5), value: value)
                    .cornerRadius(45.0)
                    .offset(x: 10)
                }
                else {
                    Rectangle()
                        .frame(width: 15, height: CGFloat(self.value) * 75)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
                        .cornerRadius(45.0)
                        .offset(x: 10)
                }
            Text(label)
                .foregroundColor(.accentColor)
                .font(.footnote)
                .frame(height: 20)
        }
    }
}
