//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI
import Firebase

struct SlimProductOverview : View {
    
    @State var searchText = ""
    @State var searching = false
    @EnvironmentObject var foodModel : FoodDataModel
    @State var showAddProduct: Bool = false
    @State var filteredProducts : [SlimProduct]?
    
    func delete(at offsets: IndexSet) {

        let index = offsets[offsets.startIndex]
        let documentID:String = filteredProducts![index].documentID
        
        //Remove
        self.foodModel.deleteProduct(documentID: documentID)
        
        //Filter the array again
        self.filterProducts()
        
        //Remove it now
        self.filteredProducts?.remove(at: index)
    }
    
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
                                ManageProductRow(product: product)
                            }.onDelete(perform: delete)
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

struct ManageProductRow: View{
    @State var product: SlimProduct
    @State var showManageProductDetailView: Bool = false
    
    var body: some View{
        ZStack{
            Button(""){}
            NavigationLink(destination:ManageProductDetailView(documentID: product.documentID, showManageProductDetailView: $showManageProductDetailView),isActive:$showManageProductDetailView){
                Text(product.name)
                    .foregroundColor(Color.init("blackWhite"))
            }
        }
    }
}
