//
//  AddProductView.swift
//  Grow
//
//  Created by Melle Wittebrood on 19/08/2021.
//

import SwiftUI

struct ProductEditorView: View {
    @EnvironmentObject private var foodModel: FoodDataModel
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
    @State private var showBarcodeScanner = false
    @State private var isFetchingBarcodeProduct = false
    @State private var hasLoadedInitialBarcode = false
    @State private var barcodeLookupAlertMessage: String?
    @State private var manualBarcodeInput: String = ""

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
        ZStack {
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

                Section("Barcodes") {
                    if product.barcodes.isEmpty {
                        Text("Nog geen barcodes toegevoegd")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(product.barcodes, id: \.self) { barcode in
                            Label(barcode, systemImage: "barcode")
                        }
                        .onDelete(perform: deleteBarcode)
                    }

                    Button {
                        showBarcodeScanner = true
                    } label: {
                        Label("Scan barcode", systemImage: "barcode.viewfinder")
                    }

                    HStack {
                        TextField("Voer barcode in", text: $manualBarcodeInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)

                        Button("Voeg toe") {
                            addManualBarcode()
                        }
                        .disabled(manualBarcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            .disabled(isFetchingBarcodeProduct)
            .blur(radius: isFetchingBarcodeProduct ? 1.5 : 0)
            .onTapGesture {
                hideKeyboard()
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(product.name.isEmpty ? "Product" : product.name))
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerSheet { barcode in
                    applyScannedBarcode(barcode)
                }
            }
            .alert("Barcode import", isPresented: Binding(
                get: { barcodeLookupAlertMessage != nil },
                set: { newValue in
                    if newValue == false {
                        barcodeLookupAlertMessage = nil
                    }
                }
            )) {
                Button("Ok", role: .cancel) {
                    barcodeLookupAlertMessage = nil
                }
            } message: {
                Text(barcodeLookupAlertMessage ?? "")
            }
            .onAppear {
                let shouldFetchInitialBarcode = (product.documentID?.isEmpty != false) && product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                guard shouldFetchInitialBarcode, hasLoadedInitialBarcode == false, let barcode = product.barcodes.first, barcode.isEmpty == false else {
                    return
                }

                hasLoadedInitialBarcode = true
                fetchProductForBarcode(barcode)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showBarcodeScanner = true
                    } label: {
                        if isFetchingBarcodeProduct {
                            ProgressView()
                        } else {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }

                    Button(saveButtonTitle) {
                        if onSave(product) {
                            onSuccess()
                        }
                    }
                    .disabled(product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetchingBarcodeProduct)
                }
            }

            if isFetchingBarcodeProduct {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.15)
                    Text("Productgegevens ophalen...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
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

    private func deleteBarcode(at offsets: IndexSet) {
        product.barcodes.remove(atOffsets: offsets)
    }

    private func addManualBarcode() {
        let trimmedBarcode = manualBarcodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedBarcode.isEmpty == false else {
            return
        }

        manualBarcodeInput = ""
        applyScannedBarcode(trimmedBarcode)
    }

    private func applyScannedBarcode(_ barcode: String) {
        product.barcodes = Array(Set(product.barcodes + [barcode])).sorted()
        let shouldFetchProductDetails = (product.documentID?.isEmpty != false) && product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if shouldFetchProductDetails {
            fetchProductForBarcode(barcode)
        }
    }

    private func fetchProductForBarcode(_ barcode: String) {
        isFetchingBarcodeProduct = true
        foodModel.fetchOpenFoodFactsProduct(barcode: barcode) { fetchedProduct in
            isFetchingBarcodeProduct = false

            guard let fetchedProduct else {
                barcodeLookupAlertMessage = "Geen product gevonden in Open Food Facts. Je kunt de gegevens handmatig invullen."
                return
            }

            product.barcodes = Array(Set(product.barcodes + [barcode] + fetchedProduct.barcodes)).sorted()
            product.imageURL = fetchedProduct.imageURL
            product.name = fetchedProduct.name
            product.kcal = fetchedProduct.kcal
            product.carbs = fetchedProduct.carbs
            product.protein = fetchedProduct.protein
            product.fat = fetchedProduct.fat
            product.fiber = fetchedProduct.fiber
            product.portions = fetchedProduct.portions

            kcalInput = NumberHelper.roundedNumbersFromDouble(unit: fetchedProduct.kcal)
            carbsInput = NumberHelper.roundNumbersMaxTwoDecimals(unit: fetchedProduct.carbs)
            proteinInput = NumberHelper.roundNumbersMaxTwoDecimals(unit: fetchedProduct.protein)
            fatInput = NumberHelper.roundNumbersMaxTwoDecimals(unit: fetchedProduct.fat)
            fiberInput = NumberHelper.roundNumbersMaxTwoDecimals(unit: fetchedProduct.fiber)
        }
    }
}

struct AddProductView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var showAddProduct: Bool
    var initialProduct: Product = Product()

    var body: some View {
        NavigationStack {
            ProductEditorView(product: initialProduct, saveButtonTitle: "Opslaan") { product in
                foodModel.createProduct(product: product)
            } onSuccess: {
                showAddProduct = false
            }
            .navigationTitle("Product toevoegen")
        }
        .accentColor(Color("AccentColor"))
    }
}
