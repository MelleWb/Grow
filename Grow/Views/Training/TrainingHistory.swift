//
//  TrainingHistory.swift
//  Grow
//
//  Created by Swen Rolink on 03/09/2021.
//

import SwiftUI
import Charts

struct TrainingHistoryOverview: View {
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @EnvironmentObject var userModel: UserDataModel

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(self.statisticsModel.trainingHistory, id: \.self) { training in
                        ZStack {
                            Button("") {}
                            NavigationLink(destination: TrainingHistoryDetail(training: training)) {
                                TrainingHistoryRow(training: training)
                            }
                        }
                    }
                    .onDelete(perform: deleteTrainingHistory)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Training historie"))
        .onAppear {
            self.statisticsModel.loadTrainingHistory()
        }
    }

    func deleteTrainingHistory(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.statisticsModel.removeTrainingHistory(for: index)
        self.userModel.getTrainingStatsForCurrentWeek()
    }
}

struct TrainingHistoryRow: View {
    @State var training: TrainingStatistics

    private var totalDuration: Int {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private var totalDistance: Double {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.distanceKilometers ?? 0) }
    }

    private var hasCardioData: Bool {
        totalDuration > 0 || totalDistance > 0
    }

    var body: some View {
        HStack {
            Text(training.trainingDate, style: .date)
            Spacer()
            Text(trailingLabel)
                .foregroundStyle(.secondary)
        }
    }

    private var trailingLabel: String {
        if hasCardioData {
            if totalDistance > 0 {
                return "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: totalDistance)) km • \(formattedDuration(totalDuration))"
            }
            return formattedDuration(totalDuration)
        }

        return "\(Int(training.trainingVolume)) kg"
    }

    private func formattedDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct TrainingHistoryDetail: View {
    @State var training: TrainingStatistics

    private var groupedExerciseStats: [ExerciseGroup] {
        let grouped = Dictionary(grouping: training.exerciceStatistics ?? []) { stats in
            stats.exerciseName
        }

        return grouped
            .map { name, stats in
                ExerciseGroup(
                    name: name,
                    sets: stats.sorted { $0.set < $1.set }
                )
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section {
                TrainingHistorySummary(training: training)
            }

            ForEach(groupedExerciseStats) { exerciseGroup in
                Section {
                    ExerciseHistoryCard(exerciseGroup: exerciseGroup)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text("Training overzicht"))
    }
}

private struct TrainingHistorySummary: View {
    let training: TrainingStatistics

    private var totalSets: Int {
        training.exerciceStatistics?.count ?? 0
    }

    private var uniqueExercises: Int {
        Set(training.exerciceStatistics?.map(\.exerciseName) ?? []).count
    }

    private var totalDuration: Int {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private var totalDistance: Double {
        (training.exerciceStatistics ?? []).reduce(0) { $0 + ($1.distanceKilometers ?? 0) }
    }

    private var hasCardioData: Bool {
        totalDuration > 0 || totalDistance > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(training.trainingDate.formatted(date: .complete, time: .omitted))
                .font(.headline)

            HStack(spacing: 12) {
                if hasCardioData {
                    TrainingSummaryMetric(title: totalDistance > 0 ? "Afstand" : "Tijd", value: totalDistance > 0 ? "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: totalDistance)) km" : formattedDuration(totalDuration))
                } else {
                    TrainingSummaryMetric(title: "Volume", value: "\(Int(training.trainingVolume)) kg")
                }
                TrainingSummaryMetric(title: "Oefeningen", value: "\(uniqueExercises)")
                TrainingSummaryMetric(title: "Sets", value: "\(totalSets)")
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private struct TrainingSummaryMetric: View {
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

private struct ExerciseHistoryCard: View {
    let exerciseGroup: ExerciseGroup

    private var isRunningExercise: Bool {
        exerciseGroup.sets.contains { ($0.distanceKilometers ?? 0) > 0 }
    }

    private var isIntervalExercise: Bool {
        !isRunningExercise && exerciseGroup.sets.contains { ($0.completedIntervals ?? 0) > 0 || ($0.durationSeconds ?? 0) > 0 }
    }

    private var isHyroxExercise: Bool {
        !isRunningExercise && exerciseGroup.sets.contains { ($0.completedIntervals ?? 0) == 0 && ($0.durationSeconds ?? 0) > 0 }
    }

    private var maxWeight: Double {
        exerciseGroup.sets.map { $0.weight ?? 0 }.max() ?? 0
    }

    private var totalReps: Int {
        exerciseGroup.sets.reduce(0) { partialResult, stats in
            partialResult + (stats.reps ?? 0)
        }
    }

    private var totalVolume: Double {
        exerciseGroup.sets.reduce(0) { partialResult, stats in
            partialResult + (Double(stats.reps ?? 0) * (stats.weight ?? 0))
        }
    }

    private var totalDistance: Double {
        exerciseGroup.sets.reduce(0) { $0 + ($1.distanceKilometers ?? 0) }
    }

    private var totalDuration: Int {
        exerciseGroup.sets.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private var totalIntervals: Int {
        exerciseGroup.sets.reduce(0) { $0 + ($1.completedIntervals ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(exerciseGroup.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    if isRunningExercise {
                        TrainingSummaryMetric(title: "Afstand", value: "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: totalDistance)) km")
                        TrainingSummaryMetric(title: "Tijd", value: formattedDuration(totalDuration))
                        TrainingSummaryMetric(title: "Tempo", value: paceString)
                    } else if isHyroxExercise {
                        TrainingSummaryMetric(title: "Tijd", value: formattedDuration(totalDuration))
                        TrainingSummaryMetric(title: "Sets", value: "\(exerciseGroup.sets.count)")
                        TrainingSummaryMetric(title: "Gemiddeld", value: exerciseGroup.sets.isEmpty ? "-" : formattedDuration(totalDuration / max(exerciseGroup.sets.count, 1)))
                    } else if isIntervalExercise {
                        TrainingSummaryMetric(title: "Intervallen", value: "\(totalIntervals)x")
                        TrainingSummaryMetric(title: "Tijd", value: formattedDuration(totalDuration))
                        TrainingSummaryMetric(title: "Sets", value: "\(exerciseGroup.sets.count)")
                    } else {
                        TrainingSummaryMetric(title: "Max gewicht", value: "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: maxWeight)) kg")
                        TrainingSummaryMetric(title: "Totaal reps", value: "\(totalReps)")
                        TrainingSummaryMetric(title: "Volume", value: "\(Int(totalVolume)) kg")
                    }
                }
            }

            if isRunningExercise {
                cardioDistanceChart
                cardioDetails
            } else if isHyroxExercise {
                intervalDurationChart
                cardioDetails
            } else if isIntervalExercise {
                intervalDurationChart
                cardioDetails
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gewicht per set")
                        .font(.subheadline.weight(.semibold))

                    Chart(exerciseGroup.sets) { stats in
                        BarMark(
                            x: .value("Set", stats.set + 1),
                            y: .value("Gewicht", stats.weight ?? 0)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: exerciseGroup.sets.map { $0.set + 1 }) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let setNumber = value.as(Int.self) {
                                    Text("Set \(setNumber)")
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps per set")
                        .font(.subheadline.weight(.semibold))

                    Chart(exerciseGroup.sets) { stats in
                        LineMark(
                            x: .value("Set", stats.set + 1),
                            y: .value("Reps", stats.reps ?? 0)
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        PointMark(
                            x: .value("Set", stats.set + 1),
                            y: .value("Reps", stats.reps ?? 0)
                        )
                        .foregroundStyle(.orange)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: exerciseGroup.sets.map { $0.set + 1 }) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let setNumber = value.as(Int.self) {
                                    Text("Set \(setNumber)")
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Set details")
                        .font(.subheadline.weight(.semibold))

                    ForEach(exerciseGroup.sets, id: \.id) { stats in
                        HStack {
                            Text("Set \(stats.set + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(stats.reps ?? 0) reps")
                                .monospacedDigit()
                            Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: stats.weight ?? 0)) kg")
                                .monospacedDigit()
                                .frame(minWidth: 72, alignment: .trailing)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var cardioDistanceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Afstand per set")
                .font(.subheadline.weight(.semibold))

            Chart(exerciseGroup.sets) { stats in
                BarMark(
                    x: .value("Set", stats.set + 1),
                    y: .value("Afstand", stats.distanceKilometers ?? 0)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
            }
            .frame(height: 180)
        }
    }

    private var intervalDurationChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tijd per set")
                .font(.subheadline.weight(.semibold))

            Chart(exerciseGroup.sets) { stats in
                BarMark(
                    x: .value("Set", stats.set + 1),
                    y: .value("Seconden", stats.durationSeconds ?? 0)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(6)
            }
            .frame(height: 180)
        }
    }

    private var cardioDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set details")
                .font(.subheadline.weight(.semibold))

            ForEach(exerciseGroup.sets, id: \.id) { stats in
                HStack {
                    Text("Set \(stats.set + 1)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isRunningExercise {
                        Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: stats.distanceKilometers ?? 0)) km • \(formattedDuration(stats.durationSeconds ?? 0)) • \(paceString(for: stats))")
                            .multilineTextAlignment(.trailing)
                    } else if isHyroxExercise {
                        Text(formattedDuration(stats.durationSeconds ?? 0))
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("\(stats.completedIntervals ?? 0)x • \(formattedDuration(stats.durationSeconds ?? 0))")
                            .multilineTextAlignment(.trailing)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    private var paceString: String {
        guard totalDistance > 0, totalDuration > 0 else {
            return "-"
        }

        let paceSeconds = Int((Double(totalDuration) / totalDistance).rounded())
        return "\(paceSeconds / 60):\(String(format: "%02d", paceSeconds % 60)) min/km"
    }

    private func paceString(for stats: ExerciseStatistics) -> String {
        guard let distance = stats.distanceKilometers, distance > 0, let duration = stats.durationSeconds, duration > 0 else {
            return "-"
        }

        let paceSeconds = Int((Double(duration) / distance).rounded())
        return "\(paceSeconds / 60):\(String(format: "%02d", paceSeconds % 60)) min/km"
    }

    private func formattedDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private struct ExerciseGroup: Identifiable {
    let name: String
    let sets: [ExerciseStatistics]

    var id: String { name }
}
