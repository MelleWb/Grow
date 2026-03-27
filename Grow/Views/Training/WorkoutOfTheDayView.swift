//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI

struct WorkoutOfTheDayView: View {
    
    @Binding var showWOD: Bool
    @StateObject private var pushNotificationManager = PushNotificationManager.shared
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State var routine:UUID
    var loadsStatisticsOnAppear: Bool = true
    @State var amountOfSets: Int = 0
    @State var showAlert: Bool = false
    @State private var changeExerciseRoute: ChangeExerciseRoute?
    
    func setOrSuperset(set: Superset) -> String{
        //let setNumber: Int = self.$trainingModel.getSupersetIndex(for: self.trainingModel.routine, for: set) + 1
        let setNumber = 1
        if set.exercises.count>1{
            return "Superset \(setNumber)"
        }
        else{
            return "Set \(setNumber)"
        }
    }

    var body: some View {
        List{
            ForEach(self.trainingModel.routine.superset, id: \.self){ set in
                Section(header: Text(self.setOrSuperset(set: set))){
                    ForEach(set.exercises, id:\.self) {exercise in
                        ExerciseRow(
                            exercise: exercise,
                            amountOfSets: set.sets,
                            superset: set,
                            onChangeExercise: {
                                changeExerciseRoute = ChangeExerciseRoute(
                                    exerciseToChange: exercise,
                                    superset: set
                                )
                            }
                        )
                        }
                    }
                }
            }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveTraining) {
                    Text("Opslaan")
                        .foregroundColor(.accentColor)
                }
                .disabled(userModel.user.id == nil)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(action: {
                    hideKeyboard()
                },label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.accentColor)
                })
            }
        }
        .onAppear(perform: {
            if loadsStatisticsOnAppear {
                self.statisticsModel.getStatisticsForCurrentRoutine()
            }
        })
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Training van vandaag")
        .navigationDestination(item: $changeExerciseRoute) { route in
            let isPresented = Binding(
                get: { changeExerciseRoute != nil },
                set: { newValue in
                    if !newValue {
                        changeExerciseRoute = nil
                    }
                }
            )
            
            ChangeExercise(
                exerciseToChange: route.exerciseToChange,
                showExerciseChange: isPresented,
                superset: route.superset
            )
        }
        .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Oops"), message: Text("Er ging iets fout in het opslaan van je training"), dismissButton: .default(Text("Oke")))})
    }

    private func saveTraining() {
        guard let userID = userModel.user.id else {
            showAlert = true
            return
        }

        let success: Bool = self.statisticsModel.saveTraining(for: userID, for: routine)
        if success {
            pushNotificationManager.cancelTrainingReminder()
            self.trainingModel.initiateTrainingModel()
            self.statisticsModel.initiateStatistics()
            self.showWOD = false
        } else {
            self.showAlert.toggle()
        }
    }
}

private struct ChangeExerciseRoute: Identifiable, Hashable {
    let id = UUID()
    let exerciseToChange: Exercise
    let superset: Superset
}

struct ExerciseRow:View{
    
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State var exercise: Exercise
    @State var amountOfSets: Int
    @State var superset: Superset
    let onChangeExercise: () -> Void

    var body: some View{
        VStack(alignment: .leading){
                Button(""){}
                NavigationLink(destination:ExerciseDetailView(exercise: exercise)){
                    VStack(alignment: .leading){
                        Text(exercise.name).font(.headline)
                        Text(summaryText).font(.subheadline)
                    }.padding(10)
                }
                }.swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        onChangeExercise()
                    } label: {
                        Label("Verander", systemImage: "arrow.left.arrow.right")
                    }
                    .tint(.indigo)
                }
        VStack(alignment: .center){
            if statisticsModel.isRunningExercise(exercise) {
                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        DistanceRow(set: index, exercise: exercise)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        DurationRow(set: index, exercise: exercise, placeholderLabel: "min")
                            .frame(maxWidth: .infinity)
                    }
                }
            } else if statisticsModel.isIntervalExercise(exercise) {
                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        CompletedIntervalsRow(set: index, exercise: exercise)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        DurationRow(set: index, exercise: exercise, placeholderLabel: "sec")
                            .frame(maxWidth: .infinity)
                    }
                }
            } else if statisticsModel.isHyroxExercise(exercise) {
                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        DurationRow(set: index, exercise: exercise, placeholderLabel: "min")
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        WeightRow(set: index, exercise: exercise)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack{
                    ForEach(0..<amountOfSets, id: \.self) { index in
                        RepsRow(set: index, exercise: exercise)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }.onTapGesture {
            hideKeyboard()
        }
    }

    private var summaryText: String {
        if statisticsModel.isRunningExercise(exercise) {
            let distanceText = exercise.distanceKilometers > 0 ? "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: exercise.distanceKilometers)) km" : "afstand open"
            let timeText = exercise.durationMinutes > 0 ? "\(exercise.durationMinutes) min" : "tijd open"
            return "\(amountOfSets)x \(distanceText) • \(timeText)"
        }

        if statisticsModel.isIntervalExercise(exercise) {
            let intervalsText = exercise.intervalCount > 0 ? "\(exercise.intervalCount)x" : "interval open"
            let workText = exercise.workSeconds > 0 ? "\(exercise.workSeconds)s snel" : "snel open"
            let restText = exercise.restSeconds > 0 ? "\(exercise.restSeconds)s rust" : "rust open"
            return "\(amountOfSets)x \(intervalsText) • \(workText) • \(restText)"
        }

        if statisticsModel.isHyroxExercise(exercise) {
            let timeText = exercise.durationMinutes > 0 ? "\(exercise.durationMinutes) min" : "tijd open"
            return "\(amountOfSets)x \(timeText)"
        }

        return "\(String(amountOfSets)) sets van \(String(exercise.reps)) reps"
    }
}

struct RepsRow:View{
    
    @State var set: Int
    @State var exercise: Exercise
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
                .frame(maxWidth: .infinity, minHeight: 40)
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
    
    @State var set: Int
    @State var exercise: Exercise
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
                .frame(maxWidth: .infinity, minHeight: 40)
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

struct DistanceRow: View {
    @State var set: Int
    @State var exercise: Exercise
    @State var placeholder: String = "km"
    @State var distanceInput: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel

    var body: some View {
        VStack {
            TextField(placeholder, text: $distanceInput, onEditingChanged: { _ in
                if let value = NumberFormatter().number(from: distanceInput) {
                    self.statisticsModel.createUpdateDistance(for: exercise, for: set, with: value.doubleValue)
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(maxWidth: .infinity, minHeight: 40)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
        }
        .onAppear {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2

            if self.statisticsModel.getDistanceForSet(for: exercise, for: set) != 0 {
                let number = NSNumber(value: self.statisticsModel.getDistanceForSet(for: exercise, for: set))
                self.distanceInput = formatter.string(from: number) ?? ""
            }

            if self.statisticsModel.getDistancePlaceholder(for: exercise, for: set) != 0 {
                let number = NSNumber(value: self.statisticsModel.getDistancePlaceholder(for: exercise, for: set))
                self.placeholder = formatter.string(from: number) ?? "km"
            } else if exercise.distanceKilometers > 0 {
                let number = NSNumber(value: exercise.distanceKilometers)
                self.placeholder = formatter.string(from: number) ?? "km"
            }
        }
    }
}

struct DurationRow: View {
    @State var set: Int
    @State var exercise: Exercise
    let placeholderLabel: String
    @State var placeholder: String = ""
    @State var durationInput: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel

    var body: some View {
        VStack {
            TextField(placeholder, text: $durationInput, onEditingChanged: { _ in
                if let value = NumberFormatter().number(from: durationInput) {
                    let rawValue = value.intValue
                    let durationSeconds = placeholderLabel == "min" ? rawValue * 60 : rawValue
                    self.statisticsModel.createUpdateDuration(for: exercise, for: set, with: durationSeconds)
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(maxWidth: .infinity, minHeight: 40)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
        }
        .onAppear {
            let currentDuration = self.statisticsModel.getDurationForSet(for: exercise, for: set)
            if currentDuration != 0 {
                self.durationInput = displayValue(for: currentDuration)
            }

            let placeholderDuration = self.statisticsModel.getDurationPlaceholder(for: exercise, for: set)
            if placeholderDuration != 0 {
                self.placeholder = displayValue(for: placeholderDuration)
            } else if exercise.durationMinutes > 0 && placeholderLabel == "min" {
                self.placeholder = String(exercise.durationMinutes)
            } else if exercise.workSeconds > 0 && exercise.restSeconds > 0 && placeholderLabel == "sec" {
                self.placeholder = String((exercise.workSeconds + exercise.restSeconds) * max(exercise.intervalCount, 1))
            } else {
                self.placeholder = placeholderLabel
            }
        }
    }

    private func displayValue(for durationSeconds: Int) -> String {
        if placeholderLabel == "min" {
            return String(durationSeconds / 60)
        }
        return String(durationSeconds)
    }
}

struct CompletedIntervalsRow: View {
    @State var set: Int
    @State var exercise: Exercise
    @State var placeholder: String = "x"
    @State var intervalsInput: String = ""
    @EnvironmentObject var statisticsModel: StatisticsDataModel

    var body: some View {
        VStack {
            TextField(placeholder, text: $intervalsInput, onEditingChanged: { _ in
                if let value = NumberFormatter().number(from: intervalsInput) {
                    self.statisticsModel.createUpdateCompletedIntervals(for: exercise, for: set, with: value.intValue)
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(maxWidth: .infinity, minHeight: 40)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
        }
        .onAppear {
            if self.statisticsModel.getCompletedIntervalsForSet(for: exercise, for: set) != 0 {
                self.intervalsInput = String(self.statisticsModel.getCompletedIntervalsForSet(for: exercise, for: set))
            }

            if self.statisticsModel.getCompletedIntervalsPlaceholder(for: exercise, for: set) != 0 {
                self.placeholder = String(self.statisticsModel.getCompletedIntervalsPlaceholder(for: exercise, for: set))
            } else if exercise.intervalCount > 0 {
                self.placeholder = String(exercise.intervalCount)
            }
        }
    }
}

private struct WorkoutOfTheDayPreviewHarness: View {
    @State private var showWOD = true
    @StateObject private var userModel: UserDataModel
    @StateObject private var trainingModel: TrainingDataModel
    @StateObject private var statisticsModel: StatisticsDataModel

    init() {
        let exerciseOne = Exercise(name: "Bench Press", reps: 8, category: "Chest")
        let exerciseTwo = Exercise(name: "Incline Dumbbell Press", reps: 10, category: "Chest")
        let exerciseThree = Exercise(name: "Cable Fly", reps: 12, category: "Chest")
        let firstSuperset = Superset(sets: 3, exercises: [exerciseOne, exerciseTwo])
        let secondSuperset = Superset(sets: 2, exercises: [exerciseThree])
        let routine = Routine(type: "Push", superset: [firstSuperset, secondSuperset])

        let userModel = UserDataModel(autostart: false, runStartupSideEffects: false)
        userModel.user.id = "preview-user"

        let trainingModel = TrainingDataModel(autostart: false, runStartupSideEffects: false)
        trainingModel.routine = routine

        let statisticsModel = StatisticsDataModel(autostart: false, runStartupSideEffects: false)
        statisticsModel.trainingStatistics = TrainingStatistics(
            routineID: routine.id,
            exerciceStatistics: [
                ExerciseStatistics(exerciseID: exerciseOne.id, exerciseName: exerciseOne.name, set: 0, reps: 8, weight: 80),
                ExerciseStatistics(exerciseID: exerciseOne.id, exerciseName: exerciseOne.name, set: 1, reps: 8, weight: 82.5),
                ExerciseStatistics(exerciseID: exerciseTwo.id, exerciseName: exerciseTwo.name, set: 0, reps: 10, weight: 28),
                ExerciseStatistics(exerciseID: exerciseThree.id, exerciseName: exerciseThree.name, set: 0, reps: 12, weight: 18)
            ]
        )
        statisticsModel.exerciseStatistics = [
            ExerciseStatistics(exerciseID: exerciseOne.id, exerciseName: exerciseOne.name, date: Date(), set: 0, reps: 8, weight: 80),
            ExerciseStatistics(exerciseID: exerciseOne.id, exerciseName: exerciseOne.name, date: Date(), set: 1, reps: 8, weight: 82.5),
            ExerciseStatistics(exerciseID: exerciseOne.id, exerciseName: exerciseOne.name, date: Date(), set: 2, reps: 6, weight: 85),
            ExerciseStatistics(exerciseID: exerciseTwo.id, exerciseName: exerciseTwo.name, date: Date(), set: 0, reps: 10, weight: 28),
            ExerciseStatistics(exerciseID: exerciseTwo.id, exerciseName: exerciseTwo.name, date: Date(), set: 1, reps: 10, weight: 30),
            ExerciseStatistics(exerciseID: exerciseTwo.id, exerciseName: exerciseTwo.name, date: Date(), set: 2, reps: 8, weight: 32),
            ExerciseStatistics(exerciseID: exerciseThree.id, exerciseName: exerciseThree.name, date: Date(), set: 0, reps: 12, weight: 18),
            ExerciseStatistics(exerciseID: exerciseThree.id, exerciseName: exerciseThree.name, date: Date(), set: 1, reps: 12, weight: 20)
        ]

        _userModel = StateObject(wrappedValue: userModel)
        _trainingModel = StateObject(wrappedValue: trainingModel)
        _statisticsModel = StateObject(wrappedValue: statisticsModel)
    }

    var body: some View {
        NavigationStack {
            WorkoutOfTheDayView(
                showWOD: $showWOD,
                routine: trainingModel.routine.id,
                loadsStatisticsOnAppear: false
            )
            .environmentObject(userModel)
            .environmentObject(trainingModel)
            .environmentObject(statisticsModel)
        }
    }
}

#Preview {
    WorkoutOfTheDayPreviewHarness()
}
