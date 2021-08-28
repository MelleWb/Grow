//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI
import Firebase

struct AddMealView : View {
    
    @State var meal: Meal
    @State var searchText = ""
    @State var searching = false
    @EnvironmentObject var foodModel : FoodDataModel
    @State var showAddProduct: Bool = false
    @Binding var showAddMeal: Bool
    
    func delete(at offsets: IndexSet) {
        
        let index = offsets[offsets.startIndex]
        let documentID:String = foodModel.products[index].documentID ?? ""
        print(documentID)
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        
        db.collection("foodProducts").document(documentID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                foodModel.products.remove(atOffsets: offsets)
            }
        }
    }
    
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
                }.onDelete(perform: delete)
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
