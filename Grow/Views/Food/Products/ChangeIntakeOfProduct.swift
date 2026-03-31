//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ProductIntakeEditorView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
    let product: Product
    let saveButtonTitle: String
    let onSave: (SelectedProductDetails) -> Bool
    let onSuccess: () -> Void

    @State private var currentProduct: Product
    @State private var amount: String
    @State private var amountInput: String = ""
    @State private var selectedPortionIndex = 0
    @State private var portionCountText: String = ""

    @State private var calories: Double = 0
    @State private var carbs: Double = 0
    @State private var protein: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0
    @State private var showBarcodeScanner = false
    @State private var showManualBarcodeEntry = false
    @State private var barcodeDraft = ""
    @State private var isSavingBarcode = false
    @State private var barcodeSaveMessage: String?

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
        _currentProduct = State(initialValue: product)
        _amount = State(initialValue: String(initialAmount))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Picker("Portie", selection: $selectedPortionIndex) {
                        ForEach(Array(currentProduct.portions.enumerated()), id: \.offset) { index, portion in
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

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if currentProduct.barcodes.isEmpty == false {
                        ForEach(currentProduct.barcodes, id: \.self) { barcode in
                            Label(barcode, systemImage: "barcode")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Button("Scan opnieuw") {
                            showBarcodeScanner = true
                        }
                        .font(.footnote)
                    } else {
                        Button {
                            showBarcodeScanner = true
                        } label: {
                            Label("Scan barcode", systemImage: "barcode.viewfinder")
                        }

                        Button("Voer barcode handmatig in") {
                            barcodeDraft = ""
                            showManualBarcodeEntry = true
                        }
                        .font(.footnote)
                    }

                    if isSavingBarcode {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Barcode opslaan...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
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
        .navigationTitle(Text(currentProduct.name))
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerSheet { barcode in
                persistBarcode(barcode)
            }
        }
        .alert("Barcode handmatig aanpassen", isPresented: $showManualBarcodeEntry) {
            TextField("Barcode", text: $barcodeDraft)
                .keyboardType(.numberPad)
            Button("Annuleer", role: .cancel) {
                barcodeDraft = ""
            }
            Button("Opslaan") {
                persistBarcode(barcodeDraft)
            }
        } message: {
            Text("De barcode wordt direct opgeslagen bij dit product.")
        }
        .alert("Barcode", isPresented: Binding(
            get: { barcodeSaveMessage != nil },
            set: { newValue in
                if newValue == false {
                    barcodeSaveMessage = nil
                }
            }
        )) {
            Button("Ok", role: .cancel) {
                barcodeSaveMessage = nil
            }
        } message: {
            Text(barcodeSaveMessage ?? "")
        }
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
        calories = calculation(unit: currentProduct.kcal, portion: portion)
        carbs = calculation(unit: currentProduct.carbs, portion: portion)
        protein = calculation(unit: currentProduct.protein, portion: portion)
        fat = calculation(unit: currentProduct.fat, portion: portion)
        fiber = calculation(unit: currentProduct.fiber, portion: portion)
    }

    private var selectedPortion: ProductPortion? {
        guard currentProduct.portions.indices.contains(selectedPortionIndex) else {
            return nil
        }

        return currentProduct.portions[selectedPortionIndex]
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

        let exactMatch = currentProduct.portions.enumerated()
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

    private func persistBarcode(_ barcode: String) {
        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedBarcode.isEmpty == false else {
            barcodeSaveMessage = "Voer eerst een geldige barcode in."
            return
        }

        isSavingBarcode = true
        foodModel.saveProductBarcode(for: currentProduct, barcode: trimmedBarcode) { success in
            isSavingBarcode = false
            if success {
                currentProduct.barcodes = Array(Set(currentProduct.barcodes + [trimmedBarcode])).sorted()
                barcodeDraft = trimmedBarcode
            } else {
                barcodeSaveMessage = "De barcode kon niet worden opgeslagen."
            }
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
