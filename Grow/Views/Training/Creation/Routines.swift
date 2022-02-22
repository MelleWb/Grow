//
//  AddRoutine.swift
//  Grow
//
//  Created by Swen Rolink on 06/07/2021.
//
import SwiftUI
import Firebase

struct ReviewSchema: View{
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var newSchema: TrainingDataModel
    @State var schema: Schema
    @State var selectedRoutine: UUID? = nil
    
    func deleteRoutine(indexSet: IndexSet) {
        self.schema.routines.remove(atOffsets: indexSet)
    }
    
    var body: some View {
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
        .navigationBarItems(
            trailing:
                Button(action: {
                    self.newSchema.updateTraining(schema: schema)
                    presentationMode.wrappedValue.dismiss()
                   }) {
                      Text("Opslaan")
                   })
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
            get: { String(self.superset.sets)},
               set: {
                   if let value = NumberFormatter().number(from: $0) {
                       //self.newSchema.updateSets(for: routine, for: superset, to: value.intValue)
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
