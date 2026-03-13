//
//  TrainingDaySelectionView.swift
//  Grow
//
//  Created by Swen Rolink on 29/07/2021.
//

import SwiftUI

struct TrainingDaySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel

    @State private var plannedDays: [PlannerItem?] = Array(repeating: nil, count: 7)
    @State private var availableItems: [PlannerItem] = []
    @State private var didLoadInitialState = false

    private let weekDays = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"]

    private var isPlanComplete: Bool {
        plannedDays.allSatisfy { $0 != nil } && availableItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Weekplanning") {
                    ForEach(weekDays.indices, id: \.self) { index in
                        TrainingDayDropRow(
                            weekDay: weekDays[index],
                            item: plannedDays[index],
                            availableItems: availableOptions(for: index),
                            onSelect: { selectedID in
                                assignItem(with: selectedID, to: index)
                            },
                            onRemove: {
                                removeAssignment(at: index)
                            }
                        )
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                }

                Section("Beschikbare trainingen") {
                    Text(availableItems.isEmpty ? "Alle trainingen zijn gekoppeld. Controleer de planning en tik op Opslaan." : availableItems.map(\.label).joined(separator: ", "))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trainingsdagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Opslaan") {
                        savePlan()
                    }
                    .disabled(!isPlanComplete)
                }
            }
            .interactiveDismissDisabled(true)
            .onAppear {
                guard !didLoadInitialState else {
                    return
                }
                loadInitialState()
                didLoadInitialState = true
            }
        }
    }

    private func loadInitialState() {
        let sourceWeekPlan = userModel.user.weekPlan ?? []
        let plannerItems = sourceWeekPlan.map {
            PlannerItem(
                id: $0.id,
                trainingType: $0.trainingType,
                routine: $0.routine,
                isTrainingDay: $0.isTrainingDay
            )
        }

        var loadedDays = Array<PlannerItem?>(repeating: nil, count: weekDays.count)

        for (index, item) in plannerItems.enumerated() where index < loadedDays.count {
            loadedDays[index] = item
        }

        plannedDays = loadedDays
        availableItems = []
    }

    private func removeAssignment(at index: Int) {
        guard
            plannedDays.indices.contains(index),
            let item = plannedDays[index]
        else {
            return
        }

        plannedDays[index] = nil

        if !availableItems.contains(where: { $0.id == item.id }) {
            availableItems.append(item)
        }
    }

    private func availableOptions(for index: Int) -> [PlannerItem] {
        var options = availableItems.sorted(by: plannerSort)

        if let currentItem = plannedDays[index], !options.contains(where: { $0.id == currentItem.id }) {
            options.append(currentItem)
        }

        return options.sorted(by: plannerSort)
    }

    private func assignItem(with droppedID: UUID, to index: Int) {
        guard plannedDays.indices.contains(index) else {
            return
        }

        let selectedItem: PlannerItem

        if let availableIndex = availableItems.firstIndex(where: { $0.id == droppedID }) {
            selectedItem = availableItems.remove(at: availableIndex)
        } else if let currentItem = plannedDays[index], currentItem.id == droppedID {
            return
        } else if let existingItem = plannedDays.first(where: { $0?.id == droppedID }) ?? nil {
            selectedItem = existingItem
        } else {
            return
        }

        if let previousItem = plannedDays[index] {
            availableItems.append(previousItem)
        }

        if let previousIndex = plannedDays.firstIndex(where: { $0?.id == selectedItem.id }) {
            plannedDays[previousIndex] = nil
        }

        plannedDays[index] = selectedItem
        availableItems.sort(by: plannerSort)
    }

    private func savePlan() {
        guard isPlanComplete else {
            return
        }

        userModel.user.weekPlan = plannedDays.compactMap { plannerItem in
            guard let plannerItem else {
                return nil
            }

            return DayPlan(
                id: plannerItem.id,
                trainingType: plannerItem.trainingType,
                routine: plannerItem.routine,
                isTrainingDay: plannerItem.isTrainingDay
            )
        }

        userModel.determineWorkoutOfTheDay()
        userModel.updateUser {
            self.foodModel.resetUser(user: self.userModel.user)
            self.trainingModel.resetUser(user: self.userModel.user)
            self.statisticsModel.resetUser(user: self.userModel.user)
            dismiss()
        }
    }

    private func plannerSort(lhs: PlannerItem, rhs: PlannerItem) -> Bool {
        if lhs.isTrainingDay != rhs.isTrainingDay {
            return lhs.isTrainingDay == true
        }

        return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
    }
}

private struct TrainingDayDropRow: View {
    let weekDay: String
    let item: PlannerItem?
    let availableItems: [PlannerItem]
    let onSelect: (UUID) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(weekDay)
                .foregroundColor(Color.init("blackWhite"))
                .frame(width: 96, alignment: .leading)

            TrainingDayPicker(
                item: item,
                availableItems: availableItems,
                onSelect: onSelect,
                onRemove: onRemove
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TrainingDayPicker: View {
    let item: PlannerItem?
    let availableItems: [PlannerItem]
    let onSelect: (UUID) -> Void
    let onRemove: () -> Void

    var body: some View {
        Menu {
            if item != nil {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Leegmaken", systemImage: "minus.circle")
                }
            }

            ForEach(availableItems) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    Label(option.label, systemImage: option.iconName)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item?.iconName ?? "line.3.horizontal.decrease.circle")
                    .foregroundColor(item == nil ? .secondary : Color.init("textColor"))

                Text(item?.label ?? "Selecteer training")
                    .foregroundColor(item == nil ? .secondary : Color.init("blackWhite"))

                Spacer(minLength: 8)

                if item != nil {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
}

private struct PlannerItem: Identifiable, Equatable {
    let id: UUID
    let trainingType: String?
    let routine: UUID?
    let isTrainingDay: Bool?

    var label: String {
        if isTrainingDay == true {
            return trainingType ?? "Training"
        }

        return "Rust"
    }

    var iconName: String {
        let isTraining = isTrainingDay == true
        let type = trainingType ?? ""

        return !isTraining
            ? "powersleep"
            : (type == "Hyrox" || type == "Cardio")
                ? "figure.run"
                : "figure.strengthtraining.traditional"
    }
}

private struct TrainingDaySelectionPreview: View {
    @StateObject private var userModel: UserDataModel = {
        let model = UserDataModel(autostart: false, runStartupSideEffects: false)
        model.user.weekPlan = [
            DayPlan(trainingType: "Borst", routine: UUID(), isTrainingDay: true),
            DayPlan(trainingType: "Rust", routine: nil, isTrainingDay: false),
            DayPlan(trainingType: "Rug", routine: UUID(), isTrainingDay: true),
            DayPlan(trainingType: "Rust", routine: nil, isTrainingDay: false),
            DayPlan(trainingType: "Benen", routine: UUID(), isTrainingDay: true),
            DayPlan(trainingType: "Rust", routine: nil, isTrainingDay: false),
            DayPlan(trainingType: "Rust", routine: nil, isTrainingDay: false)
        ]
        return model
    }()

    @StateObject private var foodModel = FoodDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var trainingModel = TrainingDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var statisticsModel = StatisticsDataModel(autostart: false, runStartupSideEffects: false)

    var body: some View {
        TrainingDaySelectionView()
            .environmentObject(userModel)
            .environmentObject(foodModel)
            .environmentObject(trainingModel)
            .environmentObject(statisticsModel)
    }
}

#Preview {
    TrainingDaySelectionPreview()
}
