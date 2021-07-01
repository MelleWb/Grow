//
//  ExerciseOverview.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import SwiftUI
import Firebase

struct ExerciseOverview: View {
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @State var showAddExerciseSheetView = false
    
    func delete(at offsets: IndexSet) {
        
        let index = offsets[offsets.startIndex]
        let documentID = exerciseModel.exercises[index].documentID
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        db.collection("exercises").document(documentID!).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                exerciseModel.exercises.remove(atOffsets: offsets)
            }
        }
    }
    
    var body: some View{
        NavigationView{
            
            List {
                           ForEach(exerciseModel.exercises, id: \.self) { exercise in
                                NavigationLink( destination: ExerciseDetailView(exercise: exercise)) {
                                            VStack(alignment: .leading) {
                                                Text(exercise.name).font(.title)
                                                Text(exercise.category).font(.subheadline)
                                            }
                                }
                           }
                           .onDelete(perform: delete)
                       }
            
            }.onAppear(perform: exerciseModel.fetchData)
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationTitle("Oefeningen overzicht")
            .navigationBarItems(trailing: (
                            Button(action: {
                                withAnimation {
                                    self.showAddExerciseSheetView.toggle()
                                }
                            }) {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 25, height: 25, alignment: .center)
                            })
                        )
        .sheet(isPresented: $showAddExerciseSheetView) {
            AddExercise(showAddExerciseSheetView: $showAddExerciseSheetView, name: "", description: "", category: "")
        }
    }
}

struct ExerciseOverview_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseOverview()
    }
}
