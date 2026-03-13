import SwiftUI

struct FoodMealSection: View {
    @Binding var enableSheet: Bool
    @Binding var mealToCopy: Meal
    let meal: Meal
    @Binding var showAddProductToMeal: Bool
    @Binding var selectedMeal: Meal
    @Binding var mealToSave: Meal?
    @Binding var showSaveAsMeal: Bool
    @FocusState var focusedField: UUID?
    let onOpenMealDetail: () -> Void
    let onCopyMealForwardOneDay: () -> Void
    let onDeleteMeal: () -> Void

    var body: some View {
        Section {
            HStack {
                FoodMealHeader(
                    enableSheet: $enableSheet,
                    mealToCopy: $mealToCopy,
                    meal: meal,
                    onSaveAsMeal: {
                        mealToSave = meal
                        showSaveAsMeal = true
                    },
                    onOpenMealDetail: onOpenMealDetail
                )
                Spacer()
                Text("\(NumberHelper.roundedNumbersFromDouble(unit: meal.kcal)) Kcal")
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(action: onCopyMealForwardOneDay) {
                    Label("Kopieer", systemImage: "doc.on.doc")
                }
                .tint(.indigo)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDeleteMeal) {
                    Label("Verwijder", systemImage: "trash.fill")
                }
            }

            FoodProductsList(meal: meal)

            Button(action: {
                selectedMeal = meal
                showAddProductToMeal = true
            }) {
                HStack {
                    Image(systemName: "plus").foregroundColor(.accentColor)
                    Text("Voeg product toe").foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct FoodProductsList: View {
    @EnvironmentObject var foodModel: FoodDataModel
    let meal: Meal

    var body: some View {
        if let products = meal.products {
            ForEach(products, id: \.self) { product in
                FoodProductRow(meal: meal, product: product)
            }
            .onDelete(perform: deleteProduct)
        }
    }

    private func deleteProduct(at offsets: IndexSet) {
        let productIndex = offsets[offsets.startIndex]
        self.foodModel.deleteProductFromMeal(for: meal, with: productIndex)
    }
}

struct FoodProductRow: View {
    let meal: Meal
    let product: Product

    var body: some View {
        NavigationLink(destination: ChangeIntakeOfProduct(product: product, meal: meal, amount: String(product.selectedProductDetails?.amount ?? 0))) {
            HStack {
                VStack(alignment: .leading) {
                    Text(String(product.name)).padding(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
                    Text("\(product.selectedProductDetails?.amount ?? 0) gram").font(.footnote).foregroundColor(.gray)
                }
                Spacer()
                Text(NumberHelper.roundedNumbersFromDouble(unit: product.selectedProductDetails?.kcal ?? 0))
            }
        }
    }
}

struct FoodMealHeader: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var enableSheet: Bool
    @Binding var mealToCopy: Meal
    let meal: Meal
    let onSaveAsMeal: () -> Void
    let onOpenMealDetail: () -> Void

    var body: some View {
        if let mealIndex = foodModel.getMealIndex(for: meal) {
            Button {
                onOpenMealDetail()
            } label: {
                Text(meal.name?.isEmpty == false ? meal.name! : "Maaltijd \(mealIndex + 1)")
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .contextMenu(menuItems: {
                VStack {
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.meals![mealIndex].kcal)) Calorieën")
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.meals![mealIndex].carbs)) Koolhydraten")
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.meals![mealIndex].protein)) Eiwitten")
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.meals![mealIndex].fat)) Vetten")
                    Text("\(NumberHelper.roundedNumbersFromDouble(unit: self.foodModel.foodDiary.meals![mealIndex].fiber)) Vezels")
                }
                Button(action: onSaveAsMeal) {
                    Text("Sla maaltijd op")
                    Image(systemName: "square.and.arrow.down")
                        .resizable()
                        .frame(width: 17, height: 20, alignment: .trailing)
                }
                Button(action: {
                    self.mealToCopy = meal
                    self.enableSheet = true
                }) {
                    Text("Kopieren")
                    Image(systemName: "doc.on.doc")
                        .resizable()
                        .frame(width: 17, height: 20, alignment: .trailing)
                }
                Button(action: {
                    foodModel.removeMeal(for: meal)
                }) {
                    Text("Verwijder")
                    Image(systemName: "trash")
                        .resizable()
                        .frame(width: 17, height: 20, alignment: .trailing)
                }
            })
        }
    }
}

private struct FoodMealSectionPreviewHarness: View {
    @State private var enableSheet = false
    @State private var mealToCopy = Meal()
    @State private var showAddProductToMeal = false
    @State private var selectedMeal = Meal()
    @State private var mealToSave: Meal?
    @State private var showSaveAsMeal = false
    @FocusState private var focusedField: UUID?

    private let previewMeal = Meal(
        name: "Lunch",
        products: [
            Product(
                name: "Havermout",
                kcal: 380,
                carbs: 62,
                protein: 13,
                fat: 7,
                fiber: 9,
                selectedProductDetails: SelectedProductDetails(kcal: 304, carbs: 49.6, protein: 10.4, fat: 5.6, fiber: 7.2, amount: 80)
            ),
            Product(
                name: "Whey",
                kcal: 400,
                carbs: 8,
                protein: 78,
                fat: 6,
                fiber: 0,
                selectedProductDetails: SelectedProductDetails(kcal: 120, carbs: 2.4, protein: 23.4, fat: 1.8, fiber: 0, amount: 30)
            )
        ],
        kcal: 424,
        carbs: 52,
        protein: 34,
        fat: 8,
        fiber: 7
    )

    var body: some View {
        FoodMealSection(
            enableSheet: $enableSheet,
            mealToCopy: $mealToCopy,
            meal: previewMeal,
            showAddProductToMeal: $showAddProductToMeal,
            selectedMeal: $selectedMeal,
            mealToSave: $mealToSave,
            showSaveAsMeal: $showSaveAsMeal,
            focusedField: _focusedField,
            onOpenMealDetail: {},
            onCopyMealForwardOneDay: {},
            onDeleteMeal: {}
        )
    }
}

#Preview {
    FoodPreviewContainer(
        diary: FoodDiary(
            meals: [
                Meal(
                    name: "Lunch",
                    products: [
                        Product(
                            name: "Havermout",
                            kcal: 380,
                            carbs: 62,
                            protein: 13,
                            fat: 7,
                            fiber: 9,
                            selectedProductDetails: SelectedProductDetails(kcal: 304, carbs: 49.6, protein: 10.4, fat: 5.6, fiber: 7.2, amount: 80)
                        ),
                        Product(
                            name: "Whey",
                            kcal: 400,
                            carbs: 8,
                            protein: 78,
                            fat: 6,
                            fiber: 0,
                            selectedProductDetails: SelectedProductDetails(kcal: 120, carbs: 2.4, protein: 23.4, fat: 1.8, fiber: 0, amount: 30)
                        )
                    ],
                    kcal: 424,
                    carbs: 52,
                    protein: 34,
                    fat: 8,
                    fiber: 7
                )
            ]
        )
    ) {
        List {
            FoodMealSectionPreviewHarness()
        }
        .listStyle(.grouped)
    }
}
