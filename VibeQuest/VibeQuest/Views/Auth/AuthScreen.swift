import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        ZStack {
            VQTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: VQTheme.paddingLg) {
                    Spacer(minLength: 60)

                    // Logo
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 60))
                            .foregroundStyle(VQTheme.primary)

                        Text("VibeQuest")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundStyle(VQTheme.textPrimary)

                        Text("Complete quests. Earn cash.")
                            .font(.subheadline)
                            .foregroundStyle(VQTheme.textSecondary)
                    }

                    Spacer(minLength: 40)

                    // Toggle
                    Picker("", selection: $isLogin) {
                        Text("Login").tag(true)
                        Text("Register").tag(false)
                    }
                    .pickerStyle(.segmented)

                    // Fields
                    VStack(spacing: 12) {
                        if !isLogin {
                            VQTextField(
                                placeholder: "Display Name",
                                text: $displayName,
                                icon: "person.fill"
                            )
                        }

                        VQTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill"
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                        VQTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                        .textContentType(isLogin ? .password : .newPassword)
                    }

                    // Error
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(VQTheme.error)
                            .multilineTextAlignment(.center)
                    }

                    // Submit
                    VQButton(
                        title: isLogin ? "Login" : "Create Account",
                        icon: isLogin ? "arrow.right" : "person.badge.plus",
                        isLoading: authViewModel.isLoading
                    ) {
                        Task {
                            if isLogin {
                                await authViewModel.login(email: email, password: password)
                            } else {
                                await authViewModel.register(
                                    email: email,
                                    password: password,
                                    displayName: displayName
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, VQTheme.paddingLg)
            }
        }
    }
}
