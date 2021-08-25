//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI
import KeyboardToolbar

struct WorkoutOfTheDayView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    var schema: String
    var routine:UUID
    @State var amountOfSets: Int = 0
    //@Binding var showWorkoutView: Bool
    
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
        NavigationView{
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
        .keyboardToolbar(toolbarItems)
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform:{
            self.trainingModel.loadRoutineFromSchema(for: schema, for: routine)
            self.statisticsModel.getStatisticsForCurrentRoutine(for: routine)
        })
        .navigationTitle("Training van vandaag")
        .navigationBarItems(leading: Button(action:{presentationMode.wrappedValue.dismiss()},label:{Text("Sluiten")}),
                                trailing:
                                Button(action:{
                                    let success: Bool = self.statisticsModel.saveTraining(for: userModel.user.id!, for: routine)
                                    if success{
                                        presentationMode.wrappedValue.dismiss()
                                    } else {
                                        print("some error")
                                    }
                                }){
                                Text("Opslaan").foregroundColor(.accentColor)
                                }
        )
        }
    }
}

struct ExerciseRow:View{
    
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    var exercise: Exercise
    var amountOfSets: Int

    var body: some View{
        
        VStack(alignment: .leading){
            ZStack{
                Button(""){}
                NavigationLink(destination:ExerciseDetailView(exercise: exercise)){
                    VStack(alignment: .leading){
                        Text(exercise.name).font(.headline)
                        Text("\(String(amountOfSets)) sets van \(String(exercise.reps ?? 0)) reps").font(.subheadline)
                    }.padding(10)
                }
            }
        }.padding(10)
        
        VStack(alignment: .center){
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
        }.onTapGesture {
            hideKeyboard()
        }
    }
}

struct RepsRow:View{
    
    var set: Int
    var exercise: Exercise
    @State var placeholder: String = "reps"
    @State var repsInput: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    
    var body: some View{
        VStack{
            TextField($placeholder.wrappedValue, text: $repsInput ,onEditingChanged: { _ in
                if let value = NumberFormatter().number(from: repsInput) {
                    self.statisticsModel.createUpdateReps(for: exercise, for: set, with: value.intValue)
                }
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 58, height: 40, alignment: .leading)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
        }.onAppear(perform: {
            
            if self.statisticsModel.getRepsPlaceholder(for: exercise, for:set) != 0{
                self.placeholder = String(self.statisticsModel.getRepsPlaceholder(for: exercise, for:set))
            }
            
            if self.statisticsModel.getRepsForSet(for: exercise, for: set) != 0 {
                self.repsInput = String(self.statisticsModel.getRepsForSet(for: exercise, for: set))
            }
        })
    }
}

struct WeightRow:View{
    
    var set: Int
    var exercise: Exercise
    @State var placeholder: String = "kg"
    @State var weight: Double?
    @State var weightInput: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    
    func roundNumber(formattedValue: String) -> String {
        if let range =  formattedValue.range(of: ".") {
            let decimal = formattedValue[range.lowerBound..<formattedValue.endIndex]
            
            if decimal == ".0"{
                return String(formattedValue[formattedValue.startIndex..<range.lowerBound])
            } else {
                return formattedValue
            }
            
        }
        return formattedValue
    }
    
    var body: some View{
        VStack{
            TextField(placeholder, text: $weightInput, onEditingChanged: { _ in
                      if let value = NumberFormatter().number(from: weightInput) {
                          self.statisticsModel.createUpdateWeight(for: exercise, for: set, with: value.doubleValue)
                      }
                  })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 58, height: 40, alignment: .leading)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
        }
        .onAppear(perform: {
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            
            if self.statisticsModel.getWeightForSet(for: exercise, for: set) != 0 {

                let number = NSNumber(value: self.statisticsModel.getWeightForSet(for: exercise, for: set))
                let formattedValue = formatter.string(from: number)!
                
                self.weightInput = roundNumber(formattedValue: formattedValue)
            }
            if self.statisticsModel.getWeightPlaceholder(for: exercise, for: set) != 0 {
                let number = NSNumber(value: self.statisticsModel.getWeightPlaceholder(for: exercise, for: set))
                let formattedValue = formatter.string(from: number)!
                
                self.placeholder = roundNumber(formattedValue: formattedValue)
            }

        })
    }
}
