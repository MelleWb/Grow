//
//  ContentView.swift
//  Watch me Grow Watch App
//
//  Created by Swen Rolink on 14/03/2026.
//

import SwiftUI
import Combine
import WatchConnectivity

struct ContentView: View {
    @StateObject private var syncStore = WatchFoodSummaryStore()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.12, blue: 0.10),
                    Color(red: 0.12, green: 0.18, blue: 0.14),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let summary = syncStore.summary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        WatchFoodHeroCard(summary: summary)

                        WatchRemainingBarsCard(summary: summary)

                        VStack(spacing: 10) {
                            WatchMacroRingCard(
                                title: "Koolhydraten over",
                                remaining: summary.remainingCarbs,
                                budget: summary.budgetCarbs,
                                progress: summary.usedRatioCarbs,
                                tint: Color.orange
                            )
                            WatchMacroRingCard(
                                title: "Eiwitten over",
                                remaining: summary.remainingProtein,
                                budget: summary.budgetProtein,
                                progress: summary.usedRatioProtein,
                                tint: Color.green
                            )
                            WatchMacroRingCard(
                                title: "Vetten over",
                                remaining: summary.remainingFat,
                                budget: summary.budgetFat,
                                progress: summary.usedRatioFat,
                                tint: Color.yellow
                            )
                            WatchMacroRingCard(
                                title: "Vezels over",
                                remaining: summary.remainingFiber,
                                budget: summary.budgetFiber,
                                progress: summary.usedRatioFiber,
                                tint: Color.cyan
                            )
                        }

                        Text("Bijgewerkt \(summary.updatedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(10)
                }
            } else {
                ContentUnavailableView {
                    Label("Nog geen data", systemImage: "fork.knife.circle")
                } description: {
                    Text("Open Grow op je iPhone om je voeding van vandaag te synchroniseren.")
                }
            }
        }
    }
}

private final class WatchFoodSummaryStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var summary: WatchFoodSummary?
    private let requestMessageKey = "requestFoodSummary"

    override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        if let summary = WatchFoodSummary(context: session.receivedApplicationContext) {
            self.summary = summary
        } else {
            requestLatestSummary()
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("Watch session activation failed: \(error)")
        }

        if let summary = WatchFoodSummary(context: session.receivedApplicationContext) {
            DispatchQueue.main.async {
                self.summary = summary
            }
        } else {
            requestLatestSummary()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let summary = WatchFoodSummary(context: applicationContext) else {
            return
        }

        DispatchQueue.main.async {
            self.summary = summary
        }
    }

    private func requestLatestSummary() {
        let session = WCSession.default

        guard session.activationState == .activated else {
            return
        }

        session.sendMessage([requestMessageKey: true], replyHandler: { payload in
            guard let summary = WatchFoodSummary(context: payload) else {
                return
            }

            DispatchQueue.main.async {
                self.summary = summary
            }
        }, errorHandler: { error in
            print("Watch summary request failed: \(error)")
        })
    }
}

private struct WatchFoodSummary {
    let updatedAt: Date
    let remainingKcal: Double
    let remainingCarbs: Double
    let remainingFat: Double
    let remainingProtein: Double
    let remainingFiber: Double
    let budgetKcal: Double
    let budgetCarbs: Double
    let budgetFat: Double
    let budgetProtein: Double
    let budgetFiber: Double
    let usedRatioKcal: Double
    let usedRatioCarbs: Double
    let usedRatioFat: Double
    let usedRatioProtein: Double
    let usedRatioFiber: Double

    init?(context: [String: Any]) {
        guard
            let updatedAt = context["updatedAt"] as? Double,
            let remainingKcal = context["remainingKcal"] as? Double,
            let remainingCarbs = context["remainingCarbs"] as? Double,
            let remainingFat = context["remainingFat"] as? Double,
            let remainingProtein = context["remainingProtein"] as? Double,
            let remainingFiber = context["remainingFiber"] as? Double,
            let budgetKcal = context["budgetKcal"] as? Double,
            let budgetCarbs = context["budgetCarbs"] as? Double,
            let budgetFat = context["budgetFat"] as? Double,
            let budgetProtein = context["budgetProtein"] as? Double,
            let budgetFiber = context["budgetFiber"] as? Double,
            let usedRatioKcal = context["usedRatioKcal"] as? Double,
            let usedRatioCarbs = context["usedRatioCarbs"] as? Double,
            let usedRatioFat = context["usedRatioFat"] as? Double,
            let usedRatioProtein = context["usedRatioProtein"] as? Double,
            let usedRatioFiber = context["usedRatioFiber"] as? Double
        else {
            return nil
        }

        self.updatedAt = Date(timeIntervalSince1970: updatedAt)
        self.remainingKcal = remainingKcal
        self.remainingCarbs = remainingCarbs
        self.remainingFat = remainingFat
        self.remainingProtein = remainingProtein
        self.remainingFiber = remainingFiber
        self.budgetKcal = budgetKcal
        self.budgetCarbs = budgetCarbs
        self.budgetFat = budgetFat
        self.budgetProtein = budgetProtein
        self.budgetFiber = budgetFiber
        self.usedRatioKcal = usedRatioKcal
        self.usedRatioCarbs = usedRatioCarbs
        self.usedRatioFat = usedRatioFat
        self.usedRatioProtein = usedRatioProtein
        self.usedRatioFiber = usedRatioFiber
    }
}

private struct WatchFoodHeroCard: View {
    let summary: WatchFoodSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vandaag over")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(numberString(summary.remainingKcal))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("kcal")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 10)

                Capsule()
                    .fill(progressColor(for: summary.remainingKcal).gradient)
                    .frame(width: max(10, 150 * progressValue(summary.usedRatioKcal)), height: 10)
            }

            Text(summary.remainingKcal >= 0 ? "Nog ruimte voor vandaag" : "Je zit boven je doel")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.86, green: 0.35, blue: 0.18),
                            Color(red: 0.98, green: 0.60, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func numberString(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private func progressColor(for remaining: Double) -> Color {
        remaining >= 0 ? .white : .red
    }

    private func progressValue(_ usedRatio: Double) -> Double {
        min(max(usedRatio, 0), 1)
    }
}

private struct WatchRemainingBarsCard: View {
    let summary: WatchFoodSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overzicht")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            WatchBarRow(title: "Kcal", remaining: summary.remainingKcal, progress: summary.usedRatioKcal, tint: .orange)
            WatchBarRow(title: "Koolh.", remaining: summary.remainingCarbs, progress: summary.usedRatioCarbs, tint: .orange)
            WatchBarRow(title: "Eiwit", remaining: summary.remainingProtein, progress: summary.usedRatioProtein, tint: .green)
            WatchBarRow(title: "Vet", remaining: summary.remainingFat, progress: summary.usedRatioFat, tint: .yellow)
            WatchBarRow(title: "Vezels", remaining: summary.remainingFiber, progress: summary.usedRatioFiber, tint: .cyan)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}

private struct WatchBarRow: View {
    let title: String
    let remaining: Double
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                Text("\(Int(remaining.rounded()))")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))

                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(8, proxy.size.width * CGFloat(progressValue)))
                }
            }
            .frame(height: 6)
        }
    }

    private var progressValue: Double {
        min(max(progress, 0), 1)
    }
}

private struct WatchMacroRingCard: View {
    let title: String
    let remaining: Double
    let budget: Double
    let progress: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(remaining.rounded()))")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                Text("doel: \(Int(budget.rounded()))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}

#Preview {
    ContentView()
}
