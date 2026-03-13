//
//  Register.swift
//  Grow
//
//  Created by Melle Wittebrood on 31/12/2021.
//

import SwiftUI
import FirebaseAuth

struct Register: View {

    enum FocusFields {
        case email, password, confirmPassword
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FocusFields?

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var alertText = ""
    @State private var showAlert = false

    private var isEmailValid: Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailFormat).evaluate(with: email)
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var canSubmit: Bool {
        isEmailValid && password.count >= 6 && passwordsMatch
    }

    private func register() {
        guard canSubmit else {
            alertText = "Vul een geldig e-mailadres in en zorg dat de wachtwoorden overeenkomen."
            showAlert = true
            return
        }

        isSubmitting = true

        Auth.auth().createUser(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) { authResult, error in
            if let error {
                isSubmitting = false
                alertText = error.localizedDescription
                showAlert = true
                return
            }

            authResult?.user.sendEmailVerification { verificationError in
                isSubmitting = false

                if let verificationError {
                    alertText = verificationError.localizedDescription
                    showAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Maak een account")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)

                Text("Na registratie ontvang je een verificatiemail. Na bevestiging vragen we je profielgegevens aan.")
                    .foregroundStyle(.secondary)

                TextField("E-mail", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color("textField"))
                    .cornerRadius(15)
                    .focused($focusedField, equals: .email)

                if email.isEmpty == false && isEmailValid == false {
                    Text("Voer een geldig e-mailadres in.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                SecureField("Wachtwoord", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color("textField"))
                    .cornerRadius(15)
                    .focused($focusedField, equals: .password)

                if password.isEmpty == false && password.count < 6 {
                    Text("Gebruik minimaal 6 tekens.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                SecureField("Bevestig wachtwoord", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color("textField"))
                    .cornerRadius(15)
                    .focused($focusedField, equals: .confirmPassword)

                if confirmPassword.isEmpty == false && passwordsMatch == false {
                    Text("De wachtwoorden komen niet overeen.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: register) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Account aanmaken")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSubmitting || canSubmit == false)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Registreren")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registratie", isPresented: $showAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(alertText)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(action: {
                    focusedField = nil
                }, label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.accentColor)
                })
            }
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                focusedField = nil
                register()
            case .none:
                break
            }
        }
    }
}

struct Register_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Register()
        }
    }
}
