//
//  AddRoutine.swift
//  Grow
//
//  Created by Swen Rolink on 06/07/2021.
//

import SwiftUI

struct AddSchema: View{
    
    @Environment(\.presentationMode) private var presentationMode
    @State var showAddRoutine: Bool = false
    @ObservedObject var schemaModel = TrainingDataModel()

    
    var body: some View{
        NavigationView{
            VStack{
                
            NavigationLink(
                destination: AddRoutine().environmentObject(schemaModel),
                        isActive: $showAddRoutine
                    ) {
                AddRoutine().environmentObject(schemaModel)
            }.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
                
            Form{
                    
                TextField("Naam van het schema", text: $schemaModel.schema.name)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.init(top: 20, leading: 20, bottom: 15, trailing: 20))
            
            Text("Geef het een naam waardoor het goed vindbaar wordt")
                .font(.caption)
                .padding(.init(top: 0, leading: 0, bottom: 10, trailing: 0))
                .frame(alignment: .leading)
            
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
                        if !(schemaModel.schema.routines ?? []).isEmpty {
                        ForEach(schemaModel.schema.routines!) { routine in
                            
                            NavigationLink(destination: AddRoutine(routine: routine).environmentObject(schemaModel)){
                                    VStack{
                                        Text(routine.type!).font(.headline)
                                        }
                                }
                            }
                        }
                                Button(action: {
                                    self.showAddRoutine = true
                                    let newRoutine: Routine = Routine()
                                    self.schemaModel.schema.routines?.append(newRoutine)
                                }) {
                                    HStack{
                                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                                        Text("Voeg training toe").foregroundColor(Color.init("textColor"))
                                    }
                                }
                        }
                    }
                }
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
                                presentationMode.wrappedValue.dismiss()
                           }) {
                            Text("Opslaan").bold()
                           }
                    )
        .environmentObject(schemaModel)
    }
    }


struct AddRoutine : View{
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    //@ObservedObject var exerciseModel = ExerciseDataModel()
    var routine: Routine?
    var routineIndex: Int?
    
    init(routine: Routine = Routine(), routineIndex: Int? = 0){
        if self.routine == nil {
            self.routine = routine
            self.routineIndex = schemaModel.schema.routines!.firstIndex(where: {$0.id == routine.id})!
        }
        else {
            let routineID: UUID = self.routine!.id
            self.routineIndex = schemaModel.schema.routines!.firstIndex(where: {$0.id == routineID})!
        }
    }

    
    var body: some View{
        
        let typeBinding = Binding(
            get: { self.schemaModel.schema.routines![routineIndex!].type },
            set: { self.schemaModel.schema.routines![routineIndex!].type = $0 }
        )
        
            VStack{
                Form{
                    Picker(selection: typeBinding, label: Text("Trainingstype")) {
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
                    .pickerStyle(DefaultPickerStyle())
                    
                    if !(routine?.superset ?? []).isEmpty {
                        ForEach(routine!.superset!){ superset in
                            //Do something
                        }
                    }

                /*
                        ForEach(Array(routine.superset.enumerated()), id: \.1) { supersetIndex, superset in
                            Section(header:
                                        
                                        HStack{Text("Superset \(supersetIndex + 1)").font(.headline).padding()
                                            
                                            
                                            Button (action: {
                                                self.schemaModel.schema.routines[routineIndex].superset.remove(at: supersetIndex)

                                                
                                            }, label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(Color.init("textColor"))
                                                    .frame(width: 30, height: 30, alignment: .trailing)
                                            })
                                            
                                            
                                        }

                            ){
                                    
                                SetsAndReps(superset: $schemaModel.schema.routines[routineIndex].superset[supersetIndex])
                                
                                List{
                                    ForEach(Array(superset.exercise.enumerated()), id: \.1) { exerciseIndex, exercise in
                                        
                                        AddExerciseToSuperset(exerciseName: $schemaModel.schema.routines[routineIndex].superset[supersetIndex].exercise[exerciseIndex].name)
                                    }
                                    Button(action:{
                                        
                                        let newExercise: ExerciseInfo = ExerciseInfo()
                                        self.schemaModel.schema.routines[routineIndex].superset[supersetIndex].exercise.append(newExercise)
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
                Button(action: {
                    let newSuperset: Superset = Superset()
                    self.schemaModel.schemas[schemaIndex].routines[routineIndex].superset.append(newSuperset)
                    self.supersetIndex = self.schemaModel.schemas[schemaIndex].routines[routineIndex].superset.endIndex - 1
                }) {
                    HStack{
                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                        Text("Voeg superset toe").foregroundColor(Color.init("textColor"))
                    }
                }
            }.onAppear(perform: {
                exerciseModel.fetchData()
            })*/
                }
            }
    }
}

struct AddExerciseToSuperset: View {
    
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @State var presentPicker = false
    @State var tag: Int = 1
    @Binding var exerciseName: String
    
    var body: some View {
        Text("Oops")
    }
}

struct SetsAndReps : View {
    
    @Binding var superset: Superset
    
    var body: some View {
        
        let setsProxy = Binding<String>(
            get: { String(Int(self.superset.sets)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.superset.sets = value.intValue
                }
            }
        )
        let repsProxy = Binding<String>(
            get: { String(Int(self.superset.reprange)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.superset.reprange = value.intValue
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
