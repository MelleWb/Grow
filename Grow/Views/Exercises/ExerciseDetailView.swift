//
//  ExerciseDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 30/06/2021.
//

import SwiftUI

struct ExerciseDescription:View {
    
    @State var exercise: Exercise
    @ObservedObject var exerciseStatsModel = StatisticsDataModel()
    
    var body: some View{
        VStack{
            Text(exercise.description ?? "Geen omschrijving bekend").padding()
        }.navigationTitle(exercise.name)
    }
}

struct ExerciseDetailView: View {
    
    @State var exercise: Exercise
    @StateObject var exerciseStatsModel = StatisticsDataModel()
    
    var body: some View {
        List{
            
            ZStack{
                Button(""){}
                NavigationLink(destination: ExerciseDescription(exercise: exercise, exerciseStatsModel: exerciseStatsModel)){
                    HStack{
                        Image(systemName: "info.circle").foregroundColor(.accentColor)
                        Text("Oefening omschrijving")
                    }
                }
            }
            
            if self.exerciseStatsModel.estimatedWeights.count > 1 {
            Section(header: Text("Persoonlijk record")){
                VStack(alignment: .leading){
                    HStack{
                        Text("Gewicht").padding().font(.headline)
                        Spacer()
                        Text(String(self.exerciseStatsModel.maxWeight.weight ?? 0)).padding()
                    }
                    HStack{
                        Text("Reps").padding().font(.headline)
                        Spacer()
                        Text(String(self.exerciseStatsModel.maxWeight.reps ?? 0)).padding()
                    }
                    HStack{
                        Text("Datum").padding().font(.headline)
                        Spacer()
                        Text(self.exerciseStatsModel.maxWeight.date, style: .date).padding()
                    }
                }
            }.environment(\.locale, Locale(identifier: "nl"))
                
            Section(header: Text("Geschat gewicht per rep")){
                ForEach(self.exerciseStatsModel.estimatedWeights, id:(\.self)){ estimation in
                        HStack{
                            Text(estimation.repsString)
                            Spacer()
                            Text("\(estimation.weight, specifier: "%.1f") kg")
                        }
                    }
                }
            } else {
                Section(header: Text("Nog geen statistieken beschikbaar")){
                    Text("Test nu je 1RM")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(exercise.name)
        .onAppear(perform:{
            self.exerciseStatsModel.calcEstimatedWeights(for: exercise.name)
        })
    }
}
