# Architectuur en UI Ontwikkeling

## View composition

De app beweegt geleidelijk weg van grote monolithische SwiftUI files.

### Dashboard

Het dashboard is opgesplitst in losse secties:

- [DashboardNutritionSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardNutritionSection.swift)
- [DashboardMeasurementSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardMeasurementSection.swift)
- [DashboardTrainingSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardTrainingSection.swift)
- [DashboardBodyMetricsSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardBodyMetricsSection.swift)

Doel:

- overzichtelijkere files
- snellere iteratie in canvas
- minder regressies bij UI-aanpassingen

### Food

De food flow is ook opgesplitst:

- [FoodSummarySection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodSummarySection.swift)
- [FoodSavedMealsSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodSavedMealsSection.swift)
- [FoodMealSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodMealSection.swift)
- [FoodAddMealSection.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodAddMealSection.swift)

## Preview aanpak

Voor previews gebruiken we speciale container views zodat:

- Firebase listeners niet automatisch starten
- preview data expliciet gezet kan worden
- meerdere UI-states naast elkaar getoond kunnen worden

Zie:

- [DashboardPreviewContainer.swift](/Users/swenrolink/Development/Grow/Grow/Views/Dashboard/DashboardPreviewContainer.swift)
- [FoodPreviewContainer.swift](/Users/swenrolink/Development/Grow/Grow/Views/Food/FoodPreviewContainer.swift)

## Data ownership

Basisregel in deze codebase:

- `@StateObject` als de view het object zelf maakt en bezit
- `@ObservedObject` alleen als het object van buiten wordt aangeleverd
- `@EnvironmentObject` voor app-brede gedeelde state

De root state wordt gemaakt in `TabBarView`.

## Firebase isolatie

Om tests en previews stabieler te maken, zijn Firebase-afhankelijke stukken achter protocollen gezet in [FirebaseDependencies.swift](/Users/swenrolink/Development/Grow/Grow/Helpers/FirebaseDependencies.swift).

Voorbeelden:

- user loading
- food reads/writes
- training reads/writes
- statistics reads/writes

Hierdoor kunnen viewmodels met fake dependencies worden opgebouwd in tests.

## Test focus

De huidige teststrategie richt zich vooral op twee risico’s:

1. Legacy Firestore data die decode errors veroorzaakt
2. Startup logica die stilvalt wanneer netwerk of cache niet overeenkomt

Zie:

- [ModelDecodingTests.swift](/Users/swenrolink/Development/Grow/GrowTests/ModelDecodingTests.swift)
- [StartupIsolationTests.swift](/Users/swenrolink/Development/Grow/GrowTests/StartupIsolationTests.swift)

## Aanbevolen vervolg

Als nieuwe UI-schermen groot worden:

1. split de view op in sections of cards
2. geef elke sectie een eigen `#Preview`
3. houd side effects uit previews
4. verplaats pure berekeningen naar helpers zodat ze testbaar blijven
