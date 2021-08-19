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
    @State var text = ""
//    var meal: Meal
    
    
var body: some View {
    
    if showAddMeal {
        NavigationLink(
            destination: AddMeal().environmentObject(foodModel),
                    isActive: $showAddMeal
                ) {
            AddMeal().environmentObject(foodModel)
        }.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
    }
    
List{
    Section(header: Text(Date(), style: .date)){
        ZStack{
            HStack{
                VStack(alignment: .leading, spacing: 10){
                    Text("Kcal.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                    Text("Khool.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                    Text("Eiwitten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                    Text("Vetten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                    Text("Vezels").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 10){
                    Text(String(userModel.user.kcal ?? 0)).font(.subheadline).bold()
                    Text(String(userModel.user.carbs ?? 0)).font(.subheadline).bold()
                    Text(String(userModel.user.protein ?? 0)).font(.subheadline).bold()
                    Text(String(userModel.user.fat ?? 0)).font(.subheadline).bold()
                    Text(String(userModel.user.fiber ?? 0)).font(.subheadline).bold()
                }
                VStack(alignment: .leading, spacing: 10){
                    ContentViewLinearKcalFood().environmentObject(userModel).environmentObject(foodModel)
                    ContentViewLinearKoolhFood().environmentObject(userModel).environmentObject(foodModel)
                    ContentViewLinearEiwitFood().environmentObject(userModel).environmentObject(foodModel)
                    ContentViewLinearVetFood().environmentObject(userModel).environmentObject(foodModel)
                    ContentViewLinearVezelFood().environmentObject(userModel).environmentObject(foodModel)
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
//                NavigationLink(destination:AddMealView(showAddMealView: $showAddMealView).environmentObject(foodModel),
//                            isActive: $showAddMealView){}.hidden()
                        }
                    }
            }
    
    if self.foodModel.dailyIntake.meals != nil {
        ForEach(self.foodModel.dailyIntake.meals!, id:\.self){ meal in
            Section{
                HStack{
                    (ShowMealHeader(meal: meal).environmentObject(foodModel))
                    Spacer()
                    Text("0 Kcal")
                }
                ZStack{
                Button("", action:{})
                    NavigationLink(destination:AddMealView(text: $text)) {
                HStack{
                        Image(systemName: "plus").foregroundColor(Color.init("textColor"))
                        Text("Voeg product toe").foregroundColor(Color.init("textColor"))
                    }
                    }
                }
            }
        }
    }
}
        .listStyle(InsetGroupedListStyle())
        .environmentObject(userModel)
        .onAppear(perform:{
        self.foodModel.getTodaysIntake(for: userModel)
        })
    }
}

struct ShowMealHeader: View {
    
    @EnvironmentObject var foodModel : FoodDataModel
    var meal: Meal
    
    var body: some View{
        Button (action: {
            foodModel.removeMeal(for: meal)
            
        }, label: {
            Image(systemName: "trash")
                .resizable()
                .foregroundColor(Color.init("textColor"))
                .frame(width: 17, height: 20, alignment: .trailing)
        })
        
        let mealIndex: Int = foodModel.getMealIndex(for: meal) + 1
        HStack{Text("Meal \(mealIndex)").padding()
            
            
            
        }
    }
}

struct AddMeal : View{
    
    @EnvironmentObject var schemaModel: TrainingDataModel
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var foodModel : FoodDataModel
//    var routine: Routine
//    @State var routineType: String
    
    var body: some View{
    List{
        Section{
            Text("hello")
            }.listStyle(InsetGroupedListStyle())
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
//                    Text("Kcal. ").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
//                    Text(String(userModel.user.kcal ?? 0)).font(.subheadline).bold()
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.kcal)
                }
        }
    }


struct ContentViewLinearKoolhFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
//                    Text("Koolh.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
//                    Text(String(userModel.user.carbs ?? 0)).font(.subheadline).bold()
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.carbs)
                }
    }
}

struct ContentViewLinearEiwitFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
//                    Text("Eiwitten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
//                    Text(String(userModel.user.protein ?? 0)).font(.subheadline).bold()
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.protein)
                    }
    }
}

struct ContentViewLinearVetFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
//                    Text("Vetten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
//                    Text(String(userModel.user.fat ?? 0)).font(.subheadline).bold()
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.fat)
                    }
    }
}

struct ContentViewLinearVezelFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
//                    Text("Vezels").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
//                    Text(String(userModel.user.fiber ?? 0)).font(.subheadline).bold()
                    ProgressBarLinear(value: $foodModel.userIntakeLeftOvers.fiber)
                    }
    }
}

//struct FoodView_Previews: PreviewProvider {
//    static var previews: some View {
//        FoodView()
//            .environment(\.locale, Locale(identifier: "fr"))
//    }
//}
