//
//  AddExercise.swift
//  Grow
//
//  Created by Swen Rolink on 30/06/2021.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ExerciseEditorView: View {
    let initialName: String
    let initialCategory: String
    let initialDescription: String
    let saveButtonTitle: String
    let onSave: (_ name: String, _ category: String, _ description: String) -> Void

    @State private var name: String
    @State private var description: String
    @State private var category: String

    private let categories = [
        "Hyrox",
        "Hardlopen",
        "Interval",
        "Rug",
        "Borst",
        "Biceps",
        "Triceps",
        "Schouders",
        "Quadriceps",
        "Hamstrings",
        "Billen",
        "Kuiten",
        "Buikspieren"
    ]

    init(
        initialName: String = "",
        initialCategory: String = "",
        initialDescription: String = "",
        saveButtonTitle: String,
        onSave: @escaping (_ name: String, _ category: String, _ description: String) -> Void
    ) {
        self.initialName = initialName
        self.initialCategory = initialCategory
        self.initialDescription = initialDescription
        self.saveButtonTitle = saveButtonTitle
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _category = State(initialValue: initialCategory)
        _description = State(initialValue: initialDescription)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Basis") {
                TextField("Naam", text: $name)

                Picker("Categorie", selection: $category) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }

            Section("Omschrijving") {
                TextField("Omschrijving", text: $description, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .toolbar {
            Button(saveButtonTitle) {
                onSave(
                    name.trimmingCharacters(in: .whitespacesAndNewlines),
                    category.trimmingCharacters(in: .whitespacesAndNewlines),
                    description.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .disabled(!canSave)
        }
    }
}

struct AddExercise: View {
    @EnvironmentObject private var userModel: UserDataModel
    @Binding var showAddExerciseSheetView: Bool

    var body: some View {
        NavigationView {
            ExerciseEditorView(saveButtonTitle: "Voeg toe") { name, category, description in
                let db = Firestore.firestore()
                let documentRef = db.collection("exercises").document()
                let ownerUserID = userModel.user.isAdmin ? nil : (userModel.user.id ?? Auth.auth().currentUser?.uid)
                let exercise = Exercise(
                    documentID: documentRef.documentID,
                    userID: ownerUserID,
                    name: name,
                    category: category,
                    description: description
                )

                do {
                    try documentRef.setData(from: exercise, merge: true)
                    self.showAddExerciseSheetView = false
                } catch {
                    print("Error adding document: \(error)")
                }
            }
            .navigationTitle("Oefening toevoegen")
        }
    }
}
