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
    
    func calculateKcal(){
        self.product.kcal = 0
        
        let calcCarbs = self.product.carbs * 4
        let calcProtein = self.product.protein * 4
        let calcFat = self.product.fat * 9
        let calcFiber = self.product.fiber * 2
        
        self.product.kcal = calcCarbs + calcProtein + calcFat + calcFiber
    }
    
    var body: some View {
        VStack{
        let kcalBinding = Binding<String>(
            get: {
                if self.product.kcal == 0 {
                return ""
            } else {
                return String(self.product.kcal)
            }
            },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.kcal = value.intValue
                } else {
                    self.product.kcal = 0
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
                } else {
                    self.product.carbs = 0
                }
                calculateKcal()
            })
        
        let proteinBinding = Binding<String>(
            get: { if self.product.protein == 0 {
                return ""
            } else{
                return String(self.product.protein)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.protein = value.intValue
                }else {
                    self.product.protein = 0
                }
                calculateKcal()
            })
        
        let fatBinding = Binding<String>(
            get: { if self.product.fat == 0 {
                return ""
            } else {
                return String(self.product.fat)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.fat = value.intValue
                }else {
                    self.product.fat = 0
                }
                calculateKcal()
            })
        
        let fiberBinding = Binding<String>(
            get: { if self.product.fiber == 0 {
                return ""
            } else {
                return String(self.product.fiber)
            }},
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.product.fiber = value.intValue
                }else {
                    self.product.fiber = 0
                }
                calculateKcal()
            })
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
