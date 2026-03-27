//
//  ManageExercisesView.swift
//  Grow
//
//  Created by OpenAI on 10/10/2025.
//

import SwiftUI
import FirebaseFirestore

struct ManageExercisesView: View {
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

    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Oefening zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Oefeningen") {
                if filteredExercises.isEmpty {
                    ContentUnavailableView(
                        "Geen oefeningen gevonden",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Pas je zoekterm aan of voeg een nieuwe oefening toe.")
                    )
                } else {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        NavigationLink(destination: ManageExerciseDetailView(exercise: exercise)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                Text(exercise.category)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Oefeningen")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddExerciseSheetView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddExerciseSheetView) {
            AddExercise(showAddExerciseSheetView: $showAddExerciseSheetView)
        }
        .onAppear {
            exerciseModel.fetchData()
        }
    }
}

struct ManageExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var isSaving = false
    @State private var isDeleting = false

    var body: some View {
        ExerciseEditorView(
            initialName: exercise.name,
            initialCategory: exercise.category,
            initialDescription: exercise.description ?? "",
            saveButtonTitle: isSaving ? "Opslaan..." : "Opslaan"
        ) { name, category, description in
            save(name: name, category: category, description: description)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Verwijder oefening", role: .destructive, action: deleteExercise)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(exercise.documentID == nil || isSaving || isDeleting)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
        }
    }

    private func save(name: String, category: String, description: String) {
        guard let documentID = exercise.documentID else {
            return
        }

        isSaving = true

        Firestore.firestore()
            .collection("exercises")
            .document(documentID)
            .updateData([
                "name": name,
                "category": category,
                "description": description
            ]) { error in
                isSaving = false

                if let error {
                    print("Error updating exercise: \(error)")
                    return
                }

                dismiss()
            }
    }

    private func deleteExercise() {
        guard let documentID = exercise.documentID else {
            return
        }

        isDeleting = true

        Firestore.firestore()
            .collection("exercises")
            .document(documentID)
            .delete { error in
                isDeleting = false

                if let error {
                    print("Error removing exercise: \(error)")
                    return
                }

                dismiss()
            }
    }
}
