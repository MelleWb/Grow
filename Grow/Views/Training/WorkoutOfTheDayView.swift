//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI
import KeyboardToolbar

struct WorkoutOfTheDayView: View {
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @StateObject var statisticsModel  = StatisticsDataModel()
    var schema: String
    var routine:UUID
    @State var amountOfSets: Int = 0
    @Binding var showWorkoutView: Bool
    
    func setOrSuperset(set: Superset) -> String{
        let setNumber: Int = self.trainingModel.getSupersetIndex(for: self.trainingModel.routine, for: set) + 1
        if set.exercises!.count>1{
            return "Superset \(setNumber)"
        }
        else{
            return "Set \(setNumber)"
        }
    }
    
    let toolbarItems: [KeyboardToolbarItem] = [.dismissKeyboard]
    

    var body: some View {
        Form{
            List{
                ForEach(self.trainingModel.routine.superset!, id: \.self){ set in
                    Section(header: Text(self.setOrSuperset(set: set))){
                        ForEach(set.exercises!, id:\.self) {exercise in
                            ExerciseRow(exercise: exercise, amountOfSets: set.sets ?? 0).environmentObject(statisticsModel)
                        }
                    }
                }
            }
        }.modifier(AdaptsKeyboard())
        .keyboardToolbar(toolbarItems)
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform:{
            self.trainingModel.loadRoutineFromSchema(for: schema, for: routine)
        })
        .navigationTitle("Training van vandaag")
        .navigationBarItems(trailing:
                                Button(action:{
                                    let success: Bool = self.statisticsModel.saveTraining(for: userModel.user.id!, for: routine)
                                    if success{
                                        self.showWorkoutView = false
                                    } else {
                                        print("some error")
                                    }
                                }){
                                Image(systemName: "externaldrive.badge.plus").foregroundColor(.accentColor)
                                }
        )
    }
}

struct ExerciseRow:View{
    
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    var exercise: Exercise
    var amountOfSets: Int
    
    var body: some View{
        VStack(alignment: .leading){
                    Text(exercise.name).font(.headline)
                    Text("\(String(amountOfSets)) sets van \(String(exercise.reps ?? 0)) reps").font(.subheadline)
            }.padding(10)
        
        VStack(alignment: .leading){
            HStack{
                ForEach(0..<amountOfSets, id: \.self) { index in
                    WeightRow(set: index, exercise: exercise).environmentObject(statisticsModel)
                }
            }
                
            HStack{
                ForEach(0..<amountOfSets, id: \.self) { index in
                    RepsRow(set: index, exercise: exercise).environmentObject(statisticsModel)
                }
            }
        }.padding()
    }
}

struct RepsRow:View{
    
    var set: Int
    var exercise: Exercise
    @State var reps: Int?
    @State var input: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    
    var body: some View{
        
        let repsProxy = Binding<String>(
            get: { if self.statisticsModel.getRepsForSet(for: exercise, for: set)==0{
                return ""
            } else {
                return String(self.statisticsModel.getRepsForSet(for: exercise, for: set))
            } },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.statisticsModel.createUpdateReps(for: exercise, for: set, with: value.intValue)
                }
            }
        )

        TextField("reps", text: repsProxy)
        
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 50, height: 40, alignment: .leading)
            .keyboardType(.numberPad)
    }
}

struct WeightRow:View{
    
    var set: Int
    var exercise: Exercise
    @State var weight: Double?
    @State var input: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    
    var body: some View{
        
        let weightProxy = Binding<String>(
            get: {if self.statisticsModel.getWeightForSet(for: exercise, for: set)==0{
                return ""
            } else {
                return String(self.statisticsModel.getWeightForSet(for: exercise, for: set))
            } },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.statisticsModel.createUpdateWeight(for: exercise, for: set, with: value.intValue)
                }
            }
        )

        TextField("kg", text: weightProxy)
        
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 50, height: 40, alignment: .leading)
            .keyboardType(.numberPad)
    }
}
