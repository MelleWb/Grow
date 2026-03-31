//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI

struct SlimProductOverview : View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @EnvironmentObject var foodModel : FoodDataModel
    @State private var showAddProduct: Bool = false
    @State private var showBarcodeScanner = false
    @State private var scannedProductDocumentID: String?
    @State private var scannedBarcodeForNewProduct: String?
    @State private var prefilledScannedProduct = Product()
    @State private var barcodeMatches = [Product]()
    
    func delete(at offsets: IndexSet) {

        let index = offsets[offsets.startIndex]
        let documentID:String = filteredProducts[index].documentID
        
        //Remove
        self.foodModel.deleteProduct(documentID: documentID)
    }
    
    private var filteredProducts: [SlimProduct] {
        let products = self.foodModel.slimProductList.products.filter { product in
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
                        ManageProductRow(product: product)
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Producten")
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
                dismiss()
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
                ManageProductDetailView(documentID: scannedProductDocumentID)
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

struct ManageProductRow: View{
    @State var product: SlimProduct
    
    var body: some View{
        ZStack{
            Button(""){}
            NavigationLink(destination: ManageProductDetailView(documentID: product.documentID)){
                Text(product.name)
                    .foregroundColor(Color.init("blackWhite"))
            }
        }
    }
}
