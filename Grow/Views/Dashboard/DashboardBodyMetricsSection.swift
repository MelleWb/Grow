import SwiftUI

struct DashboardBodyMetricsSection: View {
    let bodyWeight: Double
    let fatPercentage: Double
    let stepsToday: Double?
    let activeEnergyBurnedToday: Double?
    let activeEnergyGoalToday: Double?
    
    private let stepGoal: Double = 10_000
    
    private var stepProgress: Double {
        min(max((stepsToday ?? 0) / stepGoal, 0), 1)
    }

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
            
            if let stepsToday {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Stappen")
                        Spacer()
                        Text("\(Int(stepsToday)) / 10000")
                            .font(.headline)
                            .monospacedDigit()
                    }
                    
                    //StepGoalProgress(progress: stepProgress)
                }
            }

            if let activeEnergyBurnedToday, let activeEnergyGoalToday {
                HStack {
                    Text("Verbrande kcal")
                    Spacer()
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: activeEnergyBurnedToday)) / \(NumberHelper.roundedNumbersFromDouble(unit: activeEnergyGoalToday))")
                        .font(.headline)
                        .monospacedDigit()
                }
            }
        }
    }
}

private struct StepGoalProgress: View {
    let progress: Double
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.accentColor.opacity(0.12))
            
            Capsule()
                .fill(Color.accentColor)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
        }
        .frame(height: 12)
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardBodyMetricsSection(
                bodyWeight: 82.4,
                fatPercentage: 14.2,
                stepsToday: 7342,
                activeEnergyBurnedToday: 540,
                activeEnergyGoalToday: 700
            )
        }
        .listStyle(.insetGrouped)
    }
}
