//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI

struct WorkoutOfTheDayView: View {
    
    var schema: String
    var routine:UUID
    
    func setOrSuperset(set: Superset) -> String{
        let setNumber: Int = self.trainingModel.getSupersetIndex(for: self.trainingModel.routine, for: set) + 1
        if set.exercises!.count>1{
            return "Superset \(setNumber)"
        }
        else{
            return "Set \(setNumber)"
        }
    }
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    
    var body: some View {
        Form{
            List{
                ForEach(self.trainingModel.routine.superset!, id: \.self){ set in
                    Section(header: Text(self.setOrSuperset(set: set))){
                        HStack{
                            Text("Sets: \(set.sets)")
                        }
                        ForEach(set.exercises!, id:\.self) {exercise in
                            Text(exercise.name)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform:{
            self.trainingModel.loadRoutineFromSchema(for: schema, for: routine)
        })
        .navigationTitle("Training van vandaag")
    }
}
