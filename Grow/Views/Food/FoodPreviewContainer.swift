import SwiftUI

struct FoodPreviewContainer<Content: View>: View {
    private let content: Content
    @StateObject private var userModel = UserDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var foodModel: FoodDataModel

    init(
        date: Date = Date(),
        diary: FoodDiary = FoodDiary(),
        savedMeals: [Meal] = [],
        @ViewBuilder content: () -> Content
    ) {
        let foodModel = FoodDataModel(autostart: false, runStartupSideEffects: false)
        foodModel.date = date
        foodModel.foodDiary = diary
        foodModel.todaysDiary = diary
        foodModel.savedMeals = savedMeals
        _foodModel = StateObject(wrappedValue: foodModel)
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .environmentObject(userModel)
                .environmentObject(foodModel)
        }
    }
}
