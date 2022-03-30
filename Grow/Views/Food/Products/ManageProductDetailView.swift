//
//  ManageProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 28/03/2022.
//

import SwiftUI

struct ManageProductDetailView: View {
    
    @EnvironmentObject var foodModel : FoodDataModel
    @State var documentID: String
    @State var product: Product = Product()
    let unit = ["Grammen", "Milliliters"]
    @Binding var showManageProductDetailView: Bool

    @State var portionName: String = ""
    @State var portionAmount: String = ""
    @State var kcalInput: String = ""
    @State var carbsInput: String = ""
    @State var proteinInput: String = ""
    @State var fatInput: String = ""
    @State var fiberInput: String = ""
    
    func calculateKcal(){
        self.product.kcal = 0
        
        let calcCarbs = self.product.carbs * 4
        let calcProtein = self.product.protein * 4
        let calcFat = self.product.fat * 9
        let calcFiber = self.product.fiber * 2
        
        self.product.kcal = calcCarbs + calcProtein + calcFat + calcFiber
        self.kcalInput = NumberHelper.roundedNumbersFromDouble(unit: self.product.kcal)
    }
    
    var body: some View {
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
                            .keyboardType(.numberPad)
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
                Section(header:Text("Nutrienten per 100 gram")){
                   HStack{
                    Text("Calorieën")
                    TextField($kcalInput.wrappedValue, text: $kcalInput ,onEditingChanged: { _ in
                        if let value = NumberFormatter().number(from: kcalInput) {
                            self.product.kcal = value.doubleValue
                        }
                        calculateKcal()
                    })
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    }
                    HStack{
                        Text("Koolhydraten (g)")
                        TextField($carbsInput.wrappedValue, text: $carbsInput ,onEditingChanged: { _ in
                            if let value = NumberFormatter().number(from: carbsInput) {
                                self.product.carbs = value.doubleValue
                            }
                            calculateKcal()
                        })
                        .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack{
                        Text("Eiwitten (g)")
                        TextField($proteinInput.wrappedValue, text: $proteinInput ,onEditingChanged: { _ in
                            if let value = NumberFormatter().number(from: proteinInput) {
                                self.product.protein = value.doubleValue
                            }
                            calculateKcal()
                        })
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    }
                    HStack{
                        Text("Vetten (g)")
                        TextField($fatInput.wrappedValue, text: $fatInput ,onEditingChanged: { _ in
                            if let value = NumberFormatter().number(from: fatInput) {
                                self.product.fat = value.doubleValue
                            }
                            calculateKcal()
                        })
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    }
                    HStack{
                        Text("Vezels (g)")
                        TextField($fiberInput.wrappedValue, text: $fiberInput ,onEditingChanged: { _ in
                            if let value = NumberFormatter().number(from: fiberInput) {
                                self.product.fiber = value.doubleValue
                            }
                            calculateKcal()
                        })
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    }
                }
                
        }.onAppear(perform:{
            
            //First get the product details
            self.foodModel.getProductDetails(documentID: documentID, completion: { product, error in
                if let product = product {
                    self.product = product
                    
                    self.kcalInput = String(product.kcal)
                    self.carbsInput = String(product.carbs)
                    self.proteinInput = String(product.protein)
                    self.fatInput = String(product.fat)
                    self.fiberInput = String(product.fiber)
                    
                    calculateKcal()
                } else {
                    self.showManageProductDetailView.toggle()
                }
                })
            })
        
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text(self.product.name))
            .navigationBarItems(trailing:
                Button(action: {
                        let success = self.foodModel.createProduct(product: product)
                        if success {
                        self.showManageProductDetailView = false
                            
                        }
            }){
                Text("Opslaan")
            }.disabled(self.product.name.isEmpty)
        )}
    
    func deletePortion(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.product.portions.remove(at: index)
    }
    
}

//struct ManageProductDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ManageProductDetailView(product: Product(id: UUID(), documentID: "123", name: "Appel", kcal: 100, carbs: 25, protein: 12, fat: 4, fiber: 2, unit: "Grammen", portions: [ProductPortion()], selectedProductDetails: SelectedProductDetails(id: UUID(), kcal: 100, carbs: 25, protein: 12, fat: 4, fiber: 2, amount: 100)), showManageProductDetailView: Binding.constant(true))
//    }
//}
