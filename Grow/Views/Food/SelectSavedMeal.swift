//
//  SelectSavedMeal.swift
//  Grow
//
//  Created by Swen Rolink on 31/08/2021.
//

import SwiftUI

struct SelectSavedMeal: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var isPresented: Bool

    @State private var searchText = ""

    private var filteredMeals: [Meal] {
        let meals = foodModel.savedMeals.filter { meal in
            guard let name = meal.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                return false
            }

            return name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
        }

        return meals.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Maaltijd zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Opgeslagen maaltijden") {
                if filteredMeals.isEmpty {
                    ContentUnavailableView(
                        "Geen maaltijden gevonden",
                        systemImage: "magnifyingglass",
                        description: Text("Pas je zoekterm aan of sla eerst een maaltijd op.")
                    )
                } else {
                    ForEach(filteredMeals, id: \.self) { meal in
                        SavedMealRow(meal: meal) {
                            foodModel.addSavedMeal(meal: meal)
                            isPresented = false
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Maaltijd kiezen")
    }
}

private struct SavedMealRow: View {
    let meal: Meal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(meal.name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 12) {
                    MealMacroValue(title: "Kcal", value: NumberHelper.roundedNumbersFromDouble(unit: meal.kcal))
                    MealMacroValue(title: "Koolh", value: NumberHelper.roundedNumbersFromDouble(unit: meal.carbs))
                    MealMacroValue(title: "Eiwit", value: NumberHelper.roundedNumbersFromDouble(unit: meal.protein))
                    MealMacroValue(title: "Vet", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fat))
                    MealMacroValue(title: "Vezel", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fiber))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct MealMacroValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
