import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VQTheme.paddingMd) {
                        // Avatar + Name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(VQTheme.primary.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(VQTheme.primary)
                            }

                            if let user = viewModel.user {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(VQTheme.textPrimary)

                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(VQTheme.textSecondary)
                            }
                        }
                        .padding(.top, VQTheme.paddingLg)

                        // Wallet Card
                        if let user = viewModel.user {
                            walletCard(user: user)
                        }

                        // Stats
                        if let user = viewModel.user {
                            statsCard(user: user)
                        }

                        // Transaction History
                        if !viewModel.transactions.isEmpty {
                            transactionsList
                        }

                        // Logout
                        VQButton(title: "Logout", icon: "arrow.right.square", style: .secondary) {
                            authViewModel.logout()
                        }
                        .padding(.top, VQTheme.paddingMd)
                    }
                    .padding(.horizontal, VQTheme.paddingLg)
                    .padding(.bottom, VQTheme.paddingXl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if let uid = authViewModel.currentUserId {
                    await viewModel.loadProfile(userId: uid)
                }
            }
            .refreshable {
                if let uid = authViewModel.currentUserId {
                    await viewModel.refresh(userId: uid)
                }
            }
        }
    }

    // MARK: - Wallet Card

    private func walletCard(user: VQUser) -> some View {
        VStack(spacing: 12) {
            Text("WALLET")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(VQTheme.textSecondary)
                .tracking(2)

            Text(user.balanceFormatted)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(VQTheme.success)

            Text("Available Balance")
                .font(.caption)
                .foregroundStyle(VQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VQTheme.paddingLg)
        .background(
            RoundedRectangle(cornerRadius: VQTheme.radiusLg)
                .fill(VQTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: VQTheme.radiusLg)
                        .stroke(
                            LinearGradient(
                                colors: [VQTheme.success.opacity(0.3), VQTheme.cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Stats Card

    private func statsCard(user: VQUser) -> some View {
        HStack(spacing: 0) {
            statItem(value: "\(user.questsCreated)", label: "Created", icon: "plus.circle.fill")

            Divider()
                .frame(height: 40)
                .background(VQTheme.surfaceLight)

            statItem(value: "\(user.questsCompleted)", label: "Completed", icon: "checkmark.circle.fill")
        }
        .padding(.vertical, VQTheme.paddingMd)
        .background(VQTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(VQTheme.primary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(VQTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(VQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundStyle(VQTheme.textPrimary)

            ForEach(viewModel.transactions) { tx in
                HStack(spacing: 12) {
                    Image(systemName: tx.type.icon)
                        .foregroundStyle(tx.type.isCredit ? VQTheme.success : VQTheme.error)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.type.label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(VQTheme.textPrimary)

                        Text(tx.description)
                            .font(.caption)
                            .foregroundStyle(VQTheme.textSecondary)
                    }

                    Spacer()

                    Text(tx.amountFormatted)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(tx.type.isCredit ? VQTheme.success : VQTheme.error)
                }
                .padding(12)
                .background(VQTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusSm))
            }
        }
    }
}
