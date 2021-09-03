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
        
        let kcalBinding = Binding<String>(get: {self.kcalInput},
                                          set: { kcal in
                                            if let value = NumberFormatter().number(from: kcal) {
                                                self.product.kcal = value.doubleValue
                                                
                                            }
                                            calculateKcal()
                                            self.kcalInput = kcal
                                          })
        
            VStack{
                Form{
                    Section(header:Text("Nutrienten per 100 gram")){
                       HStack{
                        Text("Calorieën")
                        TextField($kcalInput.wrappedValue, text: kcalBinding)
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
