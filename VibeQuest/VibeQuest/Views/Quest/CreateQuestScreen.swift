import SwiftUI
import MapKit

struct CreateQuestScreen: View {
    @StateObject private var viewModel = CreateQuestViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.totalSteps))
                        .tint(VQTheme.primary)
                        .padding(.horizontal, VQTheme.paddingLg)
                        .padding(.top, 8)

                    // Step content
                    TabView(selection: $viewModel.currentStep) {
                        pinDropStep.tag(0)
                        taskTypeStep.tag(1)
                        rewardTierStep.tag(2)
                        detailsStep.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if viewModel.currentStep > 0 {
                            VQButton(title: "Back", icon: "chevron.left", style: .secondary) {
                                viewModel.previousStep()
                            }
                        }

                        if viewModel.currentStep < viewModel.totalSteps - 1 {
                            VQButton(title: "Next", icon: "chevron.right") {
                                viewModel.nextStep()
                            }
                            .disabled(!viewModel.canProceed)
                            .opacity(viewModel.canProceed ? 1 : 0.5)
                        } else {
                            VQButton(
                                title: "Create Quest \(FormatUtils.centsToEuro(viewModel.tier.totalReward))",
                                icon: "bolt.fill",
                                isLoading: viewModel.isSubmitting
                            ) {
                                Task {
                                    if let uid = authViewModel.currentUserId {
                                        await viewModel.createQuest(requesterId: uid)
                                    }
                                }
                            }
                            .disabled(!viewModel.canProceed)
                            .opacity(viewModel.canProceed ? 1 : 0.5)
                        }
                    }
                    .padding(.horizontal, VQTheme.paddingLg)
                    .padding(.bottom, VQTheme.paddingMd)
                }
            }
            .navigationTitle("New Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Quest Created!", isPresented: $viewModel.isCompleted) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your quest is now live on the map!")
            }
        }
    }

    // MARK: - Step 0: Pin Drop

    private var pinDropStep: some View {
        VStack(spacing: VQTheme.paddingMd) {
            Text("Drop a Pin")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(VQTheme.textPrimary)

            Text("Tap the map to set the quest location")
                .font(.subheadline)
                .foregroundStyle(VQTheme.textSecondary)

            Map(coordinateRegion: $viewModel.pinRegion, annotationItems: pinAnnotation) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(VQTheme.primary)

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.caption2)
                            .foregroundStyle(VQTheme.primary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusLg))
            .frame(maxHeight: .infinity)
            .onTapGesture { location in
                // Use center of map as pin location for simplicity
                viewModel.pinCoordinate = viewModel.pinRegion.center
            }

            Button("Use Map Center") {
                viewModel.pinCoordinate = viewModel.pinRegion.center
            }
            .font(.subheadline)
            .foregroundStyle(VQTheme.cyan)
        }
        .padding(VQTheme.paddingLg)
    }

    private var pinAnnotation: [PinLocation] {
        if let coord = viewModel.pinCoordinate {
            return [PinLocation(coordinate: coord)]
        }
        return []
    }

    // MARK: - Step 1: Task Type

    private var taskTypeStep: some View {
        VStack(spacing: VQTheme.paddingLg) {
            Text("Task Type")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(VQTheme.textPrimary)

            Text("What should the earner do?")
                .font(.subheadline)
                .foregroundStyle(VQTheme.textSecondary)

            VStack(spacing: 12) {
                ForEach(TaskType.allCases, id: \.self) { type in
                    TaskTypeButton(
                        type: type,
                        isSelected: viewModel.taskType == type
                    ) {
                        viewModel.taskType = type
                    }
                }
            }

            Spacer()
        }
        .padding(VQTheme.paddingLg)
    }

    // MARK: - Step 2: Reward Tier

    private var rewardTierStep: some View {
        VStack(spacing: VQTheme.paddingLg) {
            Text("Reward Tier")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(VQTheme.textPrimary)

            Text("How much will this quest pay?")
                .font(.subheadline)
                .foregroundStyle(VQTheme.textSecondary)

            HStack(spacing: 16) {
                ForEach(QuestTier.allCases, id: \.self) { tier in
                    TierCard(
                        tier: tier,
                        isSelected: viewModel.tier == tier
                    ) {
                        viewModel.tier = tier
                    }
                }
            }

            Spacer()
        }
        .padding(VQTheme.paddingLg)
    }

    // MARK: - Step 3: Details

    private var detailsStep: some View {
        VStack(spacing: VQTheme.paddingMd) {
            Text("Quest Details")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(VQTheme.textPrimary)

            VQTextField(
                placeholder: "Quest Title",
                text: $viewModel.title,
                icon: "pencil"
            )

            VStack(alignment: .leading) {
                Text("Description (optional)")
                    .font(.caption)
                    .foregroundStyle(VQTheme.textSecondary)

                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(VQTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                            .stroke(VQTheme.surfaceLight, lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
            }

            // Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Total Cost")
                        .foregroundStyle(VQTheme.textSecondary)
                    Spacer()
                    Text(FormatUtils.centsToEuro(viewModel.tier.totalReward))
                        .fontWeight(.bold)
                        .foregroundStyle(VQTheme.textPrimary)
                }
                HStack {
                    Text("Earner Gets")
                        .foregroundStyle(VQTheme.textSecondary)
                    Spacer()
                    Text(FormatUtils.centsToEuro(viewModel.tier.earnerReward))
                        .fontWeight(.bold)
                        .foregroundStyle(VQTheme.success)
                }
                HStack {
                    Text("Platform Fee")
                        .foregroundStyle(VQTheme.textSecondary)
                    Spacer()
                    Text(FormatUtils.centsToEuro(viewModel.tier.platformFee))
                        .fontWeight(.bold)
                        .foregroundStyle(VQTheme.textSecondary)
                }
            }
            .font(.subheadline)
            .padding(VQTheme.paddingMd)
            .background(VQTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(VQTheme.error)
            }

            Spacer()
        }
        .padding(VQTheme.paddingLg)
    }
}

// MARK: - Supporting Views

struct PinLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct TaskTypeButton: View {
    let type: TaskType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? VQTheme.primary : VQTheme.textSecondary)
                    .frame(width: 40)

                VStack(alignment: .leading) {
                    Text(type.label)
                        .font(.headline)
                        .foregroundStyle(VQTheme.textPrimary)

                    Text(taskDescription(for: type))
                        .font(.caption)
                        .foregroundStyle(VQTheme.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(VQTheme.primary)
                }
            }
            .padding(VQTheme.paddingMd)
            .background(isSelected ? VQTheme.primary.opacity(0.1) : VQTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                    .stroke(isSelected ? VQTheme.primary : VQTheme.surfaceLight, lineWidth: 1.5)
            )
        }
    }

    private func taskDescription(for type: TaskType) -> String {
        switch type {
        case .photo: return "Take a photo as proof"
        case .video: return "Record a video (max 15s)"
        case .action: return "Perform a physical action"
        }
    }
}

struct TierCard: View {
    let tier: QuestTier
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(tier.emoji)
                    .font(.system(size: 40))

                Text(tier.label)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(VQTheme.textPrimary)

                Text(FormatUtils.centsToEuro(tier.totalReward))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundStyle(tierColor)

                Text("Earner gets \(FormatUtils.centsToEuro(tier.earnerReward))")
                    .font(.caption)
                    .foregroundStyle(VQTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, VQTheme.paddingLg)
            .background(isSelected ? tierColor.opacity(0.1) : VQTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: VQTheme.radiusLg)
                    .stroke(isSelected ? tierColor : VQTheme.surfaceLight, lineWidth: 2)
            )
        }
    }

    private var tierColor: Color {
        tier == .micro ? VQTheme.microColor : VQTheme.macroColor
    }
}
