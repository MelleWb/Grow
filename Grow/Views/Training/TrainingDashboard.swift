//
//  AddTraining.swift
//  Grow
//
//  Created by Swen Rolink on 04/07/2021.
//

import SwiftUI
import FirebaseFirestore

struct TrainingDashboardView : View {
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State private var showTrainingDaySelection = false
    
    var body: some View {
        
        NavigationStack{
            VStack{
                List{
                    Section(header:Text("Statistieken")){
                        NavigationLink(destination: ExerciseOverview()){
                            HStack{
                                Image(systemName: "list.bullet").foregroundColor(.accentColor)
                                Text("Statistieken per oefening").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingVolumeView()){
                            HStack{
                                Image(systemName: "chart.bar").foregroundColor(.accentColor)
                                Text("Trainingsvolume progressie").font(.subheadline)
                            }
                        }
                        NavigationLink(destination: TrainingHistoryOverview()){
                            HStack{
                                Image(systemName: "clock.arrow.circlepath").foregroundColor(.accentColor)
                                Text("Traininghistorie").font(.subheadline)
                            }
                        }
                    }
                    Section(header:Text("Trainingsschema's")){
                        NavigationLink(destination: TrainingOverview()){
                            HStack{
                                Image(systemName: "square.and.pencil").foregroundColor(.accentColor)
                                Text("Bekijk of maak trainingsschema's").font(.subheadline)
                            }
                        }
                    }
                    Section(header:Text("Trainingsdagen")){
                        Button {
                            showTrainingDaySelection = true
                        } label: {
                            HStack{
                                Image(systemName: "calendar").foregroundColor(.accentColor)
                                Text("Selecteer je trainingsdagen")
                                    .font(.subheadline)
                                    .foregroundColor(Color.init("blackWhite"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Trainingen"))
            .sheet(isPresented: $showTrainingDaySelection) {
                TrainingDaySelectionView()
                    .environmentObject(userModel)
            }
        }
    }
}

struct TrainingOverview: View {
    
    @State private var showCreateSchema = false
    @State private var searchText = ""
    @EnvironmentObject var trainingModel: TrainingDataModel

    private var filteredSchemas: [Schema] {
        trainingModel.fetchedSchemas
            .filter { schema in
                schema.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
            }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Schema zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Beschikbare schema's") {
                if filteredSchemas.isEmpty {
                    ContentUnavailableView(
                        "Geen schema's gevonden",
                        systemImage: "magnifyingglass",
                        description: Text("Pas je zoekterm aan of maak een nieuw schema aan.")
                    )
                } else {
                    ForEach(filteredSchemas, id: \.self) { schema in
                        NavigationLink(destination: ReviewSchema(newSchema: trainingModel, schema: schema)) {
                            Text(schema.name)
                        }
                    }
                    .onDelete(perform: deleteSchema)
                }
            }
        }

        .listStyle(.insetGrouped)
        .navigationBarTitle(Text("Schemas"), displayMode: .inline)
        .navigationDestination(isPresented: $showCreateSchema) {
            CreateSchema()
        }
        .navigationBarItems(trailing:
               Button(action: {
                    self.showCreateSchema = true
               }) {
                   Image(systemName: "plus")
               }
           )
    }
    func deleteSchema(at offsets: IndexSet){
        let index = offsets[offsets.startIndex]
        let schemaToDelete = filteredSchemas[index]
        
        let documentID = schemaToDelete.docID ?? ""
        
        let db = Firestore.firestore()
        
        db.collection("schemas").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                self.trainingModel.fetchedSchemas.removeAll { $0.id == schemaToDelete.id }
            }
        }
    }
}

struct ProgressBarVertical: View {
    var value: Float
    var label: String

    private var barHeight: CGFloat {
        let sanitizedValue = value.isFinite ? max(0, value) : 0
        return CGFloat(sanitizedValue) * 75
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Spacer()
                if value <= 0.98 {
                Rectangle()
                    .frame(width: 15, height: barHeight)
                    .foregroundColor(Color.orange)
                    .animation(Animation.linear(duration: 0.5), value: value)
                    .cornerRadius(45.0)
                    .offset(x: 10)
                }
                else {
                    Rectangle()
                        .frame(width: 15, height: barHeight)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
                        .cornerRadius(45.0)
                        .offset(x: 10)
                }
            Text(label)
                .foregroundColor(.accentColor)
                .font(.footnote)
                .frame(height: 20)
        }
    }
}
