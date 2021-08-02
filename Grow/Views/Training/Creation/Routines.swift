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
                                    Section(header: ShowSupersetHeader(routine: routine, superset: superset).environmentObject(schemaModel)){
                                        
                                        AmountOfSets(routine: routine, superset: superset).environmentObject(schemaModel)
                                        
                                        ExercisesInSuperset(routine: routine, superset: superset).environmentObject(schemaModel)
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
    @State var showExerciseSheetView: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading){
            let routineIndex: Int = schemaModel.getRoutineIndex(for: routine)
            let supersetIndex: Int = schemaModel.getSupersetIndex(for: routine, for: superset)
            
            if schemaModel.schema.routines[routineIndex].superset != nil {
                if schemaModel.schema.routines[routineIndex].superset![supersetIndex].exercises != nil {
                    ForEach(schemaModel.schema.routines[routineIndex].superset![supersetIndex].exercises!){ exercise in
                        
                        let repsProxy = Binding<String>(
                            get: { String(exercise.reps ?? 0) },
                            set: {
                                if let value = NumberFormatter().number(from: $0) {
                                    self.schemaModel.updateExerciseReps(for: routine, for: superset, for: exercise, to: value.intValue)
                                }
                            }
                        )
                        
                        HStack{
                                TextField("Reps", text: repsProxy)
                                    .frame(width: 60, height: 40)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            Text(exercise.name).padding()
                        }
                    }.onDelete(perform:deleteExercise)
                }
            }
        }.sheet(isPresented: $showExerciseSheetView, content: {ExerciseSheetView(showExerciseSheetView: $showExerciseSheetView, routine: routine, superset: superset)})
        
            Button(action:{
                self.showExerciseSheetView.toggle()
            }){
                HStack{
                    Image(systemName: "checkmark.circle").foregroundColor(Color.init("textColor"))
                    Text("Selecteer oefeningen").foregroundColor(Color.init("textColor"))
                }
            }
        
    }
    func deleteExercise(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.schemaModel.removeExercise(for: routine, for: superset, for: index)
    }
}

struct ExerciseSheetView : View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @Binding var showExerciseSheetView: Bool
    var routine: Routine
    var superset: Superset
    
    @State var selectedExercises: [Exercise]?
    @State var searchText = ""
    @State var searching = false
    @State var showAddExerciseSheetView = false
    
    init(showExerciseSheetView: Binding<Bool>, routine: Routine, superset: Superset, selectedExercises: [Exercise]? = [Exercise]()){
        self._showExerciseSheetView = showExerciseSheetView
        self.routine = routine
        self.superset = superset
        self.selectedExercises = selectedExercises
        self.exerciseModel.fetchData()
    }
    
    
    var body: some View {
        NavigationView{
            List {
                SearchBar(searchText: $searchText, searching: $searching)
                ForEach(exerciseModel.exercises.filter({ (exercise: Exercise) -> Bool in
                    return exercise.name.hasPrefix(searchText) || searchText == ""
                }), id: \.self) { exercise in
                    SelectionCell(exercise: exercise, routine: routine, superset: superset, selectedExercises: self.$selectedExercises).environmentObject(schemaModel)
                }
            }.gesture(DragGesture()
                        .onChanged({ _ in
                            UIApplication.shared.dismissKeyboard()
                        })
            )
            .navigationTitle(Text("Voeg oefeningen toe"))
            .navigationBarItems(leading: (
            Button(action: {
                withAnimation {
                    self.showExerciseSheetView.toggle()
                }
            }) {
                Text("Annuleer").foregroundColor(Color.init("textColor"))
            }),
            trailing: (
            HStack{
                Button(action: {
                    withAnimation {
                        self.showAddExerciseSheetView.toggle()
                    }
                }) {
                    Image(systemName: "plus.circle").foregroundColor(Color.init("textColor"))
                }
                Spacer()
                Button(action: {
                    withAnimation {
                        if self.selectedExercises != nil && self.selectedExercises!.count > 0 {
                            self.schemaModel.updateExercises(for: routine, for: superset, with: selectedExercises!)
                        }
                        self.showExerciseSheetView.toggle()
                    }
                }) {
                    Text("Opslaan").foregroundColor(Color.init("textColor"))
                }
                
            }))
            .sheet(isPresented: $showAddExerciseSheetView) {
                AddExercise(showAddExerciseSheetView: $showAddExerciseSheetView)
            }
            .onAppear(perform:{
                //Preselect the selectedExercises
                self.selectedExercises = self.schemaModel.getExercises(routine: routine, for: superset)
            })
        }
    }
}

struct SelectionCell: View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    var exercise: Exercise
    var routine: Routine
    var superset: Superset
    @Binding var selectedExercises: [Exercise]?

    var body: some View {
        HStack {
            if selectedExercises != nil {
                
                let index = selectedExercises!.firstIndex(where: { $0.documentID == exercise.documentID})
                
                if index != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.init("textColor"))
                }
                else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.init("textColor"))
                }
            }
            else {
                Image(systemName: "circle")
                    .foregroundColor(Color.init("textColor"))
            }
            Text(exercise.name)
        }
        .onTapGesture {
            if self.selectedExercises == nil {
                self.selectedExercises = [exercise]
            }
            else {
                let index = selectedExercises!.firstIndex(where: { $0.documentID == exercise.documentID})
                if index == nil {
                    //Add to the selectedExercises
                    self.selectedExercises?.append(exercise)
                }
                else{
                    //Remove from the selectedExercises
                    self.selectedExercises?.remove(at: index ?? 0)
                }
            }
        }
    }
}


struct AmountOfSets : View {
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    var routine: Routine
    var superset: Superset

    
    var body: some View {

        VStack(alignment: .leading){
            HStack{
                Text("Sets").padding()
                Text(String(self.schemaModel.getAmountOfSets(for: routine, for: superset)))
                
                Button(action: {
                    self.schemaModel.updateSets(for: routine, for: superset, to: "plus")
                },label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.init("textColor"))
                }).padding()
                
                
                Button(action: {
                        self.schemaModel.updateSets(for: routine, for: superset, to: "min")
                }, label:{
                    Image(systemName: "minus.circle.fill").foregroundColor(Color.init("textColor"))
                }).padding()
            }
        }
    }
}
