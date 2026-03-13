import SwiftUI

struct DashboardTrainingSection: View {
    @EnvironmentObject private var userModel: UserDataModel

    let roundedWorkoutPercentage: Int
    @Binding var isWorkOutPresented: Bool
    var showsWorkoutButton: Bool? = nil

    private var todaysWorkoutID: UUID? {
        UserDataModel.routineID(
            for: userModel.user,
            dayOfWeek: userModel.getDayForWeekPlan()
        )
    }

    private var shouldShowWorkoutButton: Bool {
        showsWorkoutButton ?? (todaysWorkoutID != nil)
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
                        if todaysWorkoutID != nil {
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

    private var progress: CGFloat {
        CGFloat(min(max(userModel.workoutDonePercentage, 0), 1))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))

                if progress > 0 {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(
                            width: max(geometry.size.height, geometry.size.width * progress)
                        )
                }
            }
            .animation(.linear(duration: 0.5), value: userModel.workoutDonePercentage)
        }
        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
    }
}

#Preview {
    DashboardPreviewContainer {
        List {
            DashboardTrainingSection(
                roundedWorkoutPercentage: 10,
                isWorkOutPresented: .constant(true),
                showsWorkoutButton: true
            )
        }
        .listStyle(.insetGrouped)
    }
}
