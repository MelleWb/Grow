import SwiftUI

struct DashboardNutritionSection: View {
    var body: some View {
        Section(header: Text(Date(), style: .date)) {
            ZStack {
                HStack {
                    DashboardCalorieRing()
                    VStack {
                        HStack {
                            DashboardMacroCard(
                                title: "Koolh. over",
                                amount: \.usersCalorieLeftOver.carbs,
                                percentage: \.usersCalorieUsedPercentage.carbs,
                                usesFiberStyle: false
                            )
                            DashboardMacroCard(
                                title: "Eiwitten over",
                                amount: \.usersCalorieLeftOver.protein,
                                percentage: \.usersCalorieUsedPercentage.protein,
                                usesFiberStyle: false
                            )
                        }

                        HStack {
                            DashboardMacroCard(
                                title: "Vetten over",
                                amount: \.usersCalorieLeftOver.fat,
                                percentage: \.usersCalorieUsedPercentage.fat,
                                usesFiberStyle: false
                            )
                            DashboardMacroCard(
                                title: "Vezels over",
                                amount: \.usersCalorieLeftOver.fiber,
                                percentage: \.usersCalorieUsedPercentage.fiber,
                                usesFiberStyle: true
                            )
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                NavigationLink(destination: FoodView()) { EmptyView() }
                    .isDetailLink(false)
                    .opacity(0)
            }
        }
    }
}

private struct DashboardCalorieRing: View {
    @EnvironmentObject private var foodModel: FoodDataModel

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5.0)
                .opacity(0.3)
                .foregroundColor(Color.gray)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(progressColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(Animation.linear(duration: 0.5), value: foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)

            VStack {
                Text(NumberHelper.roundedNumbersFromDouble(unit: foodModel.todaysDiary.usersCalorieLeftOver.kcal))
                Text("Kcal over")
            }
        }
        .frame(width: 125.0, height: 125.0)
    }

    private var progressColor: Color {
        let value = foodModel.todaysDiary.usersCalorieUsedPercentage.kcal

        if value <= 0.9 {
            return .red
        } else if value < 0.95 {
            return .orange
        } else if value < 1.05 {
            return .green
        } else if value < 1.1 {
            return .orange
        } else {
            return .red
        }
    }
}

private struct DashboardMacroCard: View {
    @EnvironmentObject private var foodModel: FoodDataModel

    let title: String
    let amount: KeyPath<FoodDiary, Double>
    let percentage: KeyPath<FoodDiary, Float>
    let usesFiberStyle: Bool

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(NumberHelper.roundedNumbersFromDouble(unit: foodModel.todaysDiary[keyPath: amount]))
                        .font(.subheadline)
                        .bold()
                    Text("g")
                        .font(.subheadline)
                        .bold()
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .fixedSize(horizontal: true, vertical: false)
            }

            if usesFiberStyle {
                DashboardFiberProgressBar(value: foodModel.todaysDiary[keyPath: percentage])
                    .frame(height: 7.5)
            } else {
                DashboardProgressBar(value: foodModel.todaysDiary[keyPath: percentage])
                    .frame(height: 7.5)
            }
        }
    }
}

private struct DashboardProgressBar: View {
    let value: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))

                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(progressColor)
                    .animation(Animation.linear(duration: 0.5), value: value)
            }
            .cornerRadius(45.0)
            .offset(y: geometry.size.height / 3.5)
        }
    }

    private var progressColor: Color {
        if value <= 0.90 {
            return .red
        } else if value < 0.95 {
            return .orange
        } else if value < 1.05 {
            return .green
        } else if value < 1.1 {
            return .orange
        } else {
            return .red
        }
    }
}

private struct DashboardFiberProgressBar: View {
    let value: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))

                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(progressColor)
                    .animation(Animation.linear(duration: 0.5), value: value)
            }
            .cornerRadius(45.0)
            .offset(y: geometry.size.height / 3.5)
        }
    }

    private var progressColor: Color {
        if value <= 0.90 {
            return .red
        } else if value < 0.95 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardNutritionSection()
        }
        .listStyle(.insetGrouped)
    }
}
