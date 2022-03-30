//
//  ExerciseOverview.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import SwiftUI
import UIKit
import Firebase

struct ChangeExercise: View {
    
    @ObservedObject var exerciseModel = ExerciseDataModel()
    @EnvironmentObject var trainingModel: TrainingDataModel
    @State var showAddExerciseSheetView = false
    @State var exerciseToChange: Exercise
    @Binding var showExerciseChange: Bool
    @State var superset: Superset
    @State var searchText = ""
    @State var searching = false
    
    func delete(at offsets: IndexSet) {
        
        let index = offsets[offsets.startIndex]
        let documentID = exerciseModel.exercises[index].documentID ?? ""
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        db.collection("exercises").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                exerciseModel.exercises.remove(atOffsets: offsets)
            }
        }
    }
    
    var body: some View{
            VStack(alignment: .leading){
                List {
                    SearchBar(searchText: $searchText, searching: $searching)
                    ForEach(exerciseModel.exercises.filter({ (exercise: Exercise) -> Bool in
                        return exercise.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
                    }), id: \.self) { exercise in
                        Button(action: {
                            trainingModel.changeExcercise(toExercise: exercise, forExercise: exerciseToChange, superset: superset)
                            self.showExerciseChange.toggle()
                            
                        },
                               label: {
                                VStack(alignment: .leading) {
                                    Text(exercise.name).font(.headline)
                                        .foregroundColor(Color.init("blackWhite"))
                                    Text(exercise.category).font(.subheadline)
                                        .foregroundColor(Color.init("blackWhite"))
                                }
                        })
                   }
                    
                   .onDelete(perform: delete)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Training")
            .onAppear(perform: {
                self.exerciseModel.fetchData()
            })
        .sheet(isPresented: $showAddExerciseSheetView) {
            AddExercise(showAddExerciseSheetView: $showAddExerciseSheetView)
        }
    }
}
