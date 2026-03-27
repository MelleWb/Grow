//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ProductIntakeEditorView: View {
    let product: Product
    let saveButtonTitle: String
    let onSave: (SelectedProductDetails) -> Bool
    let onSuccess: () -> Void

    @State private var amount: String
    @State private var amountInput: String = ""
    @State private var selectedPortionIndex = 0
    @State private var portionCountText: String = ""

    @State private var calories: Double = 0
    @State private var carbs: Double = 0
    @State private var protein: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0

    init(
        product: Product,
        initialAmount: Int,
        saveButtonTitle: String,
        onSave: @escaping (SelectedProductDetails) -> Bool,
        onSuccess: @escaping () -> Void
    ) {
        self.product = product
        self.saveButtonTitle = saveButtonTitle
        self.onSave = onSave
        self.onSuccess = onSuccess
        _amount = State(initialValue: String(initialAmount))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Picker("Portie", selection: $selectedPortionIndex) {
                        ForEach(Array(product.portions.enumerated()), id: \.offset) { index, portion in
                            Text("\(portion.name) (\(portion.amount) g)").tag(index)
                        }
                    }
                }
                HStack {
                    Text("Aantal porties")
                    Spacer()
                    TextField("", text: $portionCountText, prompt: Text("1"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Portiegrootte (g)")
                    Spacer()
                    TextField("", text: amountBinding, prompt: Text(amount))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section(header: Text("Nutriënten per \(amount) g")) {
                HStack {
                    Text("Calorieën")
                    Spacer()
                    Text(NumberHelper.roundedNumbersFromDouble(unit: calories))
                }
                HStack {
                    Text("Koolhydraten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit: carbs))
                }
                HStack {
                    Text("Eiwitten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit: protein))
                }
                HStack {
                    Text("Vetten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit: fat))
                }
                HStack {
                    Text("Vezels")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit: fiber))
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationTitle(Text(product.name))
        .toolbar {
            Button(saveButtonTitle) {
                save()
            }
        }
        .onAppear {
            configureSelectionFromExistingAmount()
        }
        .onChange(of: selectedPortionIndex) { _, _ in
            applySelectedPortion()
        }
        .onChange(of: portionCountText) { _, _ in
            applySelectedPortion()
        }
    }

    private func calculation(unit: Double, portion: Int) -> Double {
        let per1gram = unit / 100
        return (per1gram * Double(portion)).rounded()
    }

    private func updateCalories(portion: Int) {
        calories = calculation(unit: product.kcal, portion: portion)
        carbs = calculation(unit: product.carbs, portion: portion)
        protein = calculation(unit: product.protein, portion: portion)
        fat = calculation(unit: product.fat, portion: portion)
        fiber = calculation(unit: product.fiber, portion: portion)
    }

    private var selectedPortion: ProductPortion? {
        guard product.portions.indices.contains(selectedPortionIndex) else {
            return nil
        }

        return product.portions[selectedPortionIndex]
    }

    private var portionCount: Int {
        if let value = NumberFormatter().number(from: portionCountText) {
            return max(value.intValue, 1)
        }

        return 1
    }

    private func applySelectedPortion() {
        guard let selectedPortion else {
            return
        }

        let totalAmount = selectedPortion.amount * portionCount
        amountInput = ""
        amount = String(totalAmount)
        updateCalories(portion: totalAmount)
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { amountInput },
            set: { newValue in
                amountInput = newValue

                if let value = NumberFormatter().number(from: newValue) {
                    amount = String(value.intValue)
                    updateCalories(portion: value.intValue)
                } else if newValue.isEmpty {
                    applySelectedPortion()
                }
            }
        )
    }

    private func configureSelectionFromExistingAmount() {
        guard let currentAmount = NumberFormatter().number(from: amount)?.intValue else {
            applySelectedPortion()
            return
        }

        let exactMatch = product.portions.enumerated()
            .filter { _, portion in
                portion.amount > 0 && currentAmount % portion.amount == 0
            }
            .max { lhs, rhs in
                lhs.element.amount < rhs.element.amount
            }

        if let exactMatch {
            selectedPortionIndex = exactMatch.offset
            let count = max(currentAmount / exactMatch.element.amount, 1)
            portionCountText = count == 1 ? "" : String(count)
            applySelectedPortion()
        } else {
            selectedPortionIndex = 0
            portionCountText = ""
            updateCalories(portion: currentAmount)
        }
    }

    private func save() {
        guard let value = NumberFormatter().number(from: amount) else {
            return
        }

        let createdProduct = SelectedProductDetails(
            kcal: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            fiber: fiber,
            amount: value.intValue
        )

        if onSave(createdProduct) {
            onSuccess()
        }
    }
}

struct ChangeIntakeOfProduct: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss
    @State var product: Product
    @State var meal: Meal
    @State var amount: String

    var body: some View {
        ProductIntakeEditorView(
            product: product,
            initialAmount: NumberFormatter().number(from: amount)?.intValue ?? 100,
            saveButtonTitle: "Sla op",
            onSave: { createdProduct in
                foodModel.updateProductInMeal(for: meal, with: product, with: createdProduct)
            },
            onSuccess: {
                dismiss()
            }
        )
    }
}
