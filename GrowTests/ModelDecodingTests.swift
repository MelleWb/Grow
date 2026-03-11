import Foundation
import Testing
@testable import Grow

struct ModelDecodingTests {
    @Test
    func userDecodesBrokenWeekPlanWithoutFailingWholeUser() throws {
        let data = Data(
            """
            {
                "firstName": "Swen",
                "weekPlan": [
                    {
                        "trainingType": "Push",
                        "routine": "definitely-not-a-uuid",
                        "isTrainingDay": true
                    }
                ]
            }
            """.utf8
        )

        let user = try JSONDecoder().decode(User.self, from: data)

        #expect(user.firstName == "Swen")
        #expect(user.weekPlan?.count == 1)
        #expect(user.weekPlan?.first?.routine == nil)
        #expect(user.weekPlan?.first?.isTrainingDay == true)
    }

    @Test
    func dayPlanDecodesInvalidRoutineUUIDAsNil() throws {
        let data = Data(
            """
            {
                "id": "E2C4A5E4-4C1B-4D3A-8B65-1F42B73D1F2A",
                "trainingType": "Push",
                "routine": "not-a-valid-uuid",
                "isTrainingDay": true
            }
            """.utf8
        )

        let dayPlan = try JSONDecoder().decode(DayPlan.self, from: data)

        #expect(dayPlan.trainingType == "Push")
        #expect(dayPlan.isTrainingDay == true)
        #expect(dayPlan.routine == nil)
    }

    @Test
    func workoutOfTheDayReturnsNilWhenWeekPlanIsMissing() {
        let workoutOfTheDay = UserDataModel.workoutOfTheDay(for: nil, dayOfWeek: 0)

        #expect(workoutOfTheDay == nil)
    }

    @Test
    func workoutOfTheDayReturnsNilForRestDay() {
        let routineID = UUID()
        let weekPlan = [
            DayPlan(trainingType: "Rest", routine: routineID, isTrainingDay: false)
        ]

        let workoutOfTheDay = UserDataModel.workoutOfTheDay(for: weekPlan, dayOfWeek: 0)

        #expect(workoutOfTheDay == nil)
    }

    @Test
    func workoutOfTheDayReturnsRoutineForTrainingDay() {
        let routineID = UUID()
        let weekPlan = [
            DayPlan(trainingType: "Push", routine: routineID, isTrainingDay: true)
        ]

        let workoutOfTheDay = UserDataModel.workoutOfTheDay(for: weekPlan, dayOfWeek: 0)

        #expect(workoutOfTheDay == routineID)
    }

    @Test
    func routineIDPrefersExplicitWorkoutOfTheDay() {
        let scheduledRoutineID = UUID()
        let explicitRoutineID = UUID()
        var user = User()
        user.weekPlan = [DayPlan(trainingType: "Push", routine: scheduledRoutineID, isTrainingDay: true)]
        user.workoutOfTheDay = explicitRoutineID

        let routineID = UserDataModel.routineID(for: user, dayOfWeek: 0)

        #expect(routineID == explicitRoutineID)
    }

    @Test
    func routineIDFallsBackToWeekPlanWhenWorkoutOfTheDayIsMissing() {
        let scheduledRoutineID = UUID()
        var user = User()
        user.weekPlan = [DayPlan(trainingType: "Push", routine: scheduledRoutineID, isTrainingDay: true)]

        let routineID = UserDataModel.routineID(for: user, dayOfWeek: 0)

        #expect(routineID == scheduledRoutineID)
    }

    @Test
    func routineIDIsNilWhenUserHasNoAvailableRoutine() {
        let user = User()

        let routineID = UserDataModel.routineID(for: user, dayOfWeek: 0)

        #expect(routineID == nil)
    }

    @Test
    func trainingDayCountCountsOnlyTrainingDays() {
        let weekPlan = [
            DayPlan(trainingType: "Push", routine: UUID(), isTrainingDay: true),
            DayPlan(trainingType: "Rest", routine: nil, isTrainingDay: false),
            DayPlan(trainingType: "Pull", routine: UUID(), isTrainingDay: true)
        ]

        let trainingDayCount = UserDataModel.trainingDayCount(for: weekPlan)

        #expect(trainingDayCount == 2)
    }

    @Test
    func trainingDayCountReturnsZeroForMissingWeekPlan() {
        let trainingDayCount = UserDataModel.trainingDayCount(for: nil)

        #expect(trainingDayCount == 0)
    }

    @Test
    func calorieBudgetUsesSportCaloriesForTrainingDays() {
        var user = User()
        user.weekPlan = [DayPlan(trainingType: "Push", routine: UUID(), isTrainingDay: true)]
        user.sportCalories = Macros(kcal: 2500, carbs: 300, protein: 180, fat: 70, fiber: 30)
        user.restCalories = Macros(kcal: 2000, carbs: 200, protein: 160, fat: 60, fiber: 25)

        let budget = FoodDataModel.calorieBudget(for: user, dayOfWeek: 0)

        #expect(budget.kcal == 2500)
        #expect(budget.carbs == 300)
        #expect(budget.protein == 180)
    }

    @Test
    func calorieBudgetFallsBackToRestCaloriesWhenWeekPlanIsMissing() {
        var user = User()
        user.restCalories = Macros(kcal: 2000, carbs: 200, protein: 160, fat: 60, fiber: 25)

        let budget = FoodDataModel.calorieBudget(for: user, dayOfWeek: 0)

        #expect(budget.kcal == 2000)
        #expect(budget.carbs == 200)
        #expect(budget.protein == 160)
    }

    @Test
    func calorieBudgetFallsBackToRestCaloriesWhenWeekPlanIsIncomplete() {
        var user = User()
        user.weekPlan = [DayPlan(trainingType: "Push", routine: UUID(), isTrainingDay: true)]
        user.restCalories = Macros(kcal: 1900, carbs: 180, protein: 150, fat: 55, fiber: 20)

        let budget = FoodDataModel.calorieBudget(for: user, dayOfWeek: 3)

        #expect(budget.kcal == 1900)
        #expect(budget.carbs == 180)
        #expect(budget.protein == 150)
    }

    @Test
    func exerciseDecodesWithoutStoredID() throws {
        let data = Data(
            """
            {
                "name": "Bench Press",
                "reps": 8,
                "category": "Chest",
                "description": "Flat bench press"
            }
            """.utf8
        )

        let exercise = try JSONDecoder().decode(Exercise.self, from: data)

        #expect(exercise.name == "Bench Press")
        #expect(exercise.reps == 8)
        #expect(exercise.category == "Chest")
    }

    @Test
    func schemaDecodesLegacyNestedExercisesWithoutIDs() throws {
        let data = Data(
            """
            {
                "type": "training",
                "name": "Starter Schema",
                "routines": [
                    {
                        "type": "Push",
                        "superset": [
                            {
                                "sets": 3,
                                "exercises": [
                                    {
                                        "name": "Bench Press",
                                        "reps": 10,
                                        "category": "Chest"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
            """.utf8
        )

        let schema = try JSONDecoder().decode(Schema.self, from: data)

        #expect(schema.name == "Starter Schema")
        #expect(schema.routines.count == 1)
        #expect(schema.routines[0].type == "Push")
        #expect(schema.routines[0].superset.count == 1)
        #expect(schema.routines[0].superset[0].exercises.count == 1)
        #expect(schema.routines[0].superset[0].exercises[0].name == "Bench Press")
    }
}
