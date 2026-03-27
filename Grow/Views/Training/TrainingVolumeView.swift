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
        .navigationTitle(Text("Trainingsprogressie"))
    }
}

private struct RoutineVolumeCard: View {
    let routineStats: RoutineStatistics

    private var sortedTrainingStats: [TrainingStatistics] {
        routineStats.trainingStats.sorted { $0.trainingDate < $1.trainingDate }
    }

    private var isCardioRoutine: Bool {
        routineStats.type == "Cardio"
    }

    private var isHyroxRoutine: Bool {
        routineStats.type == "Hyrox"
    }

    private var chartValues: [Double] {
        sortedTrainingStats.map(metricValue(for:))
    }

    private var distanceValues: [Double] {
        sortedTrainingStats.map(totalDistance(for:))
    }

    private var bestVolume: Double {
        chartValues.max() ?? 0
    }

    private var averageVolume: Double {
        guard !chartValues.isEmpty else {
            return 0
        }

        let total = chartValues.reduce(0, +)

        return total / Double(chartValues.count)
    }

    private var latestVolume: Double {
        sortedTrainingStats.last.map(metricValue(for:)) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(routineStats.type)
                .font(.headline)
                .foregroundColor(.accentColor)

            if isCardioRoutine || isHyroxRoutine {
                HStack(spacing: 12) {
                    VolumeMetric(title: "Laatste tijd", value: metricLabel(for: latestVolume))
                    VolumeMetric(title: "Gemiddelde tijd", value: metricLabel(for: averageVolume))
                    if isCardioRoutine {
                        VolumeMetric(title: "Afstand", value: distanceLabel(for: latestDistance))
                    } else {
                        VolumeMetric(title: "Beste tijd", value: metricLabel(for: bestVolume))
                    }
                }

                Chart(Array(sortedTrainingStats.enumerated()), id: \.element.id) { index, training in
                    AreaMark(
                        x: .value("Training", index + 1),
                        y: .value("Tijd", metricValue(for: training))
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
                        y: .value("Tijd", metricValue(for: training))
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Training", index + 1),
                        y: .value("Tijd", metricValue(for: training))
                    )
                    .foregroundStyle(Color.accentColor)

                    if isCardioRoutine {
                        BarMark(
                            x: .value("Training", index + 1),
                            y: .value("Afstand", totalDistance(for: training))
                        )
                        .foregroundStyle(Color.orange.opacity(0.35))
                    }
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
            } else {
                HStack(spacing: 12) {
                    VolumeMetric(title: "Laatste", value: metricLabel(for: latestVolume))
                    VolumeMetric(title: "Gemiddeld", value: metricLabel(for: averageVolume))
                    VolumeMetric(title: "Beste", value: metricLabel(for: bestVolume))
                }

                Chart(Array(sortedTrainingStats.enumerated()), id: \.element.id) { index, training in
                    AreaMark(
                        x: .value("Training", index + 1),
                        y: .value("Volume", metricValue(for: training))
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
                        y: .value("Volume", metricValue(for: training))
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Training", index + 1),
                        y: .value("Volume", metricValue(for: training))
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
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recente trainingen")
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(sortedTrainingStats.suffix(3).reversed()), id: \.id) { training in
                    HStack {
                        Text(training.trainingDate, style: .date)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(recentTrainingLabel(for: training))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var yAxisTitle: String {
        if isCardioRoutine {
            return "Tijd"
        }

        if isHyroxRoutine {
            return "Minuten"
        }

        return "Volume"
    }

    private func metricValue(for training: TrainingStatistics) -> Double {
        if isCardioRoutine {
            return Double(totalDurationSeconds(for: training)) / 60
        }

        if isHyroxRoutine {
            return Double(totalDurationSeconds(for: training)) / 60
        }

        return training.trainingVolume
    }

    private func metricLabel(for value: Double) -> String {
        if isCardioRoutine || isHyroxRoutine {
            return "\(Int(value)) min"
        }

        return "\(Int(value)) kg"
    }

    private var latestDistance: Double {
        sortedTrainingStats.last.map(totalDistance(for:)) ?? 0
    }

    private func distanceLabel(for value: Double) -> String {
        "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: value)) km"
    }

    private func recentTrainingLabel(for training: TrainingStatistics) -> String {
        if isCardioRoutine {
            let distance = totalDistance(for: training)
            let duration = totalDurationSeconds(for: training)
            if distance > 0 {
                return "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: distance)) km • \(formattedDuration(duration))"
            }
            return formattedDuration(duration)
        }

        if isHyroxRoutine {
            return formattedDuration(totalDurationSeconds(for: training))
        }

        return "\(Int(training.trainingVolume)) kg"
    }

    private func totalDurationSeconds(for training: TrainingStatistics) -> Int {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private func totalDistance(for training: TrainingStatistics) -> Double {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.distanceKilometers ?? 0) }
    }

    private func formattedDuration(_ durationSeconds: Int) -> String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
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
