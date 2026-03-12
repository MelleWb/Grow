import SwiftUI

struct FoodSummarySection: View {
    @EnvironmentObject private var foodModel: FoodDataModel

    let dateBinding: Binding<Date>
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: onPreviousDay) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(ChevronButtonStyle())
                    .padding()

                    DatePicker("Please enter date", selection: dateBinding, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                        .environment(\.locale, Locale.init(identifier: "nl_NL"))

                    Button(action: onNextDay) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(ChevronButtonStyle())
                    .padding()
                }
                .frame(alignment: .topLeading)

                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        FoodSummaryLabelColumn()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FoodSummaryBudgetColumn(diary: foodModel.foodDiary)
                    }

                    ZStack {
                        VStack(alignment: .leading, spacing: 10) {
                            ContentViewLinearKcalFood()
                            ContentViewLinearKoolhFood()
                            ContentViewLinearEiwitFood()
                            ContentViewLinearVetFood()
                            ContentViewLinearVezelFood()
                        }
                        VerticalLeftFoodBar()
                        VerticalFoodBar()
                        VerticalRightFoodBar()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FoodSummaryRemainingColumn(diary: foodModel.foodDiary)
                    }
                }
                .padding(.top, 10)
            }
            .padding(.bottom, 10)
        }
    }
}

private struct FoodSummaryLabelColumn: View {
    var body: some View {
        Group {
            Text("Kcal.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
            Text("Koolh.").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
            Text("Eiwitten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
            Text("Vetten").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
            Text("Vezels").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct FoodSummaryBudgetColumn: View {
    let diary: FoodDiary

    var body: some View {
        Group {
            Text(NumberHelper.roundedNumbersFromDouble(unit: diary.usersCalorieBudget.kcal)).font(.subheadline).bold()
            Text(NumberHelper.roundedNumbersFromDouble(unit: diary.usersCalorieBudget.carbs)).font(.subheadline).bold()
            Text(NumberHelper.roundedNumbersFromDouble(unit: diary.usersCalorieBudget.protein)).font(.subheadline).bold()
            Text(NumberHelper.roundedNumbersFromDouble(unit: diary.usersCalorieBudget.fat)).font(.subheadline).bold()
            Text(NumberHelper.roundedNumbersFromDouble(unit: diary.usersCalorieBudget.fiber)).font(.subheadline).bold()
        }
    }
}

private struct FoodSummaryRemainingColumn: View {
    let diary: FoodDiary

    var body: some View {
        Group {
            FoodSummaryRemainingValue(value: -diary.usersCalorieLeftOver.kcal)
            FoodSummaryRemainingValue(value: -diary.usersCalorieLeftOver.carbs)
            FoodSummaryRemainingValue(value: -diary.usersCalorieLeftOver.protein)
            FoodSummaryRemainingValue(value: -diary.usersCalorieLeftOver.fat)
            FoodSummaryRemainingValue(value: -diary.usersCalorieLeftOver.fiber)
        }
    }
}

private struct FoodSummaryRemainingValue: View {
    let value: Double

    var body: some View {
        Text(displayValue)
            .font(.subheadline)
            .bold()
    }

    private var displayValue: String {
        let roundedValue = NumberHelper.roundedNumbersFromDouble(unit: value)
        return value > 0 ? "+\(roundedValue)" : roundedValue
    }
}

#Preview {
    FoodPreviewContainer(
        diary: FoodDiary(
            meals: [],
            usersCalorieBudget: Calories(kcal: 2400, carbs: 260, protein: 180, fat: 70, fiber: 35),
            usersCalorieUsed: Calories(kcal: 1850, carbs: 190, protein: 150, fat: 58, fiber: 24),
            usersCalorieLeftOver: Calories(kcal: 550, carbs: 70, protein: 30, fat: 12, fiber: 11),
            usersCalorieUsedPercentage: CaloriesPercentages(kcal: 0.77, carbs: 0.73, protein: 0.83, fat: 0.82, fiber: 0.69)
        )
    ) {
        List {
            Section {
                FoodSummarySection(
                    dateBinding: .constant(Date()),
                    onPreviousDay: {},
                    onNextDay: {}
                )
            }
        }
        .listStyle(.grouped)
    }
}
