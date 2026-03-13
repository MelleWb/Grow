//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI

struct SlimProductOverview : View {
    
    @State private var searchText = ""
    @EnvironmentObject var foodModel : FoodDataModel
    @State private var showAddProduct: Bool = false
    
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
