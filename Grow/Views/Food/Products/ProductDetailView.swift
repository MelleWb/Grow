//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ProductDetailView: View {
    
    @EnvironmentObject var foodModel: FoodDataModel
    
    @State var product:Product = Product()
    
    @State var meal: Meal
    @State var documentID:String
    @Binding var navigationAction: Int?
    
    
    @State var amount: String = "100"
    @State var amountInput: String = ""
    @State var portionAmount: Int = 1
    
    @State var calories: Double = 0
    @State var carbs: Double = 0
    @State var protein: Double = 0
    @State var fat: Double = 0
    @State var fiber: Double = 0
    
    func calculation(unit: Double, portion: Int) -> Double {
        let per100gram:Double = unit
        let per1gram:Double = Double(per100gram) / 100
        return (Double(per1gram) * Double(portion)).rounded()
    }
    
    func updateCalories(portion: Int){
        self.calories = calculation(unit: product.kcal, portion: portion)
        self.carbs = calculation(unit: product.carbs, portion: portion)
        self.protein = calculation(unit: product.protein, portion: portion)
        self.fat = calculation(unit: product.fat, portion: portion)
        self.fiber = calculation(unit: product.fiber, portion: portion)
    }
    
    var body: some View {
        
        let amountProxy = Binding<String>(
            get: { amountInput },
            set: {
                amount = $0
                amountInput = $0
                if let value = NumberFormatter().number(from: $0) {
                    self.updateCalories(portion: value.intValue)
                }
            }
        )
        
        Form{
            Section{
                HStack{
                    Picker(selection: amountProxy, label: Text("Portie")) {
                        ForEach(self.product.portions, id:\.self){ portion in
                            Text(portion.name).tag(String(portion.amount))
                        }
                    }
                }
                HStack{
                    Text("Aantal grammen")
                    Spacer()
                    TextField(amount, text: amountProxy)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section(header:Text("Nutriënten per \(amount) g")){
                HStack{
                    Text("Calorieën")
                    Spacer()
                    Text(NumberHelper.roundedNumbersFromDouble(unit:calories))
                }
                HStack{
                    Text("Koolhydraten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit:carbs))
                }
                HStack{
                    Text("Eiwitten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit:protein))
                }
                HStack{
                    Text("Vetten")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit:fat))
                }
                HStack{
                    Text("Vezels")
                    Spacer()
                    Text(NumberHelper.roundNumbersMaxTwoDecimals(unit:fiber))
                }
            }.onTapGesture {
                hideKeyboard()
            }
        }.navigationTitle(Text(product.name))
        .toolbar(content: {Button("Voeg toe"){
            //Update the root
            
            if let value = NumberFormatter().number(from: amount) {
                let createdProduct:SelectedProductDetails = SelectedProductDetails(kcal: self.calories, carbs: self.carbs, protein: self.protein, fat: self.fat, fiber: self.fiber, amount: value.intValue)
        
                let success = self.foodModel.addProductToMeal(for: meal, with: self.product, with: createdProduct)
                
                if success {
                        self.navigationAction = 0
                }
            }
            

        }})
        .onAppear(perform:{
            
        })
        .onAppear(perform:{
            
            //First get the product details
            self.foodModel.getProductDetails(documentID: documentID, completion: { product, error in
                if let product = product {
                    self.product = product
                    
                    if let value = NumberFormatter().number(from: amount) {
                        self.updateCalories(portion: value.intValue)
                    }
                    
                } else {
                    self.navigationAction = 0
                }
                })
            })
    }
}
