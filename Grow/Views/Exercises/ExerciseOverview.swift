//
//  ExerciseOverview.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import SwiftUI
import UIKit
import Firebase

struct ExerciseOverview: View {
    
    @ObservedObject var exerciseModel = ExerciseDataModel()
    
    @State var showAddExerciseSheetView = false
    @State var searchText = ""
    @State var searching = false
    
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
            VStack(alignment: .leading){
                List {
                    SearchBar(searchText: $searchText, searching: $searching)
                    ForEach(exerciseModel.exercises.filter({ (exercise: Exercise) -> Bool in
                        return exercise.name.hasPrefix(searchText) || searchText == ""
                    }), id: \.self) { exercise in
                        NavigationLink( destination: ExerciseDetailView(exercise: exercise)) {
                                    VStack(alignment: .leading) {
                                        Text(exercise.name).font(.headline)
                                        Text(exercise.category).font(.subheadline)
                                    }
                        }
                   }
                    
                   .onDelete(perform: delete)
            }/*.gesture(DragGesture()
                        .onChanged({ _ in
                            UIApplication.shared.dismissKeyboard()
                        })
            )*/
            }.onAppear(perform: exerciseModel.fetchData)
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

extension UIApplication {
      func dismissKeyboard() {
          sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      }
  }
