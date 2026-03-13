//
//  MacrosActionSheet.swift
//  Grow
//
//  Created by Swen Rolink on 07/12/2021.
//

import SwiftUI

struct MacrosActionSheet: View {
    
    enum TypeOfCalories: String {
        case RestCalories, SportCalories
    }
    
    @EnvironmentObject var userModel: UserDataModel
    @Binding var enableMacroSheet: Bool
    
    @State var calorieTotal: Int
    @State var typeOfCalories: TypeOfCalories
    @State var macroSelection: [Int]
    
    @State var calorieSum: Int?
    @State var carbs: Int?
    @State var proteins: Int?
    @State var fats: Int?
    
    @State var carbsPercentage: Double?
    @State var proteinsPercentage: Double?
    @State var fatsPercentage: Double?

    
    private let macroData: [[Double]] = [
            Array(stride(from: 0, through: 600, by: 1)),
            Array(stride(from: 0, through: 600, by: 1)),
            Array(stride(from: 0, through: 600, by: 1))
        ]
        
    
    func setMacroStates(){
        
        let carbs = macroSelection[0]
        let proteins = macroSelection[1]
        let fats = macroSelection[2]
        
        self.carbs = carbs
        self.proteins = proteins
        self.fats = fats
        
        self.calorieSum = (carbs * 4) + (proteins * 4) + (fats * 9)
        
        let carbGrams:Double = Double(carbs) * 4
        let proteinGrams:Double = Double(proteins)  * 4
        let fatGrams:Double = Double(fats) * 9
        let calorieTotal:Double = Double(self.calorieSum ?? 0)
        
        self.carbsPercentage = (carbGrams/calorieTotal)*100
        self.proteinsPercentage = (proteinGrams/calorieTotal)*100
        self.fatsPercentage = (fatGrams/calorieTotal)*100
    }
    
    var body: some View{
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    VStack {
                        Text("Verander je macros")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        VStack{
                            Text("Calorieën")
                                .font(.headline)
                            HStack{
                                Text("\(calorieTotal)")
                                Text(" / ")
                                Text("\(calorieSum ?? 1)")
                                    .font(.headline)
                            }
                        }
                        .padding()
                        
                        HStack{
                            VStack{
                                HStack(spacing:20){
                                    VStack{
                                        Text("Koolh. (g)")
                                            .font(.headline)
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.carbsPercentage ?? 0)) %")
                                    }
                                    VStack{
                                        Text("Eiwitten (g)")
                                            .font(.headline)
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.proteinsPercentage ?? 0)) %")
                                    }
                                    VStack{
                                        Text("Vetten (g)")
                                            .font(.headline)
                                        Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.fatsPercentage ?? 0)) %")
                                    }
                                }
                                
                                let macroSelectionBinding = Binding<[Int]>(
                                    get: { self.macroSelection },
                                    set: {
                                        self.macroSelection = $0
                                        setMacroStates()
                                    }
                                )
                                MultiWheelPicker(selections: macroSelectionBinding, data: macroData)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.init("textField"))
                            .shadow(radius: 1)
                    )
                    
                    Button(action: {
                        if typeOfCalories == .RestCalories {
                            self.userModel.user.restCalories!.kcal = self.calorieSum ?? 0
                            self.userModel.user.restCalories!.carbs = self.carbs ?? 0
                            self.userModel.user.restCalories!.protein = self.proteins ?? 0
                            self.userModel.user.restCalories!.fat = self.fats ?? 0
                            self.userModel.user.restCalories!.fiber = Int(Double(self.calorieSum ?? 0) * 0.014)
                        } else if typeOfCalories == .SportCalories {
                            self.userModel.user.sportCalories!.kcal = self.calorieSum ?? 0
                            self.userModel.user.sportCalories!.carbs = self.carbs ?? 0
                            self.userModel.user.sportCalories!.protein = self.proteins ?? 0
                            self.userModel.user.sportCalories!.fat = self.fats ?? 0
                            self.userModel.user.sportCalories!.fiber = Int(Double(self.calorieSum ?? 0) * 0.014)
                        }
                        
                        self.enableMacroSheet.toggle()
                    }) {
                        Text("Klaar").fontWeight(Font.Weight.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 8))
                .onAppear {
                    setMacroStates()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
    }
}
