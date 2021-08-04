//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI

struct WorkoutOfTheDayView: View {
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    var schema: String
    var routine:UUID
    @State var amountOfSets: Int = 0
    
    func setOrSuperset(set: Superset) -> String{
        let setNumber: Int = self.trainingModel.getSupersetIndex(for: self.trainingModel.routine, for: set) + 1
        if set.exercises!.count>1{
            return "Superset \(setNumber)"
        }
        else{
            return "Set \(setNumber)"
        }
    }
    

    var body: some View {
        Form{
            List{
                ForEach(self.trainingModel.routine.superset!, id: \.self){ set in
                    Section(header: Text(self.setOrSuperset(set: set))){
                        ForEach(set.exercises!, id:\.self) {exercise in
                            ExerciseRow(exercise: exercise, amountOfSets: set.sets ?? 0)
                        }
                    }
                }
            }
        }.modifier(AdaptsKeyboard())
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform:{
            self.trainingModel.loadRoutineFromSchema(for: schema, for: routine)
        })
        .navigationTitle("Training van vandaag")
    }
}

struct ExerciseRow:View{
    
    @State var exercise: Exercise
    var amountOfSets: Int
    
    var body: some View{
        VStack(alignment: .leading){
                    Text(exercise.name).font(.headline)
                    Text("\(String(amountOfSets)) sets van \(String(exercise.reps ?? 0)) reps").font(.subheadline)
            }.padding(10)
        
        VStack(alignment: .leading){
            HStack{
                ForEach(0..<amountOfSets, id: \.self) { index in
                    
                    let setsProxy = Binding<String>(
                        get: { "" },
                        set: {
                                $0
                        }
                    )
                    TextField("reps", text: setsProxy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50, height: 40, alignment: .leading)
                }
            }
                
            HStack{
                ForEach(0..<amountOfSets, id: \.self) { index in
                    
                    let setsProxy = Binding<String>(
                        get: { "" },
                        set: {
                                $0
                        }
                    )
                    TextField("kg", text: setsProxy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50, height: 40, alignment: .leading)
                }
            }
        }.padding()
    }
}

struct NewSetRow:View{
    var body: some View {
        Text("Whoop whoop")
    }
}
