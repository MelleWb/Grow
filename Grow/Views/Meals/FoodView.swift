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

    let dayNameFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.init(identifier: "nl")
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "cccc"
        return dateFormatter
    }()
    
var body: some View {
    if showAddMeal {
        NavigationLink(
            destination: AddMealView(showAddMeal: $showAddMeal),
                    isActive: $showAddMeal
                ) {
            AddMealView(showAddMeal: $showAddMeal)
        }.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
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
                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                        Text("Voeg Maaltijd toe").foregroundColor(Color.init("textColor"))
                                }
                            }
                    }
            
            if self.foodModel.foodDiary.meals != nil {
                ForEach(self.foodModel.foodDiary.meals!, id:\.self){ meal in
                    Section{
                        HStack{
                            (ShowMealHeader(meal: meal))
                            Spacer()
                            Text("0 Kcal")
                        }
                        ZStack{
                            Button("", action:{self.showAddMeal = true})
                        HStack{
                                Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                                Text("Voeg product toe").foregroundColor(Color.init("textColor"))
                    }
                }
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
