import SwiftUI

struct DashboardMeasurementSection: View {
    @Binding var showMeasurementView: Bool

    var body: some View {
        Section {
            HStack {
                Button {
                    showMeasurementView = true
                } label: {
                    HStack {
                        Image(systemName: "alarm")
                            .foregroundColor(.accentColor)
                        Text("Tijd voor een nieuwe meting")
                            .font(.subheadline)
                            .foregroundColor(Color.init("blackWhite"))
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardMeasurementSection(showMeasurementView: .constant(false))
        }
        .listStyle(.insetGrouped)
    }
}
