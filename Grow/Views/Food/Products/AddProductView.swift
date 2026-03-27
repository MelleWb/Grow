//
//  AddProductView.swift
//  Grow
//
//  Created by Melle Wittebrood on 19/08/2021.
//

import SwiftUI

struct ProductEditorView: View {
    let saveButtonTitle: String
    let onSave: (Product) -> Bool
    let onSuccess: () -> Void

    @State private var product: Product
    @State private var portionName: String = ""
    @State private var portionAmount: String = ""
    @State private var kcalInput: String
    @State private var carbsInput: String
    @State private var proteinInput: String
    @State private var fatInput: String
    @State private var fiberInput: String

    private let units = ["Grammen", "Milliliters"]

    init(
        product: Product = Product(),
        saveButtonTitle: String,
        onSave: @escaping (Product) -> Bool,
        onSuccess: @escaping () -> Void
    ) {
        self.saveButtonTitle = saveButtonTitle
        self.onSave = onSave
        self.onSuccess = onSuccess
        _product = State(initialValue: product)
        _kcalInput = State(initialValue: NumberHelper.roundedNumbersFromDouble(unit: product.kcal))
        _carbsInput = State(initialValue: NumberHelper.roundNumbersMaxTwoDecimals(unit: product.carbs))
        _proteinInput = State(initialValue: NumberHelper.roundNumbersMaxTwoDecimals(unit: product.protein))
        _fatInput = State(initialValue: NumberHelper.roundNumbersMaxTwoDecimals(unit: product.fat))
        _fiberInput = State(initialValue: NumberHelper.roundNumbersMaxTwoDecimals(unit: product.fiber))
    }

    var body: some View {
        Form {
            Section("Basis") {
                HStack {
                    Text("Naam")
                    TextField("Voer de naam in", text: $product.name)
                        .multilineTextAlignment(.trailing)
                }

                Picker("Eenheid", selection: $product.unit) {
                    ForEach(units, id: \.self) {
                        Text($0)
                    }
                }
            }

            if product.portions.count > 1 {
                Section("Portiegroottes") {
                    ForEach(product.portions, id: \.self) { portion in
                        HStack {
                            Text(portion.name)
                            Spacer()
                            Text("\(portion.amount) gram")
                        }
                    }
                    .onDelete(perform: deletePortion)
                }
            }

            Section("Voeg portiegrootte toe") {
                HStack {
                    TextField("Portienaam", text: $portionName)
                        .multilineTextAlignment(.leading)
                        .frame(height: 40)
                    TextField("Portiegrootte", text: $portionAmount)
                        .multilineTextAlignment(.trailing)
                        .frame(height: 40)
                        .keyboardType(.numberPad)
                }

                Button(action: addPortion) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Voeg portie toe")
                    }
                }
            }

            Section("Nutriënten per 100 gram") {
                macroRow(title: "Calorieën", text: $kcalInput) { value in
                    product.kcal = value
                    calculateKcal()
                }
                macroRow(title: "Koolhydraten (g)", text: $carbsInput) { value in
                    product.carbs = value
                    calculateKcal()
                }
                macroRow(title: "Eiwitten (g)", text: $proteinInput) { value in
                    product.protein = value
                    calculateKcal()
                }
                macroRow(title: "Vetten (g)", text: $fatInput) { value in
                    product.fat = value
                    calculateKcal()
                }
                macroRow(title: "Vezels (g)", text: $fiberInput) { value in
                    product.fiber = value
                    calculateKcal()
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text(product.name.isEmpty ? "Product" : product.name))
        .toolbar {
            Button(saveButtonTitle) {
                if onSave(product) {
                    onSuccess()
                }
            }
            .disabled(product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func macroRow(
        title: String,
        text: Binding<String>,
        onValueChanged: @escaping (Double) -> Void
    ) -> some View {
        HStack {
            Text(title)
            TextField(text.wrappedValue, text: Binding(
                get: { text.wrappedValue },
                set: { newValue in
                    text.wrappedValue = newValue
                    if let value = NumberFormatter().number(from: newValue) {
                        onValueChanged(value.doubleValue)
                    }
                }
            ))
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
        }
    }

    private func calculateKcal() {
        product.kcal = (product.carbs * 4) + (product.protein * 4) + (product.fat * 9) + (product.fiber * 2)
        kcalInput = NumberHelper.roundedNumbersFromDouble(unit: product.kcal)
    }

    private func addPortion() {
        guard
            !portionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let value = NumberFormatter().number(from: portionAmount)
        else {
            return
        }

        product.portions.append(ProductPortion(name: portionName, amount: value.intValue))
        portionName = ""
        portionAmount = ""
    }

    private func deletePortion(at offsets: IndexSet) {
        let index = offsets[offsets.startIndex]
        product.portions.remove(at: index)
    }
}

struct AddProductView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var showAddProduct: Bool

    var body: some View {
        NavigationStack {
            ProductEditorView(saveButtonTitle: "Opslaan") { product in
                foodModel.createProduct(product: product)
            } onSuccess: {
                showAddProduct = false
            }
            .navigationTitle("Product toevoegen")
        }
        .accentColor(Color("AccentColor"))
    }
}
