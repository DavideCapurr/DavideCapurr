import SwiftUI

struct QuestDetailSheet: View {
    @StateObject private var viewModel: QuestDetailViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSubmission = false

    init(quest: Quest) {
        _viewModel = StateObject(wrappedValue: QuestDetailViewModel(quest: quest))
    }

    private var isRequester: Bool {
        viewModel.quest.requesterId == authViewModel.currentUserId
    }

    private var isEarner: Bool {
        viewModel.quest.earnerId == authViewModel.currentUserId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: VQTheme.paddingMd) {
                        // Header
                        HStack {
                            RewardBadge(tier: viewModel.quest.tier)
                            StatusChip(status: viewModel.quest.status)
                            Spacer()
                        }

                        Text(viewModel.quest.title)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundStyle(VQTheme.textPrimary)

                        if !viewModel.quest.description.isEmpty {
                            Text(viewModel.quest.description)
                                .font(.body)
                                .foregroundStyle(VQTheme.textSecondary)
                        }

                        Divider().background(VQTheme.surfaceLight)

                        // Details grid
                        VStack(spacing: 12) {
                            DetailRow(icon: quest.taskType.icon, label: "Task Type", value: quest.taskType.label)
                            DetailRow(icon: "eurosign.circle.fill", label: "You Earn", value: quest.earnerRewardFormatted)
                            DetailRow(icon: "clock.fill", label: "Expires", value: expiryText)
                        }
                        .padding(VQTheme.paddingMd)
                        .background(VQTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(VQTheme.error)
                        }

                        Spacer(minLength: 20)

                        // Actions
                        actionButtons
                    }
                    .padding(VQTheme.paddingLg)
                }
            }
            .navigationTitle("Quest Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(VQTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showSubmission) {
                SubmitProofScreen(quest: viewModel.quest)
                    .environmentObject(authViewModel)
            }
            .task {
                await viewModel.loadSubmission()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var quest: Quest { viewModel.quest }

    private var expiryText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: quest.expiresAt, relativeTo: Date())
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch quest.status {
        case .open:
            if !isRequester {
                VQButton(title: "Accept Quest", icon: "bolt.fill", isLoading: viewModel.isLoading) {
                    Task {
                        if let uid = authViewModel.currentUserId {
                            await viewModel.acceptQuest(earnerId: uid)
                        }
                    }
                }
            }

        case .accepted:
            if isEarner {
                VQButton(title: "Submit Proof", icon: "camera.fill") {
                    showSubmission = true
                }
            } else if isRequester {
                Text("Waiting for earner to submit proof...")
                    .font(.subheadline)
                    .foregroundStyle(VQTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }

        case .submitted:
            if isRequester {
                if let submission = viewModel.submission {
                    SubmissionPreview(submission: submission)

                    HStack(spacing: 12) {
                        VQButton(title: "Reject", icon: "xmark", style: .destructive, isLoading: viewModel.isLoading) {
                            Task { await viewModel.rejectSubmission() }
                        }

                        VQButton(title: "Approve", icon: "checkmark", isLoading: viewModel.isLoading) {
                            Task { await viewModel.approveSubmission() }
                        }
                    }
                }
            } else if isEarner {
                Text("Waiting for requester to review...")
                    .font(.subheadline)
                    .foregroundStyle(VQTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }

        case .completed:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(VQTheme.success)
                Text("Quest Completed!")
                    .fontWeight(.bold)
                    .foregroundStyle(VQTheme.success)
            }
            .frame(maxWidth: .infinity)

        default:
            EmptyView()
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(VQTheme.primary)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(VQTheme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(VQTheme.textPrimary)
        }
        .font(.subheadline)
    }
}

// MARK: - Submission Preview

struct SubmissionPreview: View {
    let submission: Submission

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Submission")
                .font(.headline)
                .foregroundStyle(VQTheme.textPrimary)

            AsyncImage(url: URL(string: submission.mediaUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
                case .failure:
                    placeholderView(icon: "photo.fill")
                default:
                    placeholderView(icon: "arrow.clockwise")
                }
            }

            if let note = submission.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(VQTheme.textSecondary)
                    .padding(12)
                    .background(VQTheme.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusSm))
            }
        }
        .padding(VQTheme.paddingMd)
        .background(VQTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
    }

    private func placeholderView(icon: String) -> some View {
        RoundedRectangle(cornerRadius: VQTheme.radiusMd)
            .fill(VQTheme.surfaceLight)
            .frame(height: 150)
            .overlay(
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(VQTheme.textSecondary)
            )
    }
}
