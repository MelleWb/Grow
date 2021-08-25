//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI

struct AddMealView : View {
    
    @State var meal: Meal
    @State var searchText = ""
    @State var searching = false
    @EnvironmentObject var foodModel : FoodDataModel
    @State var showAddProduct: Bool = false
    @Binding var showAddMeal: Bool
    
    var body: some View {
        VStack{
        List {
                SearchBar(searchText: $searchText, searching: $searching)
                ForEach(foodModel.products.filter({ (product: Product) -> Bool in
                    return product.name.hasPrefix(searchText) || searchText == ""
                }), id: \.self) { product in
                    ZStack{
                        Button(""){}
                        NavigationLink(destination:ProductDetailView(shouldPopToRoot: $showAddMeal, product: product, meal: meal)){
                                    Text(product.name)
                        }.isDetailLink(false)
                    }
                }
           }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform:{self.foodModel.fetchProducts()})
                .sheet(isPresented: $showAddProduct, content: {AddProductView(showAddProduct: $showAddProduct)})
            .toolbar(content: {Button(action: {
                self.showAddProduct = true
            }) {
                Text("Nieuw").foregroundColor(Color.init("textColor"))
            }})
    }
}
