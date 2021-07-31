//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI

struct WorkoutOfTheDayView: View {
    
    var routine:UUID
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    
    var body: some View {
        Form{
            List{
                ForEach(self.trainingModel.routine.superset!, id: \.self){ set in
                    Text(set.exercise![0].name)
                }
            }
        }
        .navigationTitle("Training van vandaag")
        .onAppear(perform:{
            self.trainingModel.loadRoutineFromSchema(for: routine)
            
            print(routine)
            print(self.trainingModel.routine)
        })
    }
}
