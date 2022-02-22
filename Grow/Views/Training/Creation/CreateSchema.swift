//
//  CreateSchema.swift
//  Grow
//
//  Created by Swen Rolink on 28/01/2022.
//

import SwiftUI

struct CreateSchema: View{
    @EnvironmentObject var trainingModel: TrainingDataModel
    @Environment(\.presentationMode) private var presentationMode
    @State var schema = Schema()
    @State var selectedRoutine: UUID? = nil
    
    var body: some View{
        
        Form{
            Section {

                HStack{
                    Picker(selection: $schema.type, label: Text("Kies trainingstype")) {
                                        Text("Strength").tag("Strength")
                                        Text("Hypertrofie").tag("Hypertrofie")
                                        Text("Strength/Hypertrofie").tag("Strength/Hypertrofie")
                                }
                    .padding()
                    .pickerStyle(SegmentedPickerStyle())

                }
                TextField("Naam van het schema", text: $schema.name)
            }
            Section{
                List{
                    ForEach($schema.routines) { $routine in
                            Text(routine.type)
                                .background(NavigationLink(destination: CreateRoutine(selectedRoutine: $selectedRoutine, routine: $routine), tag: $routine.id, selection: $selectedRoutine){EmptyView()}.isDetailLink(false).opacity(0))
                    }.onDelete(perform: deleteRoutine)
                    
                    
                    Button(action: {
                        self.schema.routines.append(Routine())
                    }) {
                        HStack{
                            Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                            Text("Voeg training toe").foregroundColor(Color.init("textColor"))
                        }
                    }
                }
            }
        }
        .navigationBarTitle(Text("Schema"), displayMode: .inline)
        .navigationBarItems(
            trailing:
            Button(action: {
//            dismiss the sheet & save the training
                let success: Bool = self.trainingModel.createTraining(schema: self.schema)
                    if success{
                        presentationMode.wrappedValue.dismiss()
                    }
                    else{
                        print("some error")
                    }

                
            }) {
            Text("Voeg toe").bold()
            })
    }
    func deleteRoutine(indexSet: IndexSet) {
        self.schema.routines.remove(atOffsets: indexSet)
    }
}

struct CreateRoutine : View{
    
    @Binding var selectedRoutine: UUID?
    @Binding var routine: Routine
    @State var selectedSuperset: UUID? = nil
    
    let routineArray = ["Upper 1","Upper 2","Upper 3","Lower 1","Lower 2","Lower 3","Full Body 1","Full Body 2","Full Body 3","Push 1","Push 2","Push 3","Pull 1","Pull 2","Pull 3"]
    
    var body: some View{
            VStack{
                Form{
                    Section {
                        Picker(selection: $routine.type, label: Text("Trainingstype")) {
                            ForEach(routineArray, id:\.self) { routine in
                                Text(routine).tag(routine)
                            }
                        }.pickerStyle(DefaultPickerStyle())
                    }
                    
                    ForEach($routine.superset){ $set in
                        Section(header: Text("Set")) {
                            HStack{
                                if set.sets != 0 {
                                    Text("\(set.sets) sets")
                                        .padding()
                                }
                                VStack(alignment:.leading){
                                    if $set.exercises.isEmpty {
                                        Text("Configureer de set")
                                    } else {
                                        ForEach($set.exercises) { $exercise in
                                            HStack {
                                                Text(exercise.name)
                                                Spacer()
                                                Text("\(exercise.reps) hh")
                                            }.padding()
                                        }
                                    }
                                }
                            }
                            .background(NavigationLink(destination: AddSuperSet(superSet: $set, selectedSuperset: $selectedSuperset), tag: $set.id, selection: $selectedSuperset){EmptyView()}.isDetailLink(false).opacity(0))
                        }
                    }.onDelete { indexSet in
                        self.routine.superset.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        self.routine.superset.append(Superset())
                    }) {
                        HStack{
                            Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                            Text("Voeg superset toe").foregroundColor(Color.init("textColor"))
                        }
                    }
                }
            }
    }
}

struct AddSuperSet: View {
    @Binding var superSet: Superset
    @Binding var selectedSuperset: UUID?
    @State var selectedExercise: UUID? = nil
    @State var showAddExercise: Bool = false
    @State var isRepsSheetEnabled: Bool = false
    
    var body: some View {
        VStack{
            Form {
                Section(header:Text("Sets")){
                    VStack{
                        Stepper("Aantal setjes: \(self.superSet.sets)", value: $superSet.sets, in: 0...10)
                    }
                }
                
                if !$superSet.exercises.isEmpty{
                    Section(header:Text("Herhalingen")) {
                        ForEach($superSet.exercises) { $exercise in
                            HStack{
                                Text(exercise.name)
                                Picker("", selection: $exercise.reps) {
                                    ForEach(1..<50) {
                                       if $0 > 1 {
                                           Text("\($0) reps")
                                       } else {
                                           Text("1 rep")
                                       }

                                   }
                               }
                            }
                        }
                    }
                }
                
                NavigationLink(destination: AddExerciseToRoutine(showAddExercise: $showAddExercise, exercises: $superSet.exercises), isActive: $showAddExercise){
                    HStack{
                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                        Text("Oefeningen").foregroundColor(Color.init("textColor"))
                    }
                }
                    
            }
        }
        
        .navigationTitle("Superset")
        .blur(radius: isRepsSheetEnabled ? 1 : 0)
        .overlay(isRepsSheetEnabled ? Color.black.opacity(0.6) : nil)
    }
}

struct AddExerciseToRoutine: View {
    
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @State var showAddExerciseSheetView = false
    @State var searchText = ""
    @State var searching = false
    @Binding var showAddExercise: Bool
    @Binding var exercises: [Exercise]
    var body: some View{
            VStack(alignment: .leading){
                List {
                    SearchBar(searchText: $searchText, searching: $searching)
                    ForEach(exerciseModel.exercises.filter({ (exercise: Exercise) -> Bool in
                        return exercise.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
                    }), id: \.self) { exercise in
                        SelectExerciseCell(selectedExercises: $exercises, exercise: exercise)
                   }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Oefeningen")
            .navigationBarItems(trailing: (
                            Button(action: {
                                withAnimation {
                                    self.showAddExerciseSheetView.toggle()
                                }
                            }) {
                                Image(systemName: "plus")
                            })
                        )
        .sheet(isPresented: $showAddExerciseSheetView) {
            AddExercise(showAddExerciseSheetView: $showAddExerciseSheetView)
        }
    }
}

struct SelectExerciseCell: View {
    
    @Binding var selectedExercises: [Exercise]
    @State var exercise: Exercise

    var body: some View {
        HStack {
            let index = selectedExercises.firstIndex(where: { $0.documentID == exercise.documentID})
            
            if index != nil {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.accentColor)
            }
            else {
                Image(systemName: "circle")
                    .foregroundColor(.accentColor)
            }

            Text(exercise.name)
        }
        .onTapGesture {
            let index = selectedExercises.firstIndex(where: { $0.documentID == exercise.documentID})
            
            if index == nil {
                //Add to the selectedExercises
                self.selectedExercises.append(exercise)
            }
            else{
                //Remove from the selectedExercises
                self.selectedExercises.remove(at: index ?? 0)
            }
            
        }
    }
}
