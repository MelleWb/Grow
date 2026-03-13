//
//  FoodView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI

struct FoodView: View {
    
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var foodModel : FoodDataModel
    @State var enableSheet:Bool = false
    @State var moveMeal:Bool = false
    @State private var date = Date()
    @State private var text = ""
    @State var meal: Meal = Meal()
    @State var mealToCopy: Meal  = Meal()
    @State private var mealToSave: Meal?
    @State private var mealToDetail: Meal?
    @State private var showAddProductToMeal = false
    @State private var showSelectSavedMeal = false
    @State private var showSaveAsMeal = false
    @FocusState var focusedField: UUID?
    
    let dayNameFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "nl")
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "cccc"
        return dateFormatter
    }()
    
    var body: some View {
    
    let dateBinding = Binding<Date> {
        self.foodModel.date
    } set: { dateValue in
        self.foodModel.date = dateValue
        self.foodModel.dateHasChanged()
    }
    ZStack{
        VStack{
            List{
                Section{
                    FoodSummarySection(
                        dateBinding: dateBinding,
                        onPreviousDay: {
                            self.foodModel.date.addTimeInterval(-86400)
                            self.date = self.foodModel.date
                        },
                        onNextDay: {
                            self.foodModel.date.addTimeInterval(86400)
                            self.date = self.foodModel.date
                        }
                    )
                }

                ForEach(self.foodModel.foodDiary.meals ?? [], id:\.self){ meal in
                    FoodMealSection(
                        enableSheet: $enableSheet,
                        mealToCopy: $mealToCopy,
                        meal: meal,
                        showAddProductToMeal: $showAddProductToMeal,
                        selectedMeal: $meal,
                        mealToSave: $mealToSave,
                        showSaveAsMeal: $showSaveAsMeal,
                        focusedField: _focusedField,
                        onOpenMealDetail: {
                            self.mealToDetail = meal
                        },
                        onCopyMealForwardOneDay: {
                            self.date.addTimeInterval(86400)
                            self.foodModel.date = self.date
                            self.foodModel.dateHasChanged()
                            self.foodModel.copyMeal(meal: meal)
                        },
                        onDeleteMeal: {
                            self.foodModel.removeMeal(for: meal)
                        }
                    )
                }
            }
        }
            .frame(alignment: .bottomLeading)
            
            .onReceive(foodModel.$date) { date in
                self.foodModel.dateHasChanged()
            }
            .introspectTabBarController { (UITabBarController) in
                if enableSheet {
                    UITabBarController.tabBar.isHidden = true
                } else {
                    UITabBarController.tabBar.isHidden = false
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Voeding"))
            .navigationDestination(isPresented: $showAddProductToMeal) {
                AddProductToMealList(meal: meal, isPresented: $showAddProductToMeal)
            }
            .navigationDestination(isPresented: $showSelectSavedMeal) {
                SelectSavedMeal(isPresented: $showSelectSavedMeal)
            }
            .navigationDestination(isPresented: $showSaveAsMeal) {
                if let mealToSave {
                    SaveAsMeal(meal: mealToSave)
                }
            }
            .navigationDestination(item: $mealToDetail) { meal in
                MealDetailView(meal: meal)
            }
            .navigationBarHidden(enableSheet)
            .navigationBarBackButtonHidden(enableSheet)
            
            if enableSheet {
                MealCopyCalendar(enableSheet: $enableSheet, date: $date, mealToCopy: mealToCopy)
            }
        }.toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    self.showSelectSavedMeal = true
                }) {
                    Image(systemName: "magnifyingglass")
                }

                Button(action: {
                    self.foodModel.addMeal()
                }) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(action: {
                    self.focusedField = nil
                    
                },label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.accentColor)
                })
            }
        }
    }
}
