//
//  MealCopyCalendar.swift
//  Grow
//
//  Created by Swen Rolink on 14/12/2021.
//

import SwiftUI

struct MealCopyCalendar: View {
    
    @Binding var enableSheet: Bool
    @Binding var date: Date
    @State var mealToCopy: Meal
    
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        ZStack{
            GeometryReader { gr in
                VStack {
                    VStack {
                        HStack{
                            Button(action: {
                                self.enableSheet = false
                            }) {
                                Text("Annuleer").foregroundColor(Color.red)
                            }.padding()
                            Spacer()
                            Button(action: {
                                self.enableSheet = false
                                self.foodModel.date = date
                                self.foodModel.dateHasChanged()
                                self.foodModel.copyMeal(meal: mealToCopy)
                            }) {
                                Text("Selecteer").fontWeight(.bold)
                            }.padding()
                        }
                        Text("Kopieer maaltijd naar")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        DatePicker("Please enter date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .environment(\.locale, Locale.init(identifier: "nl_NL"))
                        
                    }.background(RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.init("textField")).shadow(radius: 1))
                }.position(x: gr.size.width / 2 ,y: gr.size.height - 330)
           }.edgesIgnoringSafeArea(.all)
        }.background(Color.black.opacity(0.6))
    }
}
