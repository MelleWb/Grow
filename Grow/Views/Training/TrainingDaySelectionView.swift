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
        }
    }
}

struct DynamicTrainingDaysView: View {
    @EnvironmentObject var userModel: UserDataModel
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
    }
    
    private func moveRow(source: IndexSet, destination: Int){
        self.userModel.user.weekPlan!.move(fromOffsets: source, toOffset: destination)
        self.userModel.isTrainingDayToday()
        self.userModel.updateUser()
        }
}

struct TrainingDaySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDaySelectionView()
    }
}
