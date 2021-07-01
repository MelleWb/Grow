//
//  AddExercise.swift
//  Grow
//
//  Created by Swen Rolink on 30/06/2021.
//

import SwiftUI
import Firebase

struct AddExercise: View {
    
    @Binding var showAddExerciseSheetView: Bool
    @State var name: String
    @State var description: String
    @State var category: String
    
    func hasEmtpyFields() -> Bool {
        if self.name.isEmpty || self.category.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        
        NavigationView {
            Form {
                    Section {
                        TextField("Naam", text: $name).padding()
                    }
                    Section{
                        
                        Picker(selection: $category, label: Text("Categorie")) {
                            Text("Rug").tag("Rug")
                            Text("Borst").tag("Borst")
                            Text("Biceps").tag("Biceps")
                            Text("Triceps").tag("Triceps")
                            Text("Schouders").tag("Schouders")
                            Text("Quadriceps").tag("Quadriceps")
                            Text("Hamstrings").tag("Hamstrings")
                            Text("Kuiten").tag("Kuiten")
                            Text("Buikspieren").tag("Buikspieren")
                        }.padding()
                    }
                    Section{
                        TextField("Omschrijving", text: $description).padding()
                    }
                }.navigationBarItems(trailing: Button(action: {
                    if hasEmtpyFields() {
                        // Say something
                    } else {
                        
                        let settings = FirestoreSettings()
                        settings.isPersistenceEnabled = true
                        let db = Firestore.firestore()
                        
                        var ref: DocumentReference? = nil
                        ref = db.collection("exercises").addDocument(data: [
                            "name": self.name,
                            "category": self.category,
                            "description": self.description
                        ]) { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            } else {
                                self.showAddExerciseSheetView = false
                            }
                        }
                    }
                }) {
                    Text("Voeg toe").bold().disabled(hasEmtpyFields())

                   })
        }
    }
}
