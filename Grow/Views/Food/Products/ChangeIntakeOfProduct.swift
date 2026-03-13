//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ChangeIntakeOfProduct: View {
    
    @EnvironmentObject var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss
    @State var product:Product
    @State var meal: Meal
    @State var amount: String
    @State private var amountInput: String = ""
    @State private var selectedPortionIndex = 0
    @State private var portionCountText: String = ""
    
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

    private var selectedPortion: ProductPortion? {
        guard product.portions.indices.contains(selectedPortionIndex) else {
            return nil
        }

        return product.portions[selectedPortionIndex]
    }

    private var portionCount: Int {
        if let value = NumberFormatter().number(from: portionCountText) {
            return max(value.intValue, 1)
        }

        return 1
    }

    private func applySelectedPortion() {
        guard let selectedPortion else {
            return
        }

        let totalAmount = selectedPortion.amount * portionCount
        amountInput = ""
        amount = String(totalAmount)
        updateCalories(portion: totalAmount)
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { amountInput },
            set: { newValue in
                amountInput = newValue

                if let value = NumberFormatter().number(from: newValue) {
                    amount = String(value.intValue)
                    updateCalories(portion: value.intValue)
                } else if newValue.isEmpty {
                    applySelectedPortion()
                }
            }
        )
    }

    private func configureSelectionFromExistingAmount() {
        guard let currentAmount = NumberFormatter().number(from: amount)?.intValue else {
            applySelectedPortion()
            return
        }

        let exactMatch = product.portions.enumerated()
            .filter { _, portion in
                portion.amount > 0 && currentAmount % portion.amount == 0
            }
            .max { lhs, rhs in
                lhs.element.amount < rhs.element.amount
            }

        if let exactMatch {
            selectedPortionIndex = exactMatch.offset
            let count = max(currentAmount / exactMatch.element.amount, 1)
            portionCountText = count == 1 ? "" : String(count)
            applySelectedPortion()
        } else {
            selectedPortionIndex = 0
            portionCountText = ""
            updateCalories(portion: currentAmount)
        }
    }
    
    var body: some View {
        Form{
            Section{
                HStack{
                    Picker("Portie", selection: $selectedPortionIndex) {
                        ForEach(Array(product.portions.enumerated()), id: \.offset) { index, portion in
                            Text("\(portion.name) (\(portion.amount) g)").tag(index)
                        }
                    }
                }
                HStack{
                    Text("Aantal porties")
                    Spacer()
                    TextField("", text: $portionCountText, prompt: Text("1"))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack{
                    Text("Portiegrootte (g)")
                    Spacer()
                    TextField("", text: amountBinding, prompt: Text(amount))
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
                    dismiss()
                }
            }
            

        }})
        .onAppear(perform:{
            self.configureSelectionFromExistingAmount()
        })
        .onChange(of: selectedPortionIndex) { _, _ in
            applySelectedPortion()
        }
        .onChange(of: portionCountText) { _, _ in
            applySelectedPortion()
        }
    }
}
