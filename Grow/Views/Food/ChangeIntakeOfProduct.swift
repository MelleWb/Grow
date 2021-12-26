//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ChangeIntakeOfProduct: View {
    
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var showChangeIntake: Bool
    @State var product:Product
    @State var meal: Meal
    @State var amount: String
    @State var amountInput: String = ""
    @State var amountPlaceHolder : String = ""
    
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
            get: {
                if amountPlaceHolder == amount {
                 return ""
                } else {
                    return amount
                }
            },
            set: {
                amount = $0
                if let value = NumberFormatter().number(from: $0) {
                    self.updateCalories(portion: value.intValue)
                }
            }
        )
        
        Form{
            Section{
                HStack{
                    Picker(selection: amountProxy, label: Text("Maatvoering")) {
                        ForEach(self.product.portions, id:\.self){ portion in
                            Text(portion.name).tag(String(portion.amount))
                        }
                    }
                }
                HStack{
                    Text("Portiegrootte (g)")
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
        .toolbar(content: {Button("Sla op"){
            //Update the root
            
            if let value = NumberFormatter().number(from: amount) {
                let createdProduct:SelectedProductDetails = SelectedProductDetails(kcal: self.calories, carbs: self.carbs, protein: self.protein, fat: self.fat, fiber: self.fiber, amount: value.intValue)
        
                let success = self.foodModel.updateProductInMeal(for: meal, with: self.product, with: createdProduct)
                
                if success {
                    self.showChangeIntake = false
                }
            }
            

        }})
        .onAppear(perform:{
            
            //Test
            print(NumberHelper.roundNumbersMaxTwoDecimals(unit: 10.1234))
            print(NumberHelper.roundNumbersMaxTwoDecimals(unit: 10.00))
            print(NumberHelper.roundNumbersMaxTwoDecimals(unit: 10.01))
            print(NumberHelper.roundNumbersMaxTwoDecimals(unit: 10.1))
            //set the placeholder equal to amount
            self.amountPlaceHolder = amount
            
            self.showChangeIntake = true
            if let value = NumberFormatter().number(from: amount) {
                self.updateCalories(portion: value.intValue)
            }
        })
    }
}
