import SwiftUI

struct DashboardTrainingSection: View {
    @EnvironmentObject private var userModel: UserDataModel

    let roundedWorkoutPercentage: Int
    @Binding var isWorkOutPresented: Bool
    var showsWorkoutButton: Bool? = nil

    private var shouldShowWorkoutButton: Bool {
        showsWorkoutButton ?? (userModel.user.workoutOfTheDay != nil)
    }

    var body: some View {
        Section(header: Text("Trainingen deze week")) {
            HStack {
                TrainingCircle()
                Text("\(roundedWorkoutPercentage) %")
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }

            if shouldShowWorkoutButton {
                HStack {
                    Button {
                        if userModel.user.workoutOfTheDay != nil {
                            isWorkOutPresented = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(.accentColor)
                            Text("Start je training van vandaag")
                                .font(.subheadline)
                                .foregroundColor(Color.init("blackWhite"))
                        }
                    }
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            }
        }
    }
}

struct TrainingCircle: View {
    @EnvironmentObject private var userModel: UserDataModel

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.accentColor.opacity(0.1))

            Capsule()
                .fill(Color.accentColor)
                .scaleEffect(
                    x: CGFloat(min(max(userModel.workoutDonePercentage, 0), 1)),
                    y: 1,
                    anchor: .leading
                )
                .animation(Animation.linear(duration: 0.5), value: userModel.workoutDonePercentage)
        }
        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardTrainingSection(
                roundedWorkoutPercentage: 65,
                isWorkOutPresented: .constant(true),
                showsWorkoutButton: true
            )
        }
        .listStyle(.insetGrouped)
    }
}
