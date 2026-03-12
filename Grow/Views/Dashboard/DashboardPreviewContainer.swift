import SwiftUI

struct DashboardPreviewContainer<Content: View>: View {
    private let content: Content
    @StateObject private var userModel = UserDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var trainingModel = TrainingDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var statisticsModel = StatisticsDataModel(autostart: false, runStartupSideEffects: false)
    @StateObject private var foodModel = FoodDataModel(autostart: false, runStartupSideEffects: false)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .environmentObject(userModel)
                .environmentObject(trainingModel)
                .environmentObject(statisticsModel)
                .environmentObject(foodModel)
        }
    }
}
