//
//  CalorieOverview.swift
//  Grow
//
//  Created by Swen Rolink on 03/12/2021.
//

import SwiftUI

struct CalorieOverview: View {
    
    enum FocusedField {
            case restCalories
        }
    
    @EnvironmentObject var userModel: UserDataModel
    @State var enableExtraCalorieSheet: Bool = false
    @State var enableRestMacroSheet: Bool = false
    @State var enableSportMacroSheet: Bool = false
    @FocusState private var focusedField: FocusedField?
    
    func isSheetEnabled() -> Bool {
        if enableExtraCalorieSheet || enableRestMacroSheet || enableSportMacroSheet {
            return true
        } else {
            return  false
        }
    }
    
    var body: some View {
        ZStack{
            VStack{
                Form{
                    Section("Calorie budget rustdag") {
                        HStack{
                            Text("Calorieën")
                            Spacer()
                            Button("\(self.userModel.user.restCalories?.kcal ?? 0)"){
                                withAnimation {
                                    self.enableRestMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Koolhydraten")
                            Spacer()
                            Button("\(self.userModel.user.restCalories?.carbs ?? 0)"){
                                withAnimation {
                                    self.enableRestMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Eiwitten")
                            Spacer()
                            Button("\(self.userModel.user.restCalories?.protein ?? 0)"){
                                withAnimation {
                                    self.enableRestMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        
                        HStack{
                            Text("Vetten")
                            Spacer()
                            Button("\(self.userModel.user.restCalories?.fat ?? 0)"){
                                withAnimation {
                                    self.enableRestMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
    
                        HStack{
                            Text("Vezels")
                            Spacer()
                            Text("\(self.userModel.user.restCalories?.fiber ?? 0)")
                        }

                    }
                    Section{
                        HStack{
                            Text("Extra calorieën op een sportdag")
                            Spacer()
                            Button("\(self.userModel.user.extraCaloriePercentage ?? 0) %"){
                                self.enableExtraCalorieSheet.toggle()
                            }.foregroundColor(Color.init("blackWhite"))
                        }
                    }
                    Section("Calorie budget sportdag") {
                        HStack{
                            Text("Calorieën")
                            Spacer()
                            Button("\(self.userModel.user.sportCalories?.kcal ?? 0)"){
                                withAnimation {
                                    self.enableSportMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Koolhydraten")
                            Spacer()
                            Button("\(self.userModel.user.sportCalories?.carbs ?? 0)"){
                                withAnimation {
                                    self.enableSportMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Eiwitten")
                            Spacer()
                            Button("\(self.userModel.user.sportCalories?.protein ?? 0)"){
                                withAnimation {
                                    self.enableSportMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Vetten")
                            Spacer()
                            Button("\(self.userModel.user.sportCalories?.fat ?? 0)"){
                                withAnimation {
                                    self.enableSportMacroSheet.toggle()
                                }
                            }.buttonStyle(FormRowButtonStyle())
                        }
                        HStack{
                            Text("Vezels")
                            Spacer()
                            Text("\(self.userModel.user.sportCalories?.fiber ?? 0)")
                        }
                    }
                }
            }
            .introspectTabBarController { (UITabBarController) in
                if isSheetEnabled() {
                    UITabBarController.tabBar.isHidden = true
                } else {
                    UITabBarController.tabBar.isHidden = false
                }
            }
            
            .introspectNavigationController { (UINavigationBar) in
                if isSheetEnabled() {
                    UINavigationBar.navigationController?.isToolbarHidden = true
                } else {
                    UINavigationBar.navigationController?.isToolbarHidden = false
                }
            }
            
            .navigationTitle(Text("Calorie budget"))
            .navigationBarHidden(isSheetEnabled())
            .navigationBarBackButtonHidden(isSheetEnabled())
            .navigationBarItems(trailing:
                Button("Reset"){
                    do {
                        try self.userModel.calcKcal()
                    }
                    catch {
                        print("Oops")
                    }
                }
            )
            
            if enableExtraCalorieSheet {
                ExtraSportCaloriesActionSheet(enableExtraCalorieSheet: $enableExtraCalorieSheet)
            }
            
            if enableRestMacroSheet {
                MacrosActionSheet(enableMacroSheet: $enableRestMacroSheet, calorieTotal: self.userModel.user.restCalories?.kcal ?? 0, typeOfCalories: .RestCalories, macroSelection: [self.userModel.user.restCalories?.carbs ?? 0, self.userModel.user.restCalories?.protein ?? 0, self.userModel.user.restCalories?.fat ?? 0])
            }
            if enableSportMacroSheet {
                MacrosActionSheet(enableMacroSheet: $enableSportMacroSheet, calorieTotal: self.userModel.user.sportCalories?.kcal ?? 0, typeOfCalories: .SportCalories, macroSelection: [self.userModel.user.sportCalories?.carbs ?? 0, self.userModel.user.sportCalories?.protein ?? 0, self.userModel.user.sportCalories?.fat ?? 0])
            }
        }
    }
}
