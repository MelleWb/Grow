//
//  TrainingVolumeView.swift
//  Grow
//
//  Created by Swen Rolink on 22/08/2021.
//

import SwiftUI
import Charts

struct TrainingVolumeView: View {
    @EnvironmentObject var statisticsModel: StatisticsDataModel

    private var routineStats: [RoutineStatistics] {
        (statisticsModel.schemaStatistics.routineStats ?? [])
            .filter { !$0.trainingStats.isEmpty }
            .sorted { $0.type < $1.type }
    }

    var body: some View {
        List {
            if routineStats.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Nog geen volumegegevens",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Rond eerst een paar trainingen af om volume per trainingsdag te zien.")
                    )
                }
            } else {
                ForEach(routineStats, id: \.id) { routineStats in
                    Section {
                        RoutineVolumeCard(routineStats: routineStats)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text("Volume per training"))
    }
}

private struct RoutineVolumeCard: View {
    let routineStats: RoutineStatistics

    private var sortedTrainingStats: [TrainingStatistics] {
        routineStats.trainingStats.sorted { $0.trainingDate < $1.trainingDate }
    }

    private var bestVolume: Double {
        sortedTrainingStats.map(\.trainingVolume).max() ?? 0
    }

    private var averageVolume: Double {
        guard !sortedTrainingStats.isEmpty else {
            return 0
        }

        let total = sortedTrainingStats.reduce(0) { partialResult, training in
            partialResult + training.trainingVolume
        }

        return total / Double(sortedTrainingStats.count)
    }

    private var latestVolume: Double {
        sortedTrainingStats.last?.trainingVolume ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(routineStats.type)
                .font(.headline)
                .foregroundColor(.accentColor)

            HStack(spacing: 12) {
                VolumeMetric(title: "Laatste", value: "\(Int(latestVolume)) kg")
                VolumeMetric(title: "Gemiddeld", value: "\(Int(averageVolume)) kg")
                VolumeMetric(title: "Beste", value: "\(Int(bestVolume)) kg")
            }

            Chart(Array(sortedTrainingStats.enumerated()), id: \.element.id) { index, training in
                AreaMark(
                    x: .value("Training", index + 1),
                    y: .value("Volume", training.trainingVolume)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Training", index + 1),
                    y: .value("Volume", training.trainingVolume)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Training", index + 1),
                    y: .value("Volume", training.trainingVolume)
                )
                .foregroundStyle(Color.accentColor)
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: Array(1...sortedTrainingStats.count)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let trainingIndex = value.as(Int.self) {
                            Text("#\(trainingIndex)")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recente trainingen")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(sortedTrainingStats.suffix(3).reversed()), id: \.id) { training in
                    HStack {
                        Text(training.trainingDate, style: .date)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(training.trainingVolume)) kg")
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct VolumeMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrainingVolumeView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingVolumeView()
    }
}
