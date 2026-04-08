import SwiftUI
import PhotosUI

struct SubmitProofScreen: View {
    @StateObject private var viewModel: SubmissionViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?

    init(quest: Quest) {
        _viewModel = StateObject(wrappedValue: SubmissionViewModel(quest: quest))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VQTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VQTheme.paddingLg) {
                        // Quest info header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.quest.title)
                                    .font(.headline)
                                    .foregroundStyle(VQTheme.textPrimary)
                                RewardBadge(tier: viewModel.quest.tier)
                            }
                            Spacer()
                            Text(viewModel.quest.earnerRewardFormatted)
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundStyle(VQTheme.success)
                        }
                        .padding(VQTheme.paddingMd)
                        .background(VQTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))

                        // Media capture
                        VStack(spacing: 16) {
                            Text("Submit Proof")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(VQTheme.textPrimary)

                            if let imageData = viewModel.selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))

                                Button("Remove") {
                                    viewModel.selectedImageData = nil
                                }
                                .font(.caption)
                                .foregroundStyle(VQTheme.error)
                            } else {
                                // Capture buttons
                                HStack(spacing: 16) {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.title)
                                            Text("Gallery")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, VQTheme.paddingLg)
                                        .background(VQTheme.surface)
                                        .foregroundStyle(VQTheme.cyan)
                                        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                                                .stroke(VQTheme.surfaceLight, lineWidth: 1)
                                        )
                                    }

                                    Button {
                                        showCamera = true
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.title)
                                            Text("Camera")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, VQTheme.paddingLg)
                                        .background(VQTheme.surface)
                                        .foregroundStyle(VQTheme.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                                                .stroke(VQTheme.surfaceLight, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note (optional)")
                                .font(.caption)
                                .foregroundStyle(VQTheme.textSecondary)

                            TextEditor(text: $viewModel.note)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(VQTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
                                .overlay(
                                    RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                                        .stroke(VQTheme.surfaceLight, lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(VQTheme.error)
                        }

                        // Submit button
                        VQButton(
                            title: "Submit Proof",
                            icon: "paperplane.fill",
                            isLoading: viewModel.isUploading
                        ) {
                            Task {
                                if let uid = authViewModel.currentUserId {
                                    await viewModel.submit(earnerId: uid)
                                }
                            }
                        }
                        .disabled(!viewModel.hasMedia)
                        .opacity(viewModel.hasMedia ? 1 : 0.5)
                    }
                    .padding(VQTheme.paddingLg)
                }
            }
            .navigationTitle("Submit Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(VQTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(VQTheme.textSecondary)
                }
            }
            .onChange(of: selectedItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        viewModel.selectedImageData = data
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { imageData in
                    viewModel.selectedImageData = imageData
                }
            }
            .alert("Proof Submitted!", isPresented: $viewModel.isCompleted) {
                Button("OK") { dismiss() }
            } message: {
                Text("The requester will review your submission.")
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (Data) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
