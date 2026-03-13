//
//  ExerciseDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 30/06/2021.
//

import SwiftUI
import Charts

struct ExerciseDescription: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(exercise.description ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(exercise.name)
    }
}

struct ExerciseDetailView: View {

    @State var exercise: Exercise
    @StateObject private var exerciseStatsModel = StatisticsDataModel(autostart: false, runStartupSideEffects: false)

    private var completedSets: [ExerciseStatistics] {
        exerciseStatsModel.exerciseStatistics
            .filter { ($0.reps ?? 0) > 0 && ($0.weight ?? 0) > 0 }
            .sorted { lhs, rhs in
                if lhs.date == rhs.date {
                    return lhs.set < rhs.set
                }
                return lhs.date < rhs.date
            }
    }

    private var sessionSummaries: [ExerciseSessionSummary] {
        let calendar = Calendar.current
        let groupedSessions = Dictionary(grouping: completedSets) { stats in
            calendar.startOfDay(for: stats.date)
        }

        return groupedSessions.keys.sorted().map { date in
            let sets = groupedSessions[date, default: []].sorted { $0.set < $1.set }
            let bestSet = sets.max { lhs, rhs in
                estimatedOneRepMax(for: lhs) < estimatedOneRepMax(for: rhs)
            }
            let maxWeight = sets.map { $0.weight ?? 0 }.max() ?? 0
            let totalVolume = sets.reduce(0) { partialResult, stats in
                partialResult + Double(stats.reps ?? 0) * (stats.weight ?? 0)
            }
            let totalReps = sets.reduce(0) { partialResult, stats in
                partialResult + (stats.reps ?? 0)
            }

            return ExerciseSessionSummary(
                date: date,
                maxWeight: maxWeight,
                estimatedOneRepMax: bestSet.map(estimatedOneRepMax(for:)) ?? 0,
                totalVolume: totalVolume,
                totalReps: totalReps
            )
        }
    }

    private var recentSets: [ExerciseStatistics] {
        Array(completedSets.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.set > rhs.set
            }
            return lhs.date > rhs.date
        }.prefix(5))
    }

    private var personalRecordWeight: Double {
        exerciseStatsModel.maxWeight.weight ?? 0
    }

    private var personalRecordReps: Int {
        exerciseStatsModel.maxWeight.reps ?? 0
    }

    private var personalRecordDate: Date {
        exerciseStatsModel.maxWeight.date
    }

    private var estimatedOneRepMaxValue: Double {
        guard personalRecordWeight > 0, personalRecordReps > 0 else {
            return 0
        }

        return exerciseStatsModel.maxWeight.estimatedOneRepMax ?? exerciseStatsModel.getEstimatedOneRepMax(
            given: personalRecordReps,
            weight: personalRecordWeight
        )
    }

    private var totalVolume: Double {
        completedSets.reduce(0) { partialResult, stats in
            partialResult + Double(stats.reps ?? 0) * (stats.weight ?? 0)
        }
    }

    private var totalReps: Int {
        completedSets.reduce(0) { partialResult, stats in
            partialResult + (stats.reps ?? 0)
        }
    }

    private var sessionCount: Int {
        sessionSummaries.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NavigationLink(destination: ExerciseDescription(exercise: exercise)) {
                    ExerciseInfoCard(exercise: exercise)
                }
                .buttonStyle(.plain)

                if completedSets.isEmpty {
                    ExerciseEmptyStateCard()
                } else {
                    ExerciseHeroCard(
                        exerciseName: exercise.name,
                        personalRecordWeight: personalRecordWeight,
                        personalRecordReps: personalRecordReps,
                        estimatedOneRepMax: estimatedOneRepMaxValue,
                        personalRecordDate: personalRecordDate
                    )

                    HStack(spacing: 12) {
                        ExerciseStatPill(
                            title: "Sessies",
                            value: "\(sessionCount)",
                            subtitle: "afgerond",
                            tint: Color.accentColor
                        )
                        ExerciseStatPill(
                            title: "Totaal volume",
                            value: "\(Int(totalVolume)) kg",
                            subtitle: "\(totalReps) reps",
                            tint: Color.orange
                        )
                    }
                    if !exerciseStatsModel.estimatedWeights.isEmpty {
                        EstimatedWeightsCard(estimatedWeights: exerciseStatsModel.estimatedWeights)
                    }

                    if !recentSets.isEmpty {
                        RecentSetsCard(sets: recentSets)
                    }
                }
            }
            .padding(16)
        }
        .background(ExerciseDetailBackground())
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: "nl_NL"))
        .onAppear {
            exerciseStatsModel.fetchStatsForExercise(for: exercise.name)
        }
    }

    private func estimatedOneRepMax(for stats: ExerciseStatistics) -> Double {
        if let storedEstimate = stats.estimatedOneRepMax, storedEstimate > 0 {
            return storedEstimate
        }

        return exerciseStatsModel.getEstimatedOneRepMax(
            given: stats.reps ?? 1,
            weight: stats.weight ?? 1
        )
    }

}

private struct ExerciseInfoCard: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Oefening omschrijving")
                    .font(.headline)
                    .foregroundStyle(Color.init("blackWhite"))

                Text(descriptionStatusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var descriptionStatusText: String {
        if exercise.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "Bekijk techniek en uitleg"
        }

        return "Nog geen omschrijving toegevoegd"
    }
}

private struct ExerciseHeroCard: View {
    let exerciseName: String
    let personalRecordWeight: Double
    let personalRecordReps: Int
    let estimatedOneRepMax: Double
    let personalRecordDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Persoonlijk record")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: personalRecordWeight)) kg")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(personalRecordReps) reps • \(exerciseName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 12) {
                HeroMetricBadge(
                    title: "Geschatte 1RM",
                    value: "\(NumberHelper.roundNumbersMaxTwoDecimals(unit: estimatedOneRepMax)) kg"
                )
                HeroMetricBadge(
                    title: "Laatste PR",
                    value: personalRecordDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.accentColor.opacity(0.22), radius: 22, x: 0, y: 16)
    }
}

private struct HeroMetricBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ExerciseStatPill: View {
    let title: String
    let value: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .fill(tint)
                        .frame(width: 12, height: 12)
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.init("blackWhite"))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct EstimatedWeightsCard: View {
    let estimatedWeights: [EstimatedWeights]

    private var highlightedWeights: [EstimatedWeights] {
        estimatedWeights.filter { [1, 3, 5, 8, 10, 12].contains($0.reps) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Slimme richtgewichten")
                .font(.headline)

            Text("Indicatie op basis van je beste set. Gebruik dit als startpunt voor je volgende training.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(highlightedWeights) { estimation in
                BarMark(
                    x: .value("Reps", estimation.repsString),
                    y: .value("Gewicht", estimation.weight)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(8)
            }
            .frame(height: 190)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(highlightedWeights, id: \.id) { estimation in
                    HStack {
                        Text(estimation.repsString)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: estimation.weight)) kg")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.init("blackWhite"))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct RecentSetsCard: View {
    let sets: [ExerciseStatistics]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recente sets")
                .font(.headline)

            ForEach(sets, id: \.id) { stats in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stats.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.init("blackWhite"))
                        Text("Set \(stats.set + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(stats.reps ?? 0) reps")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: stats.weight ?? 0)) kg")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Color.init("blackWhite"))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct ExerciseEmptyStateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text("Nog geen statistieken beschikbaar")
                .font(.headline)

            Text("Rond deze oefening een keer af in je training. Daarna tonen we hier PR's, progressie en richtgewichten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct ExerciseDetailBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.08),
                Color.orange.opacity(0.06),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct ExerciseSessionSummary: Identifiable {
    let date: Date
    let maxWeight: Double
    let estimatedOneRepMax: Double
    let totalVolume: Double
    let totalReps: Int

    var id: Date { date }
}
