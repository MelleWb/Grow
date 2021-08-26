//
//  FoodView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase

struct FoodView: View {
    
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var foodModel : FoodDataModel
    @State var showAddMealView = false
    @State var showAddMeal = false
    @State private var date = Date()
    @State private var text = ""
    @State var meal: Meal = Meal()

    let dayNameFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "nl")
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "cccc"
        return dateFormatter
    }()
    
var body: some View {
    
    if showAddMeal {
        NavigationLink(destination: AddMealView(meal: meal, showAddMeal: self.$showAddMeal),isActive: self.$showAddMeal) {AddMealView(meal: meal, showAddMeal: self.$showAddMeal)}
            .isDetailLink(false)
            .navigationBarTitle("Voeg product toe")
    }
    
        List{
            Section(header:
                        HStack{
                            Button(action:{self.date.addTimeInterval(-86400)}){
                                Image(systemName:"arrow.backward.circle")
                                    .foregroundColor(.accentColor)
                            }
                            Spacer()
                            
                            Text(dayNameFormatter.string(from: date))
                        
                            Spacer()
                            Button(action:{self.date.addTimeInterval(86400)}){
                                Image(systemName:"arrow.forward.circle")
                                    .foregroundColor(.accentColor)
                            }}){
                ZStack{
                    HStack{
                        VStack(alignment: .leading, spacing: 10){
                            Text("Kcal.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                            Text("Koolh.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                            Text("Eiwitten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                            Text("Vetten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                            Text("Vezels").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                        }
                        VStack(alignment: .leading, spacing: 10){
                            Text(String(userModel.user.kcal ?? 0)).font(.subheadline).bold()
                            Text(String(0)).font(.subheadline).bold()
                            Text(String(0)).font(.subheadline).bold()
                            Text(String(0)).font(.subheadline).bold()
                            Text(String(0)).font(.subheadline).bold()
                        }
                        VStack(alignment: .leading, spacing: 10){
                            ContentViewLinearKcalFood()
                            ContentViewLinearKoolhFood()
                            ContentViewLinearEiwitFood()
                            ContentViewLinearVetFood()
                            ContentViewLinearVezelFood()
                                }
                            }.padding(.top, 10)
                            .padding(.bottom, 10)
                            }
                }
            
            Section{
                Button(action: {
                    self.foodModel.addMeal()
                }) {
                    HStack{
                        Image(systemName: "plus").foregroundColor(.accentColor)
                        Text("Voeg Maaltijd toe").foregroundColor(.accentColor)
                                }
                            }
                    }
            
            if self.foodModel.foodDiary.meals != nil {
                ForEach(self.foodModel.foodDiary.meals!, id:\.self){ meal in
                    
                    Section{
                        HStack{
                            ShowMealHeader(meal: meal)
                            Spacer()
                            Text("\(meal.kcal) Kcal")
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
    }
}
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Voeding"))
        .toolbar(content: {
            DatePicker("Please enter date", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
                .environment(\.locale, Locale.init(identifier: "nl"))
        })
        .onAppear(perform:{
        self.foodModel.getTodaysIntake(for: userModel)
        })
    }
}

struct ProductForMeal: View {
    @EnvironmentObject var foodModel : FoodDataModel
    @State var meal: Meal
    
    var body: some View {
        if meal.products != nil {
            ForEach(meal.products!, id:\.self){ product in
                NavigationLink(destination:ProductDetailView(shouldPopToRoot: Binding<Bool>.constant(false), product: product, meal: meal)){
                    HStack{
                        VStack(alignment:.leading){
                            Text(String(product.name)).padding(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
                            Text("\(product.selectedProductDetails?.amount ?? 0) gram").font(.footnote).foregroundColor(.gray)
                        }
                        Spacer()
                        Text(String(product.selectedProductDetails?.kcal ?? 0))
                    }.padding()
                }
            }
        }
    }
    
}

struct ShowMealHeader: View {
    
    @EnvironmentObject var foodModel : FoodDataModel
    @State private var showingActionSheet = false
    var meal: Meal

    var body: some View{
        let mealIndex: Int = foodModel.getMealIndex(for: meal) + 1
        HStack{
            Text("Meal \(mealIndex)")
                .padding()
                .contextMenu(menuItems: {
                    Button (action: {
                        foodModel.removeMeal(for: meal)
                        
                    }, label: {
                        Text("Verwijder")
                        Image(systemName: "trash")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 17, height: 20, alignment: .trailing)
                    })
                    Button (action: {
                    self.showingActionSheet = true
                    }, label: {
                        Text("Kopieren")
                        Image(systemName: "doc.on.doc")
                            .resizable()
                            .foregroundColor(.accentColor)
                            .frame(width: 17, height: 20, alignment: .trailing)
                    })
                })
            
            
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Kopieren"), message: Text("Selecteer een dag"), buttons: [
                .default(Text("Morgen")) {  },
                .default(Text("Overmorgen")) {  },
                .cancel()
            ])
        }
    }
}

struct ProgressBarLinear: View {
    @Binding var value: Float
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height/2)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                if value <= 0.8 {
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                    .foregroundColor(Color.green)
                    .animation(.linear)
                }
                else if value > 0.8 && value < 1 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.orange)
                        .animation(.linear)
                } else {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.red)
                        .animation(.linear)
                }
            }.cornerRadius(45.0)
            .offset(y: geometry.size.height/3.5)
        }
    }
}

struct ContentViewLinearKcalFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.kcal)
                }
        }
    }


struct ContentViewLinearKoolhFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.carbs)
                }
    }
}

struct ContentViewLinearEiwitFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.protein)
                    }
    }
}

struct ContentViewLinearVetFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.fat)
                    }
    }
}

struct ContentViewLinearVezelFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.fiber)
                    }
    }
}
