import SwiftUI

#Preview {
    FoodPreviewContainer(
        diary: FoodDiary(
            meals: [
                Meal(name: "Ontbijt", kcal: 520, carbs: 61, protein: 31, fat: 16, fiber: 8),
                Meal(name: "Diner", kcal: 710, carbs: 64, protein: 48, fat: 24, fiber: 10)
            ],
            usersCalorieBudget: Calories(kcal: 2400, carbs: 260, protein: 180, fat: 70, fiber: 35),
            usersCalorieUsed: Calories(kcal: 1230, carbs: 125, protein: 79, fat: 40, fiber: 18),
            usersCalorieLeftOver: Calories(kcal: 1170, carbs: 135, protein: 101, fat: 30, fiber: 17),
            usersCalorieUsedPercentage: CaloriesPercentages(kcal: 0.51, carbs: 0.48, protein: 0.44, fat: 0.57, fiber: 0.51)
        )
    ) {
        FoodView()
    }
}
