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
    
    @State private var searchText = ""
    @EnvironmentObject var foodModel : FoodDataModel
    @State private var showAddProduct: Bool = false
    
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
        .sheet(isPresented: $showAddProduct, content: { AddProductView(showAddProduct: $showAddProduct) })
        .toolbar(content: {
            Button(action: {
                self.showAddProduct.toggle()
            }) {
                Text("Nieuw").foregroundColor(Color.accentColor)
            }
        })
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
