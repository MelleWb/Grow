import SwiftUI

struct FoodAddMealSection: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(systemName: "plus").foregroundColor(.accentColor)
                    Text("Voeg Maaltijd toe").foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    FoodPreviewContainer {
        List {
            Section {
                FoodAddMealSection(action: {})
            }
        }
        .listStyle(.grouped)
    }
}
