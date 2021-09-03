//
//  SaveAsMeal.swift
//  Grow
//
//  Created by Swen Rolink on 31/08/2021.
//

import SwiftUI

struct SaveAsMeal: View {
    @EnvironmentObject var foodModel:FoodDataModel
    @Binding var showSaveAsMeal: Bool
    @State var meal: Meal
    @State var mealName: String = ""
    
    var body: some View {
        
        let mealNameBinding = Binding<String>(get: {self.meal.name ?? ""}, set: {self.meal.name = $0})
        
        VStack{
            Section{
                if meal.products != nil {
                    List{
                        TextField("Maaltijd naam", text: mealNameBinding)
                            .padding()
                            .cornerRadius(5.0)
                            .padding(.bottom, 10)
                        ForEach(meal.products!, id:\.self){ product in
                            HStack{
                                VStack(alignment:.leading){
                                    Text(String(product.name)).padding(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
                                    Text("\(product.selectedProductDetails?.amount ?? 0) gram").font(.footnote).foregroundColor(.gray)
                                }
                                Spacer()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:product.selectedProductDetails?.kcal ?? 0))
                            }.padding()
                        }
                    }
                }
            }
        }.navigationBarItems(trailing:
            Button("Opslaan"){
                let success = self.foodModel.saveMeal(for:meal)
                if success{
                    self.showSaveAsMeal=false
                }
            })
    }
}
