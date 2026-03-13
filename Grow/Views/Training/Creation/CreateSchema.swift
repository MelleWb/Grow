//
//  CreateSchema.swift
//  Grow
//
//  Created by Swen Rolink on 28/01/2022.
//

import SwiftUI

struct CreateSchema: View{
    @EnvironmentObject var trainingModel: TrainingDataModel
    @Environment(\.presentationMode) private var presentationMode
    @State var schema = Schema()
    @State var selectedRoutine: UUID? = nil
    
    private let schemaTypes = ["Strength", "Hypertrofie", "Cardio", "Hyrox"]
    
    private var canSaveSchema: Bool {
        !schema.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !schema.routines.isEmpty
    }
    
    var body: some View{
        
        Form{
            Section("Schema details") {
                Picker("Doel", selection: $schema.type) {
                    ForEach(schemaTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Naam van het schema", text: $schema.name)
            }
            
            Section("Trainingen") {
                if schema.routines.isEmpty {
                    ContentUnavailableView(
                        "Nog geen trainingen",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Voeg eerst een training toe en werk daarna de sets en oefeningen uit.")
                    )
                } else {
                    ForEach($schema.routines) { $routine in
                        Button {
                            selectedRoutine = routine.id
                        } label: {
                            RoutineSummaryRow(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteRoutine)
                }
                
                Button {
                    self.schema.routines.append(Routine(type: "Upper 1", superset: [Superset(sets: 3)]))
                } label: {
                    Label("Voeg training toe", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationBarTitle(Text("Schema"), displayMode: .inline)
        .navigationDestination(item: $selectedRoutine) { routineID in
            if let index = schema.routines.firstIndex(where: { $0.id == routineID }) {
                CreateRoutine(selectedRoutine: $selectedRoutine, routine: $schema.routines[index])
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let success: Bool = self.trainingModel.createTraining(schema: self.schema)
                    if success{
                        presentationMode.wrappedValue.dismiss()
                    }
                    else{
                        print("some error")
                    }
                }) {
                    Text("Voeg toe").bold()
                }
                .disabled(!canSaveSchema)
            }
        }
    }
    func deleteRoutine(indexSet: IndexSet) {
        self.schema.routines.remove(atOffsets: indexSet)
    }
}

struct CreateRoutine : View{
    
    @Binding var selectedRoutine: UUID?
    @Binding var routine: Routine
    @State var selectedSuperset: UUID? = nil
    
    let routineArray = ["Upper 1","Upper 2","Upper 3","Lower 1","Lower 2","Lower 3","Full Body 1","Full Body 2","Full Body 3","Push 1","Push 2","Push 3","Pull 1","Pull 2","Pull 3", "Hyrox", "Cardio"]
    
    var body: some View{
        Form{
            Section("Trainingstype") {
                Picker("Training", selection: $routine.type) {
                    ForEach(routineArray, id:\.self) { routine in
                        Text(routine).tag(routine)
                    }
                }
            }
            
            Section("Blokken") {
                if routine.superset.isEmpty {
                    ContentUnavailableView(
                        "Nog geen blokken",
                        systemImage: "square.stack.3d.up",
                        description: Text("Voeg een blok toe en kies daarna sets, oefeningen en herhalingen.")
                    )
                } else {
                    ForEach($routine.superset){ $set in
                        Button {
                            selectedSuperset = set.id
                        } label: {
                            SupersetSummaryRow(superset: set)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        self.routine.superset.remove(atOffsets: indexSet)
                    }
                }
                
                Button(action: {
                    self.routine.superset.append(Superset(sets: 3))
                }) {
                    Label("Voeg blok toe", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationDestination(item: $selectedSuperset) { supersetID in
            if let index = routine.superset.firstIndex(where: { $0.id == supersetID }) {
                AddSuperSet(superSet: $routine.superset[index], selectedSuperset: $selectedSuperset)
            }
        }
    }
}

struct AddSuperSet: View {
    @Binding var superSet: Superset
    @Binding var selectedSuperset: UUID?
    @State var selectedExercise: UUID? = nil
    @State var showAddExercise: Bool = false
    @State var isRepsSheetEnabled: Bool = false
    
    var body: some View {
        Form {
            Section("Sets") {
                Stepper("Aantal sets: \(self.superSet.sets)", value: $superSet.sets, in: 1...10)
            }
            
            Section("Oefeningen") {
                if superSet.exercises.isEmpty {
                    ContentUnavailableView(
                        "Nog geen oefeningen",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Kies een of meer oefeningen voor dit blok.")
                    )
                } else {
                    ForEach($superSet.exercises) { $exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.headline)
                            Picker("Herhalingen", selection: $exercise.reps) {
                                ForEach(1..<50) {
                                   if $0 > 1 {
                                       Text("\($0) reps")
                                   } else {
                                       Text("1 rep")
                                   }
                               }
                           }
                           .pickerStyle(.menu)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button {
                    showAddExercise = true
                } label: {
                    Label("Kies oefeningen", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Superset")
        .navigationDestination(isPresented: $showAddExercise) {
            AddExerciseToRoutine(showAddExercise: $showAddExercise, exercises: $superSet.exercises)
        }
        .blur(radius: isRepsSheetEnabled ? 1 : 0)
        .overlay(isRepsSheetEnabled ? Color.black.opacity(0.6) : nil)
    }
}

struct AddExerciseToRoutine: View {
    
    @StateObject private var exerciseModel = ExerciseDataModel()
    @State var showAddExerciseSheetView = false
    @State var searchText = ""
    @State var searching = false
    @Binding var showAddExercise: Bool
    @Binding var exercises: [Exercise]
    
    private var filteredExercises: [Exercise] {
        exerciseModel.exercises.filter { exercise in
            let matchesSearch = exercise.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
            let isAlreadySelected = exercises.contains(where: { $0.documentID == exercise.documentID })
            return matchesSearch && !isAlreadySelected
        }
    }
    
    var body: some View{
            List {
                SearchBar(searchText: $searchText, searching: $searching)
                
                Section("Geselecteerd") {
                    if exercises.isEmpty {
                        Text("Nog geen oefeningen gekozen")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(exercises.count) oefening\(exercises.count == 1 ? "" : "en") geselecteerd")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ForEach(exercises, id: \.id) { exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                Text(exercise.category)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeExercise(exercise)
                                } label: {
                                    Label("Verwijder", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section("Beschikbare oefeningen") {
                    if filteredExercises.isEmpty {
                        ContentUnavailableView(
                            "Geen oefeningen gevonden",
                            systemImage: "magnifyingglass",
                            description: Text("Probeer een andere zoekterm of voeg een nieuwe oefening toe.")
                        )
                    } else {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            SelectExerciseCell(selectedExercises: $exercises, exercise: exercise)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Oefeningen")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            self.showAddExerciseSheetView.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    
                    Button("Klaar") {
                        showAddExercise = false
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

    private func removeExercise(_ exercise: Exercise) {
        if let index = exercises.firstIndex(where: { $0.documentID == exercise.documentID }) {
            exercises.remove(at: index)
        }
    }
}

struct SelectExerciseCell: View {
    
    @Binding var selectedExercises: [Exercise]
    @State var exercise: Exercise

    var body: some View {
        Button {
            if selectedExercises.firstIndex(where: { $0.documentID == exercise.documentID}) == nil {
                self.selectedExercises.append(exercise)
            }
        }
        label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .foregroundColor(.primary)
                    Text(exercise.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RoutineSummaryRow: View {
    let routine: Routine
    
    private var exerciseCount: Int {
        routine.superset.reduce(0) { $0 + $1.exercises.count }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.type)
                    .font(.headline)
                Text("\(routine.superset.count) blokken • \(exerciseCount) oefeningen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct SupersetSummaryRow: View {
    let superset: Superset
    
    private var title: String {
        superset.exercises.count > 1 ? "Superset" : "Set"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(superset.sets)x")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                if superset.exercises.isEmpty {
                    Text("Nog niet geconfigureerd")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(superset.exercises.prefix(3), id: \.id) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Text("\(exercise.reps) reps")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                    if superset.exercises.count > 3 {
                        Text("+\(superset.exercises.count - 3) meer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
