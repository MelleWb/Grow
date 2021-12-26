//
//  AddRoutine.swift
//  Grow
//
//  Created by Swen Rolink on 06/07/2021.
//
import SwiftUI
import Firebase

struct ReviewSchema: View{
    @ObservedObject var newSchema: TrainingDataModel
    var schema: Schema
    
    var body: some View {
        VStack{
            SchemaBody(newSchema: newSchema)
        }
        .navigationBarItems(trailing:
                                Button(action: {
                                    self.newSchema.updateTraining()
                                   }) {
                                      Text("Opslaan")
                                   })
        .onAppear(perform:{
            self.newSchema.setSingleSchemaFromFetchedSchemas(for: schema)
        })
    }
}

struct SchemaBody: View{
    
    @Environment(\.presentationMode) private var presentationMode
    @State var showAddRoutine: Bool = false
    @State var routine: Routine?
    @ObservedObject var newSchema: TrainingDataModel
    var schema: Schema?
    
    var body: some View{
            
                if showAddRoutine {
                    NavigationLink(
                        destination: AddRoutine(newSchema: newSchema, routine: routine ?? Routine(), routineType: ""),
                                isActive: $showAddRoutine
                            ) {
                        AddRoutine(newSchema: newSchema, routine: routine ?? Routine(), routineType: "")
                    }.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
                }
        Form{
            HStack{
                Picker(selection: $newSchema.schema.type, label: Text("Kies trainingstype")) {
                                    Text("Strength").tag("Strength")
                                    Text("Hypertrofie").tag("Hypertrofie")
                                    Text("Strength/Hypertrofie").tag("Strength/Hypertrofie")
                            }
                .padding()
                .pickerStyle(SegmentedPickerStyle())

            }
                
                
                    List{
                        if !(newSchema.schema.routines).isEmpty {
                            ForEach(newSchema.schema.routines) { routine in
                                
                                ZStack{
                                    Button("", action:{})
                                    NavigationLink(destination: AddRoutine(newSchema: newSchema, routine: routine, routineType: routine.type ?? "")){
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
                                    self.newSchema.addRoutine(for: self.routine!)
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
        self.newSchema.schema.routines.remove(atOffsets: indexSet)
    }
}

struct AddSchema: View{
    
    @Environment(\.presentationMode) private var presentationMode
    @State var showAddRoutine: Bool = false
    @State var routine: Routine?
    @ObservedObject var newEmptySchema = TrainingDataModel()
    var schema: Schema?
    
    var body: some View{
        NavigationView{
            VStack{
                SchemaBody(newSchema: newEmptySchema)
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
                                let success: Bool = self.newEmptySchema.createTraining()
                                if success{
                                    presentationMode.wrappedValue.dismiss()
                                }
                                else{
                                    print("some error")
                                }
                            
                                
                           }) {
                            Text("Voeg toe").bold()
                           }
                    )
        }
    }
    func deleteRoutine(indexSet: IndexSet) {
        self.newEmptySchema.schema.routines.remove(atOffsets: indexSet)
    }
}


struct AddRoutine : View{
    
    @ObservedObject var newSchema: TrainingDataModel
    var routine: Routine
    @State var routineType: String
    
    let routineArray = ["Upper 1","Upper 2","Upper 3","Lower 1","Lower 2","Lower 3","Full Body 1","Full Body 2","Full Body 3","Push 1","Push 2","Push 3","Pull 1","Pull 2","Pull 3"]
    
    var body: some View{
            VStack{
                Form{
                    Picker(selection: $routineType, label: Text("Trainingstype")) {
                        ForEach(routineArray, id:\.self) { routine in
                            Text(routine).tag(routine)
                        }
                    }
                    .onChange(of: routineType) { tag in
                        newSchema.updateRoutineType(for: routine, to: routineType)
                    }
                    .pickerStyle(DefaultPickerStyle())
                     
                    if let routineIndex = newSchema.getRoutineIndex(for: routine) {
                        if !(newSchema.schema.routines[routineIndex].superset ?? []).isEmpty {
                            ForEach(newSchema.schema.routines[routineIndex].superset!){ superset in
                                
                                List{
                                    Section(header: ShowSupersetHeader(newSchema: newSchema, routine: routine, superset: superset)){
                                        
                                        AmountOfSets(newSchema: newSchema, routine: routine, superset: superset)
                                        
                                        ExercisesInSuperset(newSchema: newSchema, routine: routine, superset: superset)
                                }
                            }
                        }
                    }
                }
                Button(action: {
                    self.newSchema.addSuperset(for: routine)
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
    
    @ObservedObject var newSchema: TrainingDataModel
    var routine: Routine
    var superset: Superset
    
    var body: some View{
        let supersetIndex: Int = newSchema.getSupersetIndex(for: routine, for: superset) + 1
        HStack{Text("Superset \(supersetIndex)").font(.headline).padding()
            
            Button (action: {
                newSchema.removeSuperset(for: superset, for: routine)
                
            }, label: {
                Image(systemName: "trash")
                    .foregroundColor(Color.init("textColor"))
                    .frame(width: 30, height: 30, alignment: .trailing)
            })
            
            
        }
    }
}

struct ExercisesInSuperset: View{
    
    @ObservedObject var newSchema: TrainingDataModel
    @ObservedObject var exerciseModel = ExerciseDataModel()
    var routine: Routine
    var superset: Superset
    @State var showExerciseSheetView: Bool = false
    
    var body: some View {
        
            let routineIndex: Int = newSchema.getRoutineIndex(for: routine)
            let supersetIndex: Int = newSchema.getSupersetIndex(for: routine, for: superset)
            
            if newSchema.schema.routines[routineIndex].superset != nil {
                if newSchema.schema.routines[routineIndex].superset![supersetIndex].exercises != nil {
                        ForEach(newSchema.schema.routines[routineIndex].superset![supersetIndex].exercises!){ exercise in
                            
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)){
                                
                                let repsProxy = Binding<String>(
                                    get: { String(exercise.reps ?? 0) },
                                    set: {
                                        if let value = NumberFormatter().number(from: $0) {
                                            self.newSchema.updateExerciseReps(for: routine, for: superset, for: exercise, to: value.intValue)
                                        }
                                    }
                                )
                                
                                HStack{
                                    Text("Reps: ")
                                        TextField("Reps", text: repsProxy)
                                            .frame(width: 60, height: 40)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                    Text(exercise.name).padding()
                                }
                            }
                        }.onDelete(perform:deleteExercise)
                        .onMove(perform: moveRow)
                }
            }
        Button(action:{
            self.showExerciseSheetView.toggle()
        }){
            HStack{
                Text("Selecteer oefeningen").foregroundColor(Color.init("textColor"))
            }
        }
        .sheet(isPresented: $showExerciseSheetView, content: {ExerciseSheetView(newSchema: newSchema, showExerciseSheetView: $showExerciseSheetView, routine: routine, superset: superset)})
    }

    func moveRow(source: IndexSet, destination: Int){
        print("I get here")
        self.newSchema.schema.routines[0].superset![0].exercises!.move(fromOffsets: source, toOffset: destination)
            }
        
    func deleteExercise(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.newSchema.removeExercise(for: routine, for: superset, for: index)
    }
}

struct ExerciseSheetView : View {
    
    @ObservedObject var newSchema: TrainingDataModel
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @Binding var showExerciseSheetView: Bool
    var routine: Routine
    var superset: Superset
    
    @State var selectedExercises: [Exercise]?
    @State var searchText = ""
    @State var searching = false
    @State var showAddExerciseSheetView = false
    
    init(newSchema: TrainingDataModel, showExerciseSheetView: Binding<Bool>, routine: Routine, superset: Superset, selectedExercises: [Exercise]? = [Exercise]()){
        self.newSchema = newSchema
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
                    return exercise.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
                }), id: \.self) { exercise in
                    SelectionCell(newSchema: newSchema, exercise: exercise, routine: routine, superset: superset, selectedExercises: self.$selectedExercises)
                }
            }
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
                            self.newSchema.updateExercises(for: routine, for: superset, with: selectedExercises!)
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
                self.selectedExercises = self.newSchema.getExercises(routine: routine, for: superset)
            })
        }
    }
}

struct SelectionCell: View {
    
    @ObservedObject var newSchema: TrainingDataModel
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
                    .foregroundColor(.accentColor)
                }
                else {
                    Image(systemName: "circle")
                        .foregroundColor(.accentColor)
                }
            }
            else {
                Image(systemName: "circle")
                    .foregroundColor(.accentColor)
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
    
    @ObservedObject var newSchema: TrainingDataModel
    var routine: Routine
    var superset: Superset
    
    @State var reps: String = ""
       @State var sets: String = ""
       
       var body: some View {
           
           
           let setsProxy = Binding<String>(
            get: { String(self.superset.sets ?? 0)},
               set: {
                   if let value = NumberFormatter().number(from: $0) {
                       self.newSchema.updateSets(for: routine, for: superset, to: value.intValue)
                   }
               }
           )
            
        VStack(alignment: .leading){
               HStack{
                   Text("Sets: ")
                   TextField("Sets", text: setsProxy)
                        .frame(width: 60, height: 40)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
               }
        }
    }
}
