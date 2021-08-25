//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ProductDetailView: View {
    
    @Binding var shouldPopToRoot: Bool
    @State var product:Product
    @State var meal: Meal
    @State var amount: String = "100"
    
    @State var calories: Int = 0
    @State var carbs: Int = 0
    @State var protein: Int = 0
    @State var fat: Int = 0
    @State var fiber: Int = 0
    
    func calculation(unit: Int, portion: Int) -> Int {
        let per100gram:Int = unit
        let per1gram:Double = Double(per100gram) / 100
        return Int((Double(per1gram) * Double(portion)).rounded())
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
            get: { amount },
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
                    Text(String(calories))
                }
                HStack{
                    Text("Koolhydraten")
                    Spacer()
                    Text(String(carbs))
                }
                HStack{
                    Text("Eiwitten")
                    Spacer()
                    Text(String(protein))
                }
                HStack{
                    Text("Vetten")
                    Spacer()
                    Text(String(fat))
                }
                HStack{
                    Text("Vezels")
                    Spacer()
                    Text(String(fiber))
                }
            }.onTapGesture {
                hideKeyboard()
            }
        }.navigationTitle(Text(product.name))
        .toolbar(content: {Button("Voeg toe"){self.shouldPopToRoot = false}})
        .onAppear(perform:{
            if let value = NumberFormatter().number(from: amount) {
                self.updateCalories(portion: value.intValue)
            }
        })
    }
}
