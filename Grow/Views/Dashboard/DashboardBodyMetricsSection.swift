import SwiftUI

struct DashboardBodyMetricsSection: View {
    let bodyWeight: Double
    let fatPercentage: Double

    var body: some View {
        Section {
            if bodyWeight != 0 {
                HStack {
                    Text("Gewicht")
                    Spacer()
                    Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: bodyWeight)) kg")
                        .font(.headline)
                }

                if fatPercentage != 0 {
                    HStack {
                        Text("Vet percentage")
                        Spacer()
                        Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: fatPercentage)) %")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardBodyMetricsSection(bodyWeight: 82.4, fatPercentage: 14.2)
        }
        .listStyle(.insetGrouped)
    }
}
