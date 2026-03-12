# Grow

iOS app voor voeding, training, progressie en profielbeheer.

## Stack

- SwiftUI
- Firebase
  - Auth
  - Firestore
- HealthKit
- Google Mobile Ads
- StoreKit

## Startpunt

De app start in [GrowApp.swift](/Users/swenrolink/Development/Grow%20Native/Grow/Grow/GrowApp.swift).

Bij startup gebeurt onder andere:

- `FirebaseApp.configure()`
- `MobileAds.shared.start(...)`
- HealthKit authorisatie

De root UI wordt daarna opgebouwd via [SceneDelegate.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/SceneDelegate.swift).

## Belangrijkste structuur

### Views

- `Views/Dashboard`
  Dashboard, instellingen, login/register en preview-containers
- `Views/Food`
  Food diary, maaltijden, producten en food previews
- `Views/Training`
  Workout of the day, trainingsdashboard, schema-creatie
- `Views/Measurements`
  Progressie en metingen
- `Views/Profile`
  Profiel- en actiebladen

### State / ViewModels

- [UserVM.swift](/Users/swenrolink/Development/Grow/Grow/ViewModels/UserVM.swift)
  gebruikersdata, startup-logica, workout-of-the-day helpers
- [FoodModel.swift](/Users/swenrolink/Development/Grow/Grow/ViewModels/FoodModel.swift)
  food diary, maaltijden, producten
- [TrainingModel.swift](/Users/swenrolink/Development/Grow/Grow/ViewModels/TrainingModel.swift)
  schema’s, routines, workout data
- [StatisticsModel.swift](/Users/swenrolink/Development/Grow/Grow/ViewModels/StatisticsModel.swift)
  trainingsstatistieken en historie

### Models

- [UserModel.swift](/Users/swenrolink/Development/Grow/Grow/Models/UserModel.swift)
  domeinmodellen voor user, routines, weekplan, statistieken en food

## Root navigation

De hoofdtabbar staat in [DashboardView.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardView.swift) in `TabBarView`.

Tabs:

- Dashboard
- Training
- Progressie
- Instellingen

Deze root view maakt de gedeelde state aan met `@StateObject` en injecteert die via `environmentObject`.

## Firebase

Firebase-afhankelijke reads en writes zijn gedeeltelijk geïsoleerd achter protocolgebaseerde dependencies in [FirebaseDependencies.swift](/Users/swenrolink/Development/Grow/Grow/Helpers/FirebaseDependencies.swift).

Dat is toegevoegd zodat:

- startup sequencing testbaar is zonder netwerk
- viewmodels losser gekoppeld zijn aan Firestore
- previews en tests veiliger kunnen draaien

## HealthKit

HealthKit helpers staan in [HealthKit.swift](/Users/swenrolink/Development/Grow/Grow/Helpers/HealthKit.swift).

Huidig gebruik:

- meest recent gewicht
- meest recent vetpercentage
- stappen van vandaag

De dashboard HealthKit-sectie toont stappen alleen wanneer er daadwerkelijk een waarde beschikbaar is.

## Previews

De grotere schermen zijn opgesplitst in kleinere section views met eigen `#Preview` blocks.

Belangrijke preview helpers:

- [DashboardPreviewContainer.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardPreviewContainer.swift)
- [FoodPreviewContainer.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodPreviewContainer.swift)

Deze containers maken canvas-development mogelijk zonder live Firebase listeners of echte app-start side effects.

## Tests

Tests staan in `GrowTests`.

Belangrijkste bestanden:

- [ModelDecodingTests.swift](/Users/swenrolink/Development/Grow/GrowTests/ModelDecodingTests.swift)
- [StartupIsolationTests.swift](/Users/swenrolink/Development/Grow/GrowTests/StartupIsolationTests.swift)

De focus ligt nu op:

- decode-robustness voor legacy Firestore data
- startup behavior zonder netwerk
- viewmodel afhankelijkheden via protocolisolatie

## Veelgebruikte ontwikkelpunten

### Dashboard aanpassen

Werk vooral in:

- [DashboardView.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardView.swift)
- [DashboardNutritionSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardNutritionSection.swift)
- [DashboardTrainingSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardTrainingSection.swift)
- [DashboardBodyMetricsSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardBodyMetricsSection.swift)

### Food aanpassen

Werk vooral in:

- [FoodView.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodView.swift)
- [FoodSummarySection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodSummarySection.swift)
- [FoodMealSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodMealSection.swift)

### Trainingsschema creatie aanpassen

Werk vooral in:

- [CreateSchema.swift](/Users/swenrolink/Development/Grow/Grow/Views/Training/Creation/CreateSchema.swift)
- [Routines.swift](/Users/swenrolink/Development/Grow/Grow/Views/Training/Creation/Routines.swift)

## Opmerking

De codebase is deels gemigreerd naar een beter testbare structuur, maar bevat nog oudere SwiftUI/Firebase patronen. Nieuwe wijzigingen kunnen het beste aansluiten op:

- `@StateObject` voor owner views
- `@EnvironmentObject` voor gedeelde app-state
- preview-safe initialisatie
- protocolisolatie rond Firebase/StoreKit/HealthKit waar mogelijk
