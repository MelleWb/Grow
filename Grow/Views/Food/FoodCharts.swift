//
//  FoodCharts.swift
//  Grow
//
//  Created by Swen Rolink on 14/12/2021.
//

import SwiftUI

//struct PreviewVerticalBar: View {
//    var body: some View {
//        ZStack {
//            VStack(alignment: .leading, spacing: 10){
//                ContentViewLinearKcalFood()
//                ContentViewLinearKoolhFood()
//                ContentViewLinearEiwitFood()
//                ContentViewLinearVetFood()
//                ContentViewLinearVezelFood()
//            }
//            VerticalLeftFoodBar()
//            VerticalFoodBar()
//            VerticalRightFoodBar()
//        }
//    }
//}
//
//struct PreviewBars_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewBars()
//    }
//}


struct VerticalFoodBar: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: ((geometry.size.width * 0.8)*0.1), height: (geometry.size.height*0.93))
                    .foregroundColor(Color.green)
                    .offset(x: ((geometry.size.width * 0.8)*0.95), y: 5)
                    .opacity(0.5)
            }
        }
    }
}

struct VerticalLeftFoodBar: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: 1, height: (geometry.size.height*0.93))
                    .foregroundColor(Color.gray)
                    .offset(x: ((geometry.size.width * 0.8)*0.9), y: 5)
                    .opacity(0.5)
            }
        }
    }
}

struct VerticalRightFoodBar: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: 1, height: (geometry.size.height*0.93))
                    .foregroundColor(Color.gray)
                    .offset(x: ((geometry.size.width * 0.8)*1.1), y: 5)
                    .opacity(0.5)
            }
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
                
                if value <= 0.90 {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                    .foregroundColor(Color.red)
                    .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 0.90 && value < 0.95 {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value >= 0.95 && value < 1.05 {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value >= 1.05 && value < 1.1 {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.red)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
            }.cornerRadius(45.0)
            .offset(y: geometry.size.height/3.5)
        }
    }
}

struct FiberProgressBarLinear: View {
    @Binding var value: Float
    @EnvironmentObject var userModel: UserDataModel
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height/2)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                if value <= 0.90 {
                Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                    .foregroundColor(Color.red)
                    .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 0.9 && value < 0.95 {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else {
                    Rectangle().frame(width: min(CGFloat(self.value*0.8)*geometry.size.width, geometry.size.width), height: geometry.size.height/2)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
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
                    ProgressBarLinear(value: $foodModel.foodDiary.usersCalorieUsedPercentage.kcal)
                }
        }
    }


struct ContentViewLinearKoolhFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.foodDiary.usersCalorieUsedPercentage.carbs)
                }
    }
}

struct ContentViewLinearEiwitFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.foodDiary.usersCalorieUsedPercentage.protein)
                    }
    }
}

struct ContentViewLinearVetFood: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
                HStack{
                    ProgressBarLinear(value: $foodModel.foodDiary.usersCalorieUsedPercentage.fat)
                    }
    }
}

struct ContentViewLinearVezelFood: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
                HStack{
                    FiberProgressBarLinear(value: $foodModel.foodDiary.usersCalorieUsedPercentage.fiber)
                    }
    }
}

