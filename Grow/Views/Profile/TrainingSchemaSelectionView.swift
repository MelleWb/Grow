import SwiftUI

struct TrainingSchemaSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    
    @State private var searchTerm = ""
    
    private var filteredSchemas: [Schema] {
        if searchTerm.isEmpty {
            return trainingModel.fetchedSchemas
        }
        
        return trainingModel.fetchedSchemas.filter { schema in
            schema.name.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchTerm, placeholder: "Schema zoeken")
                    .listRowInsets(EdgeInsets())
            }
            
            Section("Beschikbare schema's") {
                if filteredSchemas.isEmpty {
                    ContentUnavailableView(
                        "Geen schema's gevonden",
                        systemImage: "magnifyingglass",
                        description: Text("Pas je zoekterm aan of maak eerst een schema aan.")
                    )
                } else {
                    ForEach(Array(filteredSchemas.enumerated()), id: \.offset) { _, schema in
                        SchemaSelectionRow(
                            schema: schema,
                            isSelected: userModel.user.schema == schema.docID,
                            action: { selectSchema(schema) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Trainingschema")
    }
    
    private func selectSchema(_ schema: Schema) {
        guard let schemaID = schema.docID else {
            return
        }
        
        userModel.stageWorkoutSchemaChange(to: schemaID)
        dismiss()
    }
}

private struct SchemaSelectionRow: View {
    let schema: Schema
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schema.name)
                        .foregroundColor(.primary)
                    if !schema.type.isEmpty {
                        Text(schema.type)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TrainingSchemaSelectionView()
            .environmentObject(UserDataModel(autostart: false, runStartupSideEffects: false))
            .environmentObject(TrainingDataModel(autostart: false, runStartupSideEffects: false))
    }
}
