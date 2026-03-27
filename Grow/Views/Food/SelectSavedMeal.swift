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
    @State private var filterOnRemainingCalories = false
    @State private var filterOnQuickMeals = false

    private var remainingKcal: Double {
        foodModel.foodDiary.usersCalorieLeftOver.kcal
    }

    private var filteredMeals: [Meal] {
        let meals = foodModel.savedMeals.filter { meal in
            guard let name = meal.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                return false
            }

            let matchesSearch = name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
            let fitsRemainingCalories = !filterOnRemainingCalories || meal.kcal <= remainingKcal
            let fitsQuickMeal = !filterOnQuickMeals || (meal.recipeDurationInMinutes.map { $0 <= 20 } ?? false)

            return matchesSearch && fitsRemainingCalories && fitsQuickMeal
        }

        return meals.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    PickerSearchBar(text: $searchText, placeholder: "Maaltijd zoeken")

                    HStack(spacing: 8) {
                        Button {
                            filterOnRemainingCalories.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filterOnRemainingCalories ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                Text("\(NumberHelper.roundedNumbersFromDouble(unit: remainingKcal)) kcal over")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(filterOnRemainingCalories ? Color.white : Color.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(filterOnRemainingCalories ? Color.accentColor : Color.accentColor.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            filterOnQuickMeals.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filterOnQuickMeals ? "bolt.fill" : "bolt")
                                Text("Snel klaar")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(filterOnQuickMeals ? Color.white : Color.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(filterOnQuickMeals ? Color.accentColor : Color.accentColor.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }

            Section("Opgeslagen maaltijden") {
                if filteredMeals.isEmpty {
                    ContentUnavailableView(
                        "Geen maaltijden gevonden",
                        systemImage: "magnifyingglass",
                        description: Text(activeFilterDescription)
                    )
                } else {
                    ForEach(filteredMeals, id: \.self) { meal in
                        NavigationLink(destination: SavedMealPreviewDetailView(meal: meal, isPresented: $isPresented)) {
                            SavedMealRow(meal: meal)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Maaltijd kiezen")
    }

    private var activeFilterDescription: String {
        if filterOnRemainingCalories && filterOnQuickMeals {
            return "Pas je zoekterm aan of zet een van de filters uit."
        }
        if filterOnRemainingCalories {
            return "Pas je zoekterm aan of zet de kcal-filter uit."
        }
        if filterOnQuickMeals {
            return "Pas je zoekterm aan of zet de filter voor snelle maaltijden uit."
        }
        return "Pas je zoekterm aan of sla eerst een maaltijd op."
    }
}

private struct SavedMealRow: View {
    let meal: Meal

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let imageURLString = meal.recipe?.imageStorageURL ?? meal.recipe?.imageSourceURL,
               let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(meal.name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let totalTimeText = meal.recipe?.totalTimeText, !totalTimeText.isEmpty {
                    Label(totalTimeText, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .top, spacing: 12) {
                    MealMacroValue(title: "Kcal", value: NumberHelper.roundedNumbersFromDouble(unit: meal.kcal))
                    MealMacroValue(title: "Koolh", value: NumberHelper.roundedNumbersFromDouble(unit: meal.carbs))
                    MealMacroValue(title: "Eiwit", value: NumberHelper.roundedNumbersFromDouble(unit: meal.protein))
                    MealMacroValue(title: "Vet", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fat))
                    MealMacroValue(title: "Vezel", value: NumberHelper.roundedNumbersFromDouble(unit: meal.fiber))
                }
            }
        }
        .padding(.vertical, 4)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

private extension Meal {
    var recipeDurationInMinutes: Int? {
        guard let totalTimeText = recipe?.totalTimeText?.lowercased(), !totalTimeText.isEmpty else {
            return nil
        }

        let nsText = totalTimeText as NSString
        let pattern = #"(\d+)"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: totalTimeText, range: NSRange(location: 0, length: nsText.length)),
              let range = Range(match.range(at: 1), in: totalTimeText),
              let value = Int(totalTimeText[range]) else {
            return nil
        }

        if totalTimeText.contains("uur") || totalTimeText.contains("hour") || totalTimeText.contains("hr") {
            return value * 60
        }

        return value
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

private struct SavedMealPreviewDetailView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    @Binding var isPresented: Bool

    var body: some View {
        List {
            if let recipe = meal.recipe {
                Section {
                    SavedMealRecipeHero(recipe: recipe)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            if meal.recipe == nil {
                Section("Titel") {
                Text(meal.name?.isEmpty == false ? meal.name! : "Maaltijd")
                }
            }

            Section("Ingredienten") {
                if let products = meal.products, !products.isEmpty {
                    ForEach(products, id: \.self) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                Text("\(product.selectedProductDetails?.amount ?? 0) gram")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(NumberHelper.roundedNumbersFromDouble(unit: product.selectedProductDetails?.kcal ?? 0))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Nog geen ingredienten",
                        systemImage: "fork.knife",
                        description: Text("Deze opgeslagen maaltijd bevat nog geen producten.")
                    )
                }
            }

            Section("Totaal") {
                MealMacroPreviewRow(title: "Calorieën", value: NumberHelper.roundedNumbersFromDouble(unit: meal.kcal))
                MealMacroPreviewRow(title: "Koolhydraten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: meal.carbs))
                MealMacroPreviewRow(title: "Eiwitten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: meal.protein))
                MealMacroPreviewRow(title: "Vetten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: meal.fat))
                MealMacroPreviewRow(title: "Vezels", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: meal.fiber))
            }

            if let recipe = meal.recipe {
                Section("Bereiding") {
                    if let sourceURL = URL(string: recipe.sourceURL) {
                        Link(destination: sourceURL) {
                            Label(recipe.sourceDomain, systemImage: "link")
                                .font(.subheadline)
                        }
                    }

                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                            Text(instruction)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(meal.name?.isEmpty == false ? meal.name! : "Maaltijd")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Voeg toe") {
                    foodModel.addSavedMeal(meal: meal)
                    isPresented = false
                    dismiss()
                }
            }
        }
    }
}

private struct SavedMealRecipeHero: View {
    let recipe: MealRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURLString = recipe.imageStorageURL ?? recipe.imageSourceURL,
               let imageURL = URL(string: imageURLString) {
                ZStack(alignment: .bottom) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            ZStack {
                                Rectangle().fill(Color.secondary.opacity(0.12))
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    LinearGradient(
                        colors: [
                            .clear,
                            Color(.systemBackground).opacity(0.35),
                            Color(.systemBackground).opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 110)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .allowsHitTesting(false)
                }
            }

            Text(recipe.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            if let totalTimeText = recipe.totalTimeText, !totalTimeText.isEmpty {
                Label(totalTimeText, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }
        }
    }
}

private struct MealMacroPreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
