//
//  FoodView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase
import Introspect

struct FoodView: View {
    
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var foodModel : FoodDataModel
    @State var showAddMeal:Bool = false
    @State var enableSheet:Bool = false
    @State var showGetMeal:Bool = false
    @State var moveMeal:Bool = false
    @State private var date = Date()
    @State private var text = ""
    @State var meal: Meal = Meal()
    @State var mealToCopy: Meal  = Meal()

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

    if showAddMeal {
        NavigationLink(destination: AddMealView(meal: meal, showAddMeal: self.$showAddMeal),isActive: self.$showAddMeal) {AddMealView(meal: meal, showAddMeal: self.$showAddMeal)}
            .isDetailLink(false)
            .navigationBarTitle("Voeg product toe")
    }
    
    if showGetMeal {
        NavigationLink(destination: SelectSavedMeal(showGetMeal: self.$showGetMeal),isActive: self.$showGetMeal) {SelectSavedMeal(showGetMeal: self.$showAddMeal)}
            .isDetailLink(false)
            .navigationBarTitle("Voeg product toe")
    }
        
    ZStack{
        VStack{
            List{
                Section{
                    ZStack{
                        VStack{
                            HStack{
                                
                                Button (action: {
                                    self.foodModel.date.addTimeInterval(-86400)
                                    self.date = self.foodModel.date
                                }, label: {
                                    Image(systemName:"chevron.left")
                                }).buttonStyle(ChevronButtonStyle()).padding()
                                
                                
                                DatePicker("Please enter date", selection: dateBinding, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .environment(\.locale, Locale.init(identifier: "nl_NL"))
                            
                                
                                Button (action: {
                                    self.foodModel.date.addTimeInterval(86400)
                                    self.date = self.foodModel.date
                                }, label: {
                                    Image(systemName:"chevron.right")
                                }).buttonStyle(ChevronButtonStyle()).padding()

                            }.frame(alignment: .topLeading)
                            
                        HStack{
                            VStack(alignment: .leading, spacing: 10){
                                Text("Kcal.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                                Text("Koolh.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                                Text("Eiwitten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                                Text("Vetten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                                Text("Vezels").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                            }
                            VStack(alignment: .leading, spacing: 10){
                                
                                Text(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.usersCalorieBudget.kcal)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieBudget.carbs)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieBudget.protein)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieBudget.fat)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieBudget.fiber)).font(.subheadline).bold()
                            }
                            VStack(alignment: .leading, spacing: 10){
                                ContentViewLinearKcalFood()
                                ContentViewLinearKoolhFood()
                                ContentViewLinearEiwitFood()
                                ContentViewLinearVetFood()
                                ContentViewLinearVezelFood()
                                    }
                            VStack(alignment: .leading, spacing: 10){
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieLeftOver.kcal )).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieLeftOver.carbs)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieLeftOver.protein)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieLeftOver.fat)).font(.subheadline).bold()
                                Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.usersCalorieLeftOver.fiber)).font(.subheadline).bold()
                            }
                                }.padding(.top, 10)
                        }
                        .padding(.bottom, 10)
                        }
                    }
                Section{
                    HStack{
                        Button(action: {
                            self.showGetMeal = true
                        }) {
                            HStack{
                                Image(systemName: "magnifyingglass").foregroundColor(.accentColor)
                                Text("Kies Maaltijd").foregroundColor(.accentColor)
                                        }
                        }
                    }
                }
            
                ForEach(self.foodModel.foodDiary.meals ?? [], id:\.self){ meal in
                            Section{
                                HStack{
                                    ShowMealHeader(enableSheet: $enableSheet, mealToCopy: $mealToCopy, meal: meal)
                                    Spacer()
                                    Text("\(NumberHelper.roundedNumbersFromDouble(unit:meal.kcal)) Kcal")
                                }
                                
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        // Copy function
                                        self.date.addTimeInterval(86400)
                                        self.foodModel.date = self.date
                                        self.foodModel.dateHasChanged()
                                        self.foodModel.copyMeal(meal: meal)
                                    } label: {
                                        Label("Kopieer", systemImage: "doc.on.doc")
                                    }
                                    .tint(.indigo)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        self.foodModel.removeMeal(for: meal)
                                    } label: {
                                        Label("Verwijder", systemImage: "trash.fill")
                                    }
                                }
                                
                                ProductForMeal(meal:meal)

                                
                                Button(action:{self.showAddMeal = true
                                        self.meal = meal},label:{
                                    HStack{
                                        Image(systemName: "plus").foregroundColor(.accentColor)
                                        Text("Voeg product toe").foregroundColor(.accentColor)
                                    }
                                 })
                            }
                }
                Section{
                    HStack{
                        Button(action: {
                            self.foodModel.addMeal()
                        }) {
                            HStack{
                                Image(systemName: "plus").foregroundColor(.accentColor)
                                Text("Voeg Maaltijd toe").foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
            .frame(alignment: .bottomLeading)
            .blur(radius: enableSheet ? 1 : 0)
            .overlay(enableSheet ? Color.black.opacity(0.6) : nil)
            
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
            .listStyle(GroupedListStyle())
            .navigationTitle(Text("Voeding"))
            .navigationBarHidden(enableSheet)
            .navigationBarBackButtonHidden(enableSheet)
            
            if enableSheet {
                MealCopyCalendar(enableSheet: $enableSheet, date: $date, mealToCopy: mealToCopy)
            }
        }
    }
}

struct ProductForMeal: View {
    @EnvironmentObject var foodModel : FoodDataModel
    @State var meal: Meal
    var body: some View {
        if meal.products != nil {
            ForEach(meal.products!, id:\.self){ product in
                ProductIntakeDetails(meal: meal, product: product)
            }.onDelete(perform: deleteProduct)
        }
    }
    
    func deleteProduct(at offsets: IndexSet) {
        let productIndex: Int = offsets[offsets.startIndex]
        self.foodModel.deleteProductFromMeal(for: meal, with: productIndex)
    }
}

struct ProductIntakeDetails:View {
    
    @State var meal: Meal
    @State var showChangeIntake = false
    @State var product: Product
    
    var body: some View{
        NavigationLink(destination:ChangeIntakeOfProduct(showChangeIntake: $showChangeIntake, product: product, meal: meal, amount: String(product.selectedProductDetails?.amount ?? 0)),isActive:$showChangeIntake){
            HStack{
                VStack(alignment:.leading){
                    Text(String(product.name)).padding(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
                    Text("\(product.selectedProductDetails?.amount ?? 0) gram").font(.footnote).foregroundColor(.gray)
                }
                Spacer()
                Text(NumberHelper.roundedNumbersFromDouble(unit:product.selectedProductDetails?.kcal ?? 0))
            }.padding()
        }.isDetailLink(false)
    }
}

struct ShowMealHeader: View {
    
    @EnvironmentObject var foodModel : FoodDataModel
    @Binding var enableSheet: Bool
    @Binding var mealToCopy: Meal
    @State var showSaveAsMeal: Bool = false
    @State var meal: Meal
    
    var body: some View{
        
        if showSaveAsMeal{
            NavigationLink(destination:SaveAsMeal(showSaveAsMeal: $showSaveAsMeal, meal: meal),isActive:$showSaveAsMeal){
                SaveAsMeal(showSaveAsMeal: $showSaveAsMeal, meal: meal)
            }.isDetailLink(false).hidden()
        }
            
        if foodModel.getMealIndex(for: meal) != nil {
            
            let mealIndex: Int = (foodModel.getMealIndex(for: meal) ?? 0) + 1
        
            HStack{
                Text("Maaltijd \(mealIndex)")
                    .padding()
                    .contextMenu(menuItems: {
                        VStack{                            Text("\(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.meals![foodModel.getMealIndex(for: meal)!].kcal)) Calorieën")
                           
                            Text("\(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.meals![foodModel.getMealIndex(for: meal)!].carbs)) Koolhydraten")

                            Text("\(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.meals![foodModel.getMealIndex(for: meal)!].protein)) Eiwitten")

                            Text("\(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.meals![foodModel.getMealIndex(for: meal)!].fat)) Vetten")

                            Text("\(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.foodDiary.meals![foodModel.getMealIndex(for: meal)!].fiber)) Vezels")
                            }
                        Button (action: {
                            self.showSaveAsMeal = true
                        }, label: {
                            Text("Sla maaltijd op")
                            Image(systemName: "square.and.arrow.down")
                                .resizable()
                                .frame(width: 17, height: 20, alignment: .trailing)
                        })
                        Button (action: {
                            self.mealToCopy = meal
                            self.enableSheet = true
                            
                        }, label: {
                            Text("Kopieren")
                            Image(systemName: "doc.on.doc")
                                .resizable()
                                .frame(width: 17, height: 20, alignment: .trailing)
                        })
                        Button (action: {
                            foodModel.removeMeal(for: meal)
                            
                        }, label: {
                            Text("Verwijder")
                            Image(systemName: "trash")
                                .resizable()
                                .frame(width: 17, height: 20, alignment: .trailing)
                        })
                    })
            }.onAppear {
                print("Ik print meal")
                print(meal)
            }
        }
    }
}

