//
//  SceneDelegate.swift
//  Grow
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SceneDelegate: View {

    enum RootDestination: Equatable {
        case loading
        case login
        case verification(email: String)
        case profileCompletion
        case dashboard
    }

    @State private var viewToDisplay: RootDestination = .loading
    @State private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    @State private var authFlowMessage: String?

    @StateObject private var userModel = UserDataModel(autostart: false)
    @StateObject private var trainingModel = TrainingDataModel(autostart: false)
    @StateObject private var statisticsModel = StatisticsDataModel(autostart: false)
    @StateObject private var foodModel = FoodDataModel(autostart: false)

    var body: some View {
        Group {
            switch viewToDisplay {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .login:
                Login()
            case .verification(let email):
                VerificationGateView(
                    email: email,
                    message: authFlowMessage,
                    onRefresh: refreshAuthenticatedState,
                    onResend: resendVerificationEmail,
                    onSignOut: signOutCurrentUser
                )
            case .profileCompletion:
                NavigationStack {
                    Profile(
                        showsLogout: true,
                        onProfileSaved: {
                            Task {
                                await refreshAuthenticatedState()
                            }
                        }
                    )
                }
            case .dashboard:
                TabBarView()
            }
        }
        .onAppear {
            trainingModel.fetchData()

            authStateListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                Task {
                    await handleAuthStateChange(user: user)
                }
            }
        }
        .onDisappear {
            if let authStateListenerHandle {
                Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
                self.authStateListenerHandle = nil
            }
        }
        .environment(\.locale, Locale(identifier: "nl_NL"))
        .environmentObject(userModel)
        .environmentObject(trainingModel)
        .environmentObject(statisticsModel)
        .environmentObject(foodModel)
    }

    @MainActor
    private func handleAuthStateChange(user: FirebaseAuth.User?) async {
        authFlowMessage = nil

        guard let user else {
            viewToDisplay = .login
            userModel.queryRunning = false
            return
        }

        viewToDisplay = .loading

        do {
            try await reload(user: user)

            guard user.isEmailVerified else {
                viewToDisplay = .verification(email: user.email ?? "")
                return
            }

            try await ensureFirestoreUserDocumentExists(uid: user.uid)
            try await fetchCurrentUser(uid: user.uid)

            if userModel.user.hasRequiredProfileData {
                foodModel.initiateFoodModel()
                trainingModel.initiateTrainingModel()
                statisticsModel.initiateStatistics()
                viewToDisplay = .dashboard
            } else {
                viewToDisplay = .profileCompletion
            }
        } catch {
            authFlowMessage = error.localizedDescription
            viewToDisplay = .login
        }
    }

    @MainActor
    private func refreshAuthenticatedState() async {
        await handleAuthStateChange(user: Auth.auth().currentUser)
    }

    @MainActor
    private func resendVerificationEmail() async {
        guard let user = Auth.auth().currentUser else {
            authFlowMessage = "Er is geen gebruiker aangemeld."
            return
        }

        do {
            try await sendVerificationEmail(to: user)
            authFlowMessage = "Er is een nieuwe verificatiemail verstuurd."
        } catch {
            authFlowMessage = error.localizedDescription
        }
    }

    @MainActor
    private func signOutCurrentUser() {
        do {
            try Auth.auth().signOut()
            viewToDisplay = .login
        } catch {
            authFlowMessage = error.localizedDescription
        }
    }

    private func reload(user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reload { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func sendVerificationEmail(to user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.sendEmailVerification { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func ensureFirestoreUserDocumentExists(uid: String) async throws {
        let db = Firestore.firestore()

        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            db.collection("users").document(uid).getDocument { document, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let document {
                    continuation.resume(returning: document)
                } else {
                    continuation.resume(throwing: NSError(domain: "GrowAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Gebruiker kon niet worden geladen."]))
                }
            }
        }

        guard snapshot.exists == false else {
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("users").document(uid).setData([:]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func fetchCurrentUser(uid: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            userModel.fetchUser(uid: uid) {
                if let errorMessage = userModel.errorMessage {
                    continuation.resume(throwing: NSError(domain: "GrowAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

private struct VerificationGateView: View {
    let email: String
    let message: String?
    let onRefresh: () async -> Void
    let onResend: () async -> Void
    let onSignOut: () -> Void

    @State private var isRefreshing = false
    @State private var isResending = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                Text("Verifieer je e-mail")
                    .font(.largeTitle.bold())

                Text("We hebben een verificatielink gestuurd naar \(email). Bevestig eerst je e-mailadres voordat je verdergaat.")
                    .foregroundStyle(.secondary)

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        isRefreshing = true
                        await onRefresh()
                        isRefreshing = false
                    }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Ik heb mijn e-mail bevestigd")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRefreshing || isResending)

                Button {
                    Task {
                        isResending = true
                        await onResend()
                        isResending = false
                    }
                } label: {
                    if isResending {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Stuur nieuwe verificatielink")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isRefreshing || isResending)

                Button("Uitloggen", action: onSignOut)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
