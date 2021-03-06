//
//  TrainingDaySelectionView.swift
//  Grow
//
//  Created by Swen Rolink on 29/07/2021.
//

import SwiftUI

struct TrainingDaySelectionView: View {
    @EnvironmentObject var userModel: UserDataModel
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                StaticWeekDaysView()
                    .frame(width: geometry.size.width/2, height: geometry.size.height)
                    .disabled(true)
                DynamicTrainingDaysView().environmentObject(userModel)
                    .frame(width: geometry.size.width/1.5)
                    .offset(x: geometry.size.width/3.5)
            }
        }
    }
}
struct StaticWeekDaysView: View{
    
    var weekDays:[String] = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"]
    
    var body: some View {
        List{
            ForEach(0..<weekDays.count){ i in
            Text(weekDays[i])
            }
        }.listStyle(PlainListStyle())
    }
}

struct DynamicTrainingDaysView: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State var isEditMode: EditMode = .active
    
    var body: some View {
        List{
            ForEach(userModel.user.weekPlan!, id:\.self){ day in
                HStack{
                    if day.isTrainingDay!{
                        Image(systemName: "bolt").foregroundColor(Color.init("textColor"))
                        Text(day.trainingType ?? "Training")
                    }
                    else {
                        Image(systemName: "powersleep").foregroundColor(Color.init("textColor"))
                        Text("Rust")
                    }
                }
            }.onMove(perform: moveRow)
        }.environment(\.editMode, self.$isEditMode)
            .listStyle(PlainListStyle())
    }
    
    private func moveRow(source: IndexSet, destination: Int){
        self.userModel.user.weekPlan!.move(fromOffsets: source, toOffset: destination)
        self.userModel.determineWorkoutOfTheDay()
        self.userModel.updateUser()
        self.foodModel.resetUser(user: self.userModel.user)
        self.trainingModel.resetUser(user: self.userModel.user)
        self.statisticsModel.resetUser(user: self.userModel.user)
        }
}

struct TrainingDaySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDaySelectionView()
    }
}
