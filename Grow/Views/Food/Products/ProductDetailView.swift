//
//  ProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 25/08/2021.
//

import SwiftUI

struct ProductDetailView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    @State var product: Product = Product()
    @State var meal: Meal
    @State var documentID: String
    @Binding var isPresented: Bool

    @State private var isLoading = true

    @State var amount: String = "100"

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Product laden")
            } else {
                ProductIntakeEditorView(
                    product: product,
                    initialAmount: NumberFormatter().number(from: amount)?.intValue ?? 100,
                    saveButtonTitle: "Voeg toe",
                    onSave: { createdProduct in
                        foodModel.addProductToMeal(for: meal, with: product, with: createdProduct)
                    },
                    onSuccess: {
                        isPresented = false
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            foodModel.getProductDetails(documentID: documentID, completion: { product, error in
                if let product = product {
                    self.product = product
                } else {
                    isPresented = false
                    dismiss()
                }
                isLoading = false
            })
        }
    }
}
