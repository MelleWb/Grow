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
        
        let carbsBinding = Binding<String>(get: {self.carbsInput},
                                          set: { carbs in
                                            if let value = NumberFormatter().number(from: carbs) {
                                                self.product.carbs = value.doubleValue
                                                
                                            }
                                            calculateKcal()
                                            self.carbsInput = carbs
                                          })
        
        let proteinBinding = Binding<String>(get: {self.proteinInput},
                                          set: { protein in
                                            if let value = NumberFormatter().number(from: protein) {
                                                self.product.protein = value.doubleValue
                                                
                                            }
                                            calculateKcal()
                                            self.proteinInput = protein
                                          })
        
        let fatBinding = Binding<String>(get: {self.fatInput},
                                          set: { fat in
                                            if let value = NumberFormatter().number(from: fat) {
                                                self.product.fat = value.doubleValue
                                                
                                            }
                                            calculateKcal()
                                            self.fatInput = fat
                                          })
        
        let fiberBinding = Binding<String>(get: {self.fiberInput},
                                          set: { fiber in
                                            if let value = NumberFormatter().number(from: fiber) {
                                                self.product.fiber = value.doubleValue
                                                
                                            }
                                            calculateKcal()
                                            self.fiberInput = fiber
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
                            TextField($carbsInput.wrappedValue, text: carbsBinding)
                            .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                        HStack{
                            Text("Eiwitten (g)")
                            TextField($proteinInput.wrappedValue, text: proteinBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        }
                        HStack{
                            Text("Vetten (g)")
                            TextField($fatInput.wrappedValue, text: fatBinding)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        }
                        HStack{
                            Text("Vezels (g)")
                            TextField($fiberInput.wrappedValue, text: fiberBinding)
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
