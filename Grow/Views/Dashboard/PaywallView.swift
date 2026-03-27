//
//  PaywallView.swift
//  Grow
//
//  Created by OpenAI on 11/10/2025.
//

import SwiftUI
import StoreKit

struct PaywallPlanDisplay: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let priceText: String
    let badge: String?
    let isHighlighted: Bool
}

struct PaywallView: View {
    let plans: [PaywallPlanDisplay]
    let isRestoring: Bool
    let onSelectPlan: (PaywallPlanDisplay) -> Void
    let onRestore: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroSection

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(plans) { plan in
                        PaywallPlanCard(plan: plan) {
                            onSelectPlan(plan)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(
                        icon: "figure.strengthtraining.traditional",
                        title: "Trainingsschema's klaar voor gebruik",
                        subtitle: "Krijg toegang tot trainingsschema's die direct in Grow te gebruiken zijn."
                    )
                    BenefitRow(
                        icon: "fork.knife.circle",
                        title: "Maaltijden met recepten",
                        subtitle: "Bewaar complete maaltijden, importeer recepten en werk sneller in je food diary."
                    )
                    BenefitRow(
                        icon: "chart.xyaxis.line",
                        title: "Training- en oefenstatistieken",
                        subtitle: "Volg je voortgang met uitgebreide statistieken voor oefeningen en trainingen."
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.78))
                )

                VStack(spacing: 10) {
                    Button("Herstel aankopen") {
                        onRestore()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isRestoring)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .background(paywallBackground.ignoresSafeArea())
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Grow Premium")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.opacity(0.14))
                    )
                Spacer()
            }

            Text("Ontgrendel alles wat Grow sterk maakt.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            Text("Een actief abonnement is vereist om verder te gaan. Daarmee krijg je toegang tot trainingsschema's, maaltijden met recepten en uitgebreide statistieken.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.95),
                                Color.accentColor.opacity(0.78),
                                Color.orange.opacity(0.86)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 210)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Trainingsschema's inbegrepen", systemImage: "list.bullet.clipboard")
                    Label("Recept-maaltijden opslaan", systemImage: "fork.knife.circle.fill")
                    Label("Statistieken en voortgang", systemImage: "chart.bar.fill")
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)

                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .offset(x: 20, y: 24)
            }
        }
    }

    private var paywallBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.90),
                    Color(red: 0.94, green: 0.98, blue: 0.95),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(0.08))
                .frame(width: 220, height: 220)
                .offset(x: 120, y: -260)

            Circle()
                .fill(Color.orange.opacity(0.08))
                .frame(width: 280, height: 280)
                .offset(x: -150, y: 260)
        }
    }
}

struct RegistrationPaywallScreen: View {
    @StateObject private var storeManager = StoreManager()

    let onFinished: () -> Void

    private var planDisplays: [PaywallPlanDisplay] {
        let livePlans = storeManager.myProducts.enumerated().map { index, product in
            PaywallPlanDisplay(
                title: product.displayName,
                subtitle: product.description.isEmpty ? "Premium toegang voor Grow." : product.description,
                priceText: product.displayPrice,
                badge: index == 0 ? "Aanbevolen" : nil,
                isHighlighted: index == 0
            )
        }

        if livePlans.isEmpty {
            return PaywallView.previewPlans
        }

        return livePlans
    }

    var body: some View {
        NavigationStack {
            PaywallView(
                plans: planDisplays,
                isRestoring: false,
                onSelectPlan: purchase(plan:),
                onRestore: storeManager.restoreProducts
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .onAppear {
            storeManager.startObserving()
            storeManager.getProducts()
        }
        .onDisappear {
            storeManager.stopObserving()
        }
        .onChange(of: storeManager.transactionDates) { _, dates in
            if dates.isEmpty == false {
                onFinished()
            }
        }
    }

    private func purchase(plan: PaywallPlanDisplay) {
        guard let product = storeManager.myProducts.first(where: { $0.displayName == plan.title }) else {
            return
        }

        storeManager.purchaseProduct(product: product)
    }
}

private struct PaywallPlanCard: View {
    let plan: PaywallPlanDisplay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(plan.isHighlighted ? Color.white : .primary)
                        Text(plan.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(plan.isHighlighted ? Color.white.opacity(0.84) : .secondary)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 8) {
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(plan.isHighlighted ? Color.accentColor : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(plan.isHighlighted ? Color.white.opacity(0.85) : Color.secondary.opacity(0.12))
                                )
                        }

                        Text(plan.priceText)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(plan.isHighlighted ? Color.white : .primary)
                    }
                }

                HStack {
                    Text("Direct starten")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(plan.isHighlighted ? Color.white : Color.accentColor)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(plan.isHighlighted ? Color.white : Color.accentColor)
                }
            }
            .padding(20)
            .background(backgroundView)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(plan.isHighlighted ? Color.accentColor.opacity(0.24) : Color.black.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                plan.isHighlighted
                ? LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.92),
                        Color.accentColor.opacity(0.74)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color.white.opacity(0.88),
                        Color.white.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension PaywallView {
    static let previewPlans: [PaywallPlanDisplay] = [
        PaywallPlanDisplay(
            title: "Jaarabonnement",
            subtitle: "Volledige toegang tot schema's, recepten en statistieken.",
            priceText: "€39,99 / jaar",
            badge: "Meest gekozen",
            isHighlighted: true
        ),
        PaywallPlanDisplay(
            title: "Maandabonnement",
            subtitle: "Flexibel beginnen met alle premium onderdelen.",
            priceText: "€5,99 / maand",
            badge: nil,
            isHighlighted: false
        )
    ]
}

#Preview("Paywall") {
    PaywallView(
        plans: PaywallView.previewPlans,	
        isRestoring: false,
        onSelectPlan: { _ in },
        onRestore: {}
    )
}
