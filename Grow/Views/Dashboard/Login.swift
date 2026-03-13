//
//  Login.swift
//  Grow
//
//  Created by Swen Rolink on 10/12/2021.
//

import SwiftUI
import FirebaseAuth

struct Login: View {

    enum FocusFields {
        case username, password
    }

    @ObservedObject var userSettings = UserSettings()
    @FocusState private var focusedField: FocusFields?
    @State private var showActivityIndicator = false
    @State private var alertText = ""
    @State private var showAlert = false

    private func login() {
        showActivityIndicator = true

        Auth.auth().signIn(withEmail: userSettings.username.trimmingCharacters(in: .whitespacesAndNewlines), password: userSettings.password) { _, error in
            showActivityIndicator = false

            if let error {
                alertText = error.localizedDescription
                showAlert = true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 12)

                Text("Welkom!")
                    .font(.largeTitle)
                    .foregroundColor(Color("blackWhite"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 16)

                Image("menuImage")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .shadow(radius: 10)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)

                TextField("E-mail", text: $userSettings.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color("textField"))
                    .focused($focusedField, equals: .username)
                    .cornerRadius(15)

                SecureField("Wachtwoord", text: $userSettings.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color("textField"))
                    .focused($focusedField, equals: .password)
                    .cornerRadius(15)

                Button(action: login) {
                    if showActivityIndicator {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(showActivityIndicator || userSettings.username.isEmpty || userSettings.password.isEmpty)

                NavigationLink(destination: Register()) {
                    Text("Registeren")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 27.5)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("textField"), Color("LoginBackground")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
            )
            .alert("Error", isPresented: $showAlert) {
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
                if focusedField == .username {
                    focusedField = .password
                } else {
                    focusedField = nil
                    login()
                }
            }
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
