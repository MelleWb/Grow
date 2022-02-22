//
//  SelectSavedMeal.swift
//  Grow
//
//  Created by Swen Rolink on 31/08/2021.
//

import SwiftUI

struct SelectSavedMeal: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @State var searchText = ""
    @State var searching = false
    @Binding var navigationAction: Int?
    
    var body: some View {
        VStack{
            List {
                SearchBar(searchText: $searchText, searching: $searching)
                if self.foodModel.savedMeals.count > 1 {
                    ForEach(self.foodModel.savedMeals.filter({ (meal: Meal) -> Bool in
                        return (meal.name!.hasPrefix(searchText)) || searchText == ""
                    }), id: \.self) { meal in
                        ZStack{
                            Button(""){
                                self.foodModel.addSavedMeal(meal: meal)
                                navigationAction = 0
                                
                            }
                            VStack(alignment: .leading){
                                Text(meal.name ?? "").font(.headline).padding()
                                HStack{
                                    VStack{
                                        Text("Kcal")
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.kcal))")
                                    }
                                    VStack{
                                        Text("Koolh")
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.carbs))")
                                    }
                                    VStack{
                                        Text("Eiwitten")
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.protein))")
                                    }
                                    VStack{
                                        Text("Vetten")
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.fat))")
                                    }
                                    VStack{
                                        Text("Vezels")
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.fiber))")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
