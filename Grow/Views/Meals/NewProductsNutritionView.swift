//
//  NewProductKcalView.swift
//  Grow
//
//  Created by Melle Wittebrood on 21/08/2021.
//

import SwiftUI

struct NewProductsNutritionView: View {
    @EnvironmentObject var foodModel : FoodDataModel
    @State var product: Product
    @Binding var showProductsNutritionView: Bool
    @Binding var showAddProduct: Bool
    @State var showAlert: Bool = false
    
    var body: some View {
        VStack{
        let kcalBinding = Binding<String>(
            get: { if self.product.kcal == 0 {
                return ""
            } else {
                return String(self.product.kcal)
            }
            },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.kcal = value.intValue
                }})
        
        let carbsBinding = Binding<String>(
            get: { if self.product.carbs == 0 {
                return ""
            } else {
                return String(self.product.carbs)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.carbs = value.intValue
                }})
        
        let proteinBinding = Binding<String>(
            get: { if self.product.protein == 0 {
                return ""
            } else{
                return String(self.product.protein)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.protein = value.intValue
                }})
        
        let fatBinding = Binding<String>(
            get: { if self.product.fat == 0 {
                return ""
            } else {
                return String(self.product.fat)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.fat = value.intValue
                }})
        
        let fiberBinding = Binding<String>(
            get: { if self.product.fiber == 0 {
                return ""
            } else {
                return String(self.product.fiber)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.fiber = value.intValue
                }})
            VStack{
                Form{
                    Section(header:Text("Nutrienten per 100 gram")){
                       HStack{
                        Text("Calorieën")
                        TextField("", text: kcalBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                        HStack{
                            Text("Koolhydraten (g)")
                            TextField("", text: carbsBinding)
                            .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                        HStack{
                            Text("Eiwitten (g)")
                            TextField("", text: proteinBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                        HStack{
                            Text("Vetten (g)")
                            TextField("", text: fatBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                        HStack{
                            Text("Vezels (g)")
                            TextField("", text: fiberBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                    }
                }
        }.alert(isPresented: $showAlert){
            Alert(title: Text("Oops"), message: Text("Iets ging er fout"), dismissButton: .default(Text("Ok!")))
        }.onTapGesture {
            hideKeyboard()
        }
        .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text(self.product.name))
        .navigationBarItems(trailing:
                                Button(action: {
                                    let success = self.foodModel.createProduct(product: product)
                                        if success {
                                            self.showAddProduct = false
                                            self.showProductsNutritionView = false
                                        } else {
                                            self.showAlert = true
                                        }
                                }) { Text("Opslaan") }
                                .disabled(self.product.kcal == 0)
        )}
        }
}
