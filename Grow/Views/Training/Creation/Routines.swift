//
//  AddRoutine.swift
//  Grow
//
//  Created by Swen Rolink on 06/07/2021.
//

import SwiftUI
import Firebase

struct ReviewSchema: View{
    @EnvironmentObject var schemaModel: TrainingDataModel
    var schema: Schema
    
    var body: some View {
        VStack{
            SchemaBody().environmentObject(schemaModel)
        }.onAppear(perform:{
            self.schemaModel.setSingleSchemaFromFetchedSchemas(for: schema)
        })
    }
}

struct SchemaBody: View{
    
    @Environment(\.presentationMode) private var presentationMode
    @State var showAddRoutine: Bool = false
    @State var routine: Routine?
    @EnvironmentObject var schemaModel: TrainingDataModel
    var schema: Schema?
    
    var body: some View{
            
                if showAddRoutine {
                    NavigationLink(
                        destination: AddRoutine(routine: routine ?? Routine(), routineType: "").environmentObject(schemaModel),
                                isActive: $showAddRoutine
                            ) {
                        AddRoutine(routine: routine ?? Routine(), routineType: "").environmentObject(schemaModel)
                    }.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
                }
        Form{
            HStack{
                Picker(selection: $schemaModel.schema.type, label: Text("Kies trainingstype")) {
                                    Text("Strength").tag("Strength")
                                    Text("Hypertrofie").tag("Hypertrofie")
                                    Text("Strength/Hypertrofie").tag("Strength/Hypertrofie")
                            }
                .padding()
                .pickerStyle(SegmentedPickerStyle())

            }
                
                
                    List{
                        if !(schemaModel.schema.routines).isEmpty {
                            ForEach(schemaModel.schema.routines) { routine in
                                
                                ZStack{
                                    Button("", action:{})
                                    NavigationLink(destination: AddRoutine(routine: routine, routineType: routine.type ?? "").environmentObject(schemaModel)){
                                        VStack{
                                            Text(routine.type!).font(.headline)
                                            }
                                    }
                                }
                            }.onDelete(perform: deleteRoutine)
                        }
                                Button(action: {
                                    self.showAddRoutine = true
                                    self.routine = Routine()
                                    //Call function in schemaModel to add the routine
                                    self.schemaModel.addRoutine(for: self.routine!)
                                }) {
                                    HStack{
                                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                                        Text("Voeg training toe").foregroundColor(Color.init("textColor"))
                                    }
                                }
                        }
                    }
            }
    func deleteRoutine(indexSet: IndexSet) {
        self.schemaModel.schema.routines.remove(atOffsets: indexSet)
    }
}

struct AddSchema: View{
    
    @Environment(\.presentationMode) private var presentationMode
    @State var showAddRoutine: Bool = false
    @State var routine: Routine?
    @StateObject var schemaModel = TrainingDataModel()
    var schema: Schema?
    
    var body: some View{
        NavigationView{
            VStack{
                SchemaBody().environmentObject(schemaModel)
            }.navigationBarTitle(Text("Schema"), displayMode: .inline)
        
        .navigationBarItems(leading:
                                Button(action: {
                                //dismiss the sheet & save the training
                                    presentationMode.wrappedValue.dismiss()
                               }) {
                                    Text("Annuleer")
                               }
                              , trailing:
                            Button(action: {
                            //dismiss the sheet & save the training
                                let success: Bool = self.schemaModel.createTraining()
                                if success{
                                    presentationMode.wrappedValue.dismiss()
                                }
                                else{
                                    print("some error")
                                }
                            
                                
                           }) {
                            Text("Opslaan").bold()
                           }
                    )
        }
    }
    func deleteRoutine(indexSet: IndexSet) {
        self.schemaModel.schema.routines.remove(atOffsets: indexSet)
    }
}


struct AddRoutine : View{
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    var routine: Routine
    @State var routineType: String
    
    var body: some View{
            VStack{
                Form{
                    Picker(selection: $routineType, label: Text("Trainingstype")) {
                        Text("Upper").tag("Upper")
                        Text("Lower").tag("Lower")
                        Text("Full Body").tag("Full Body")
                        Text("Push").tag("Push")
                        Text("Pull").tag("Pull")
                        Text("Chest").tag("Chest")
                        Text("Back").tag("Back")
                        Text("Shoulders").tag("Shoulders")
                        Text("Arms").tag("Arms")
                        Text("Legs").tag("Legs")
                                    
                    }
                    .onChange(of: routineType) { tag in
                        schemaModel.updateRoutineType(for: routine, to: routineType)
                    }
                    .pickerStyle(DefaultPickerStyle())
                     
                    if let routineIndex = schemaModel.getRoutineIndex(for: routine) {
                        if !(schemaModel.schema.routines[routineIndex].superset ?? []).isEmpty {
                            ForEach(schemaModel.schema.routines[routineIndex].superset!){ superset in
                                
                                List{
                                    Section(header: ShowSupersetHeader(routine: routine, superset: superset).environmentObject(schemaModel)

                                    ){
                                        
                                        SetsAndReps(routine: routine, superset: superset).environmentObject(schemaModel)
                                        
                                        ExercisesInSuperset(routine: routine, superset: superset).environmentObject(schemaModel)
                                        
                                        Button(action:{
                                        
                                        //Do something
                                        self.schemaModel.addExerciseToSuperset(for: routine, for: superset)
                                    }){
                                        HStack{
                                            Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                                            Text("Voeg oefening toe").foregroundColor(Color.init("textColor"))
                                        }
                                    }
                                        
                                }

                                    
                            }
                                
                        }
                    }
                        

                }
                Button(action: {
                    self.schemaModel.addSuperset(for: routine)
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

struct ShowSupersetHeader: View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    var routine: Routine
    var superset: Superset
    
    var body: some View{
        let supersetIndex: Int = schemaModel.getSupersetIndex(for: routine, for: superset) + 1
        HStack{Text("Superset \(supersetIndex)").font(.headline).padding()
            
            Button (action: {
                schemaModel.removeSuperset(for: superset, for: routine)
                
            }, label: {
                Image(systemName: "trash")
                    .foregroundColor(Color.init("textColor"))
                    .frame(width: 30, height: 30, alignment: .trailing)
            })
            
            
        }
    }
}

struct ExercisesInSuperset: View{
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    @ObservedObject var exerciseModel = ExerciseDataModel()
    var routine: Routine
    var superset: Superset
    
    var body: some View {
        
        let routineIndex: Int = schemaModel.getRoutineIndex(for: routine)
        let supersetIndex: Int = schemaModel.getSupersetIndex(for: routine, for: superset)
        
        if !(schemaModel.schema.routines[routineIndex].superset ?? []).isEmpty {
            if !(schemaModel.schema.routines[routineIndex].superset![supersetIndex].exercise ?? []).isEmpty {
                ForEach(schemaModel.schema.routines[routineIndex].superset![supersetIndex].exercise!){ exercise in
                    NavigationLink(destination: ExerciseDetail(routine: routine, superset: superset, exerciseInfo: exercise, selectedExercise: exercise.name ).environmentObject(schemaModel)){
                        Text(exercise.name)
                    }
                }.onDelete(perform:deleteExercise)
            }
        }
    }
    func deleteExercise(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.schemaModel.removeExercise(for: routine, for: superset, for: index)
    }
}


struct ExerciseDetail : View{
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @EnvironmentObject var schemaModel: TrainingDataModel
    @State var selectedExercise: String?
    
    var routine: Routine
    var superset: Superset
    var exerciseInfo: ExerciseInfo
    @State var searchText = ""
    @State var searching = false
    @State var showAddExerciseSheetView = false
    
    init(routine: Routine, superset: Superset, exerciseInfo: ExerciseInfo, selectedExercise: String?, searchText:String = "", searching:Bool = false){

        self.routine = routine
        self.superset = superset
        self.exerciseInfo = exerciseInfo
        self.selectedExercise = selectedExercise
        self.searchText = searchText
        self.searching = searching
        
        exerciseModel.fetchData()
    }
    
    var body: some View {

        List {
            SearchBar(searchText: $searchText, searching: $searching)
            ForEach(exerciseModel.exercises.filter({ (exercise: Exercise) -> Bool in
                return exercise.name.hasPrefix(searchText) || searchText == ""
            }), id: \.self) { exercise in
            SelectionCell(exercise: exercise.name, routine: routine, superset: superset, exerciseInfo: exerciseInfo, selectedExercise: self.$selectedExercise).environmentObject(schemaModel)
            }
        }.gesture(DragGesture()
                    .onChanged({ _ in
                        UIApplication.shared.dismissKeyboard()
                    })
        )
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

struct SelectionCell: View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    let exercise: String
    var routine: Routine
    var superset: Superset
    var exerciseInfo: ExerciseInfo
    @Binding var selectedExercise: String?

    var body: some View {
        HStack {
            if exercise == selectedExercise {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.init("textColor"))
            }
            else {
                Image(systemName: "circle")
                    .foregroundColor(Color.init("textColor"))
            }
            
            Text(exercise)
        }   .onTapGesture {
                    self.selectedExercise = self.exercise
                    self.schemaModel.updateExercise(for: routine, for: superset, for: exerciseInfo, to: exercise)
            }
    }
}


struct SetsAndReps : View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    var routine: Routine
    var superset: Superset
    
    @State var reps: String = ""
    @State var sets: String = ""
    
    var body: some View {
        
        
        let setsProxy = Binding<String>(
            get: { String(Int(self.superset.sets)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.schemaModel.updateSets(for: routine, for: superset, to: value.intValue)
                }
            }
        )
        let repsProxy = Binding<String>(
            get: { String(Int(self.superset.reprange)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.schemaModel.updateReps(for: routine, for: superset, to: value.intValue)
                    
                }
            }
        )
         
        HStack{
            VStack(alignment: .leading){
                Text("Sets").font(.caption)
                TextField("Sets", text: setsProxy)
                    .frame(height: 30)
                    .cornerRadius(13)
                    .keyboardType(.numberPad)
            }
            VStack(alignment: .leading){
                Text("Reps").font(.caption)
                TextField("Reps", text: repsProxy)
                    .frame(height: 30)
                    .keyboardType(.numberPad)
            }
        }
    }
}
