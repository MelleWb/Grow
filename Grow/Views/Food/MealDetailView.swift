import SwiftUI

struct MealDetailView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    let meal: Meal

    @State private var mealName = ""
    @State private var showAddProductToMeal = false

    private var currentMeal: Meal {
        foodModel.currentMeal(for: meal) ?? meal
    }

    private var displayedMealName: String {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }

        let currentName = currentMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return currentName.isEmpty ? "Maaltijd" : currentName
    }

    var body: some View {
        VStack {
            List {
                Section("Titel") {
                    TextField("Maaltijdnaam", text: $mealName)
                        .onSubmit {
                            persistMealName()
                        }
                }

                Section("Ingredienten") {
                    if let products = currentMeal.products, !products.isEmpty {
                        ForEach(products, id: \.self) { product in
                            FoodProductRow(meal: currentMeal, product: product)
                        }
                        .onDelete(perform: deleteProduct)
                    } else {
                        ContentUnavailableView(
                            "Nog geen ingredienten",
                            systemImage: "fork.knife",
                            description: Text("Voeg producten toe om deze maaltijd op te slaan of bij te werken.")
                        )
                    }

                    Button {
                        showAddProductToMeal = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Voeg product toe")
                        }
                        .foregroundColor(.accentColor)
                    }
                }

                Section("Totaal") {
                    MealMacroSummaryRow(title: "Calorieën", value: NumberHelper.roundedNumbersFromDouble(unit: currentMeal.kcal))
                    MealMacroSummaryRow(title: "Koolhydraten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.carbs))
                    MealMacroSummaryRow(title: "Eiwitten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.protein))
                    MealMacroSummaryRow(title: "Vetten", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.fat))
                    MealMacroSummaryRow(title: "Vezels", value: NumberHelper.roundNumbersMaxTwoDecimals(unit: currentMeal.fiber))
                }
            }
        }
        .navigationDestination(isPresented: $showAddProductToMeal) {
            AddProductToMealList(meal: currentMeal, isPresented: $showAddProductToMeal)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(displayedMealName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Opslaan") {
                    persistMealName()
                    let success = foodModel.saveMeal(for: currentMeal)
                    if success {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            mealName = currentMeal.name ?? ""
        }
    }

    private func persistMealName() {
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = currentMeal.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard trimmedName != currentName else {
            return
        }

        foodModel.updateMealName(for: meal, name: trimmedName)
    }

    private func deleteProduct(at offsets: IndexSet) {
        guard let productIndex = offsets.first else {
            return
        }

        foodModel.deleteProductFromMeal(for: currentMeal, with: productIndex)
    }
}

private struct MealMacroSummaryRow: View {
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

#Preview {
    FoodPreviewContainer(
        diary: FoodDiary(
            meals: [
                Meal(
                    name: "Lunch",
                    products: [
                        Product(
                            name: "Havermout",
                            kcal: 380,
                            carbs: 62,
                            protein: 13,
                            fat: 7,
                            fiber: 9,
                            selectedProductDetails: SelectedProductDetails(kcal: 304, carbs: 49.6, protein: 10.4, fat: 5.6, fiber: 7.2, amount: 80)
                        )
                    ],
                    kcal: 304,
                    carbs: 49.6,
                    protein: 10.4,
                    fat: 5.6,
                    fiber: 7.2
                )
            ]
        )
    ) {
        NavigationStack {
            MealDetailView(meal: Meal(name: "Lunch"))
        }
    }
}
