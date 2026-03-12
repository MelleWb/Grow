import SwiftUI

struct FoodSavedMealsSection: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.accentColor)
                    Text("Kies Maaltijd").foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    FoodPreviewContainer {
        List {
            Section {
                FoodSavedMealsSection(action: {})
            }
        }
        .listStyle(.grouped)
    }
}
