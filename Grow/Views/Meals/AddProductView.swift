//
//  AddProductView.swift
//  Grow
//
//  Created by Melle Wittebrood on 19/08/2021.
//

import SwiftUI
import Firebase

struct AddProductView: View {
    @EnvironmentObject var foodModel : FoodDataModel
    @State var product: Product = Product()
    let unit = ["Grammen", "Milimeters"]
    @State var showProductsNutritionView: Bool = false
    @Binding var showAddProduct: Bool
    
    @State var portionName: String = ""
    @State var portionAmount: String = ""
    
    var body: some View {
        NavigationView{
            if showProductsNutritionView {
                NavigationLink(
                    destination: NewProductsNutritionView(product: product, showProductsNutritionView: $showProductsNutritionView, showAddProduct: $showAddProduct),
                            isActive: $showProductsNutritionView
                        ) {}.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
            }
            
            Form{
                Section{
                   HStack{
                    Text("Naam")
                    TextField("Voer de naam in", text: $product.name)
                        .multilineTextAlignment(.trailing)
                    }
                    HStack{
                        ZStack{
                        Button("", action:{})
                            Picker("Eenheid", selection: $product.unit) {
                                        ForEach(unit, id: \.self) {
                                            Text($0)
                                        }
                                    }
                        }
                    }
                }
                if self.product.portions.count > 1 {
                    Section(header:Text("Portiegroottes")){
                        List{
                            ForEach(self.product.portions, id:\.self){ portion in
                                    HStack{
                                        Text(portion.name)
                                        Spacer()
                                        Text("\(portion.amount) gram")
                                }
                            }.onDelete(perform: deletePortion)
                        }
                    }
                }
                
                Section(header:Text("Voeg portiegrootte toe")){
                    
                    HStack{
                        TextField("Portienaam", text:$portionName)
                            .multilineTextAlignment(.leading)
                            .frame(height:40)
                        TextField("Portiegrootte", text:$portionAmount)
                            .multilineTextAlignment(.trailing)
                            .frame(height:40)
                    }
                        Button(action:{
                            var amountNumber: Int = 0
                            if let value = NumberFormatter().number(from: portionAmount) {
                                amountNumber = value.intValue
                            }
                            self.product.portions.append(ProductPortion(name: portionName, amount:amountNumber))
                            self.portionName = ""
                            self.portionAmount = ""
                            
                        },label:{
                            HStack{
                                Image(systemName:"plus")
                                Text("Voeg portie toe")
                            }
                        })
                    }
        }.listStyle(InsetGroupedListStyle())
            .navigationTitle(Text(self.product.name))
            .navigationBarItems(trailing:
                                    Button(action: {self.showProductsNutritionView = true}) { Text("Volgende") }
                                    .disabled(self.product.name.isEmpty)
        )}
        }

    func deletePortion(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.product.portions.remove(at: index)
    }
    
}
