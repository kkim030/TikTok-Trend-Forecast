import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo area
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.rbcBlue)

                        Text("RBC Direct Investing")
                            .font(.title.bold())
                            .foregroundColor(.rbcBlue)

                        Text("Online Investing Made Simple")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // Login form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        if let error = authVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button("Sign In") {
                            Task { await authVM.login(email: email, password: password) }
                        }
                        .buttonStyle(RBCButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)

                        Button("Create Account") {
                            showRegister = true
                        }
                        .buttonStyle(RBCButtonStyle(isPrimary: false))
                    }
                    .padding(.horizontal, 32)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("or").font(.caption).foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal, 32)

                    // Demo login
                    Button {
                        Task { await authVM.demoLogin() }
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Try Demo Account")
                        }
                        .font(.headline)
                        .foregroundColor(.rbcGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rbcDarkBlue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 32)

                    if authVM.isLoading {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Full Name", text: $fullName)
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password (min 8 chars)", text: $password)
                }

                if let error = authVM.errorMessage {
                    Section { Text(error).foregroundColor(.red) }
                }

                Section {
                    Button("Create Account") {
                        Task {
                            await authVM.register(email: email, password: password, fullName: fullName)
                            if authVM.isAuthenticated { dismiss() }
                        }
                    }
                    .disabled(fullName.isEmpty || email.isEmpty || password.count < 8)
                }
            }
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
