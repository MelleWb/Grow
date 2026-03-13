//
//  ExerciseOverview.swift
//  Grow
//
//  Created by Swen Rolink on 29/06/2021.
//

import SwiftUI
import UIKit
import FirebaseFirestore

struct ExerciseOverview: View {
    
    @StateObject private var exerciseModel = ExerciseDataModel()
    
    @State private var showAddExerciseSheetView = false
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        exerciseModel.exercises
            .filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
            }
            .sorted { $0.name < $1.name }
    }
    
    func delete(at offsets: IndexSet) {
        
        let index = offsets[offsets.startIndex]
        let exerciseToDelete = filteredExercises[index]
        let documentID = exerciseToDelete.documentID ?? ""
        
        let db = Firestore.firestore()
        
        db.collection("exercises").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                exerciseModel.exercises.removeAll { $0.id == exerciseToDelete.id }
            }
        }
    }
    
    var body: some View{
            List {
                Section {
                    PickerSearchBar(text: $searchText, placeholder: "Oefening zoeken")
                        .listRowInsets(EdgeInsets())
                }

                Section("Beschikbare oefeningen") {
                    if filteredExercises.isEmpty {
                        ContentUnavailableView(
                            "Geen oefeningen gevonden",
                            systemImage: "magnifyingglass",
                            description: Text("Pas je zoekterm aan of voeg een nieuwe oefening toe.")
                        )
                    } else {
                        ForEach(filteredExercises, id: \.self) { exercise in
                        NavigationLink( destination: ExerciseDetailView(exercise: exercise)) {
                                    VStack(alignment: .leading) {
                                        Text(exercise.name).font(.headline)
                                        Text(exercise.category).font(.subheadline)
                                    }
                        }
            }
                        .onDelete(perform: delete)
                    }
                }
        }
            .onAppear(perform: {
                self.exerciseModel.fetchData()
            })
            .listStyle(.insetGrouped)
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
