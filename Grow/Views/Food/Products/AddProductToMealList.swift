//
//  AddProductOverview.swift
//  Grow
//
//  Created by Swen Rolink on 28/03/2022.
//

import SwiftUI

struct AddProductToMealList: View {
    
    @State var meal: Meal
    @Binding var isPresented: Bool
    var startWithScanner: Bool = false
    
    @State private var searchText = ""
    @EnvironmentObject var foodModel : FoodDataModel
    @State private var showAddProduct: Bool = false
    @State private var showBarcodeScanner = false
    @State private var scannedProductDocumentID: String?
    @State private var scannedBarcodeForNewProduct: String?
    @State private var prefilledScannedProduct = Product()
    @State private var barcodeMatches = [Product]()
    @State private var hasTriggeredInitialScanner = false
    
    private var filteredProducts: [SlimProduct] {
        let products = foodModel.slimProductList.products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty
        }

        return products.sorted { $0.name < $1.name }
    }
        
    var body: some View {
        List {
            Section {
                PickerSearchBar(text: $searchText, placeholder: "Product zoeken")
                    .listRowInsets(EdgeInsets())
            }

            Section("Beschikbare producten") {
                if filteredProducts.isEmpty {
                    ContentUnavailableView(
                        "Geen producten gevonden",
                        systemImage: "magnifyingglass",
                        description: Text("Pas je zoekterm aan of voeg een nieuw product toe.")
                    )
                } else {
                    ForEach(filteredProducts, id: \.self) { product in
                        AddProductRow(product: product, isPresented: $isPresented, meal: meal, documentID: product.documentID)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Product kiezen")
        .onAppear {
            guard startWithScanner, hasTriggeredInitialScanner == false else {
                return
            }

            hasTriggeredInitialScanner = true
            showBarcodeScanner = true
        }
        .sheet(isPresented: $showAddProduct, content: {
            AddProductView(showAddProduct: $showAddProduct, initialProduct: prefilledScannedProduct)
        })
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerSheet { barcode in
                handleScannedBarcode(barcode)
            }
        }
        .sheet(isPresented: Binding(
            get: { barcodeMatches.isEmpty == false },
            set: { newValue in
                if newValue == false {
                    barcodeMatches = []
                }
            }
        )) {
            NavigationStack {
                List {
                    Section("Meerdere producten gevonden") {
                        ForEach(barcodeMatches, id: \.id) { product in
                            Button {
                                scannedProductDocumentID = product.documentID
                                barcodeMatches = []
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .foregroundColor(Color("blackWhite"))
                                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: product.kcal)) kcal per 100 g")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Kies product")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Sluit") {
                            barcodeMatches = []
                        }
                    }
                }
            }
        }
        .alert("Product niet gevonden", isPresented: Binding(
            get: { scannedBarcodeForNewProduct != nil },
            set: { newValue in
                if newValue == false {
                    scannedBarcodeForNewProduct = nil
                }
            }
        )) {
            Button("Annuleer", role: .cancel) {
                scannedBarcodeForNewProduct = nil
                isPresented = false
            }
            Button("Toevoegen") {
                prefilledScannedProduct = Product(barcode: scannedBarcodeForNewProduct)
                scannedBarcodeForNewProduct = nil
                showAddProduct = true
            }
        } message: {
            Text("Dit product staat nog niet in Grow. Wil je het toevoegen?")
        }
        .navigationDestination(isPresented: Binding(
            get: { scannedProductDocumentID != nil },
            set: { newValue in
                if newValue == false {
                    scannedProductDocumentID = nil
                }
            }
        )) {
            if let scannedProductDocumentID {
                ProductDetailView(meal: meal, documentID: scannedProductDocumentID, isPresented: $isPresented)
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    showBarcodeScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundColor(.accentColor)
                }

                Button(action: {
                    prefilledScannedProduct = Product()
                    self.showAddProduct.toggle()
                }) {
                    Text("Nieuw").foregroundColor(Color.accentColor)
                }
            }
        })
    }

    private func handleScannedBarcode(_ barcode: String) {
        foodModel.findProducts(for: barcode) { products in
            if products.isEmpty {
                scannedBarcodeForNewProduct = barcode
            } else if products.count == 1 {
                scannedProductDocumentID = products.first?.documentID
            } else {
                barcodeMatches = products
            }
        }
    }
}


struct AddProductRow: View{
    @State var product: SlimProduct
    @Binding var isPresented: Bool
    @State var meal: Meal
    @State var documentID: String
    
    var body: some View{
        ZStack{
            Button(""){}
            NavigationLink(destination: ProductDetailView(meal: meal, documentID: documentID, isPresented: $isPresented)){
                Text(product.name)
                    .foregroundColor(Color.init("blackWhite"))
            }
        }
    }
}
