//
//  AddProductOverview.swift
//  Grow
//
//  Created by Swen Rolink on 28/03/2022.
//

import SwiftUI

struct AddProductToMealList: View {
    
    @State var meal: Meal
    @Binding var navigationAction: Int?
    
    @State var searchText = ""
    @State var searching = false
    @EnvironmentObject var foodModel : FoodDataModel
    @State var filteredProducts : [SlimProduct]?
    @State var showAddProduct: Bool = false
    
    
    func filterProducts(){
        self.filteredProducts = self.foodModel.slimProductList.products.filter { product in
          return product.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
        }
        
        self.filteredProducts = self.filteredProducts?.sorted { $0.name < $1.name }
    }
        
        var body: some View {
                VStack{
                    List {
                        let customSearchText = Binding<String> {
                            self.searchText
                        } set: { text in
                            self.searchText = text
                            filterProducts()
                        }

                        SearchBar(searchText: customSearchText, searching: $searching)
                        if filteredProducts != nil {
                            ForEach(filteredProducts!, id: \.self) { product in
                                AddProductRow(product: product, navigationAction: $navigationAction, meal: meal, documentID: product.documentID)
                                }
                           }
                    }
                }
                .onAppear(perform: {
                    filterProducts()
                })
                .listStyle(InsetGroupedListStyle())
                .sheet(isPresented: $showAddProduct, content: {AddProductView(showAddProduct: $showAddProduct)})
                    .toolbar(content: {Button(action: {
                        self.showAddProduct.toggle()
                    }) {
                        Text("Nieuw").foregroundColor(Color.accentColor)
                    }})
        }
    }


struct AddProductRow: View{
    @State var product: SlimProduct
    @Binding var navigationAction: Int?
    @State var meal: Meal
    @State var documentID: String
    @State var showProductDetailView: Bool = false
    
    var body: some View{
        ZStack{
            Button(""){}
            NavigationLink(destination:ProductDetailView(meal: meal, documentID: documentID, navigationAction: $navigationAction)){
                Text(product.name)
                    .foregroundColor(Color.init("blackWhite"))
            }
        }
    }
}
