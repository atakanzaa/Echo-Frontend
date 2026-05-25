import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @ObservedObject var viewModel: CommunityViewModel
    var prefillContent: String? = nil
    var prefillEmoji: String? = nil
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var content       = ""
    @State private var emoji:        String? = nil
    @State private var isAnonymous   = false
    @State private var isPosting     = false
    @State private var errorMessage: String? = nil
    @State private var selectedItem:  PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var imageData:     Data? = nil
    @State private var didApplyPrefill = false

    private let emojiOptions = ["😊", "😢", "😤", "😴", "🥰", "😎", "🤔", "💪"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background(colorScheme).ignoresSafeArea()

                KeyboardAwareFormScroll {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        imagePicker
                        captionField
                        emojiPicker
                        anonymousToggle
                        submitButton
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(locManager.t("common.cancel")) { dismiss() }
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                        .disabled(isPosting)
                }
                ToolbarItem(placement: .principal) {
                    Text(locManager.t("create_post.title"))
                        .font(AppTheme.Typography.heading3)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                }
            }
            .toolbarBackground(AppTheme.Colors.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(locManager.t("create_post.failed"), isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(locManager.t("common.ok")) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                guard !didApplyPrefill else { return }
                if let prefillContent, content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    content = prefillContent
                }
                if let prefillEmoji {
                    emoji = prefillEmoji
                }
                didApplyPrefill = true
            }
        }
    }

    // MARK: - Subviews

    private var imagePicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(AppTheme.Spacing.radiusMd)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.selectedItem = nil; self.selectedImage = nil; self.imageData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                                .padding(AppTheme.Spacing.sm)
                        }
                    }
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.Colors.accent)
                    Text(locManager.t("create_post.add_photo"))
                        .font(AppTheme.Typography.caption).fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(AppTheme.Colors.surface(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundColor(AppTheme.Colors.border(colorScheme))
                )
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImage = img; imageData = data
                }
            }
        }
    }

    private var captionField: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(selectedImage != nil ? locManager.t("create_post.caption_optional") : locManager.t("create_post.whats_on_mind"))
                .font(AppTheme.Typography.caption).fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            TextEditor(text: $content)
                .frame(minHeight: 100)
                .padding(AppTheme.Spacing.sm)
                .scrollContentBackground(.hidden)
                .background(AppTheme.Colors.surface(colorScheme))
                .cornerRadius(AppTheme.Spacing.radiusMd)
                .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                .font(AppTheme.Typography.body)
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(locManager.t("create_post.how_feeling"))
                .font(AppTheme.Typography.caption).fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: AppTheme.Layout.compactControlHeight), spacing: AppTheme.Spacing.sm)],
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(emojiOptions, id: \.self) { e in
                    Button(action: { emoji = emoji == e ? nil : e }) {
                        Text(e).font(.system(size: 24))
                            .frame(width: AppTheme.Layout.compactControlHeight, height: AppTheme.Layout.compactControlHeight)
                            .background(emoji == e ? AppTheme.Colors.accentSoft(colorScheme) : Color.clear)
                            .cornerRadius(AppTheme.Spacing.radiusSm)
                    }
                }
            }
        }
    }

    private var anonymousToggle: some View {
        Toggle(isOn: $isAnonymous) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "eye.slash")
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                Text(locManager.t("create_post.anonymous"))
                    .font(AppTheme.Typography.caption).fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
            }
        }
        .tint(AppTheme.Colors.accent)
        .padding(.horizontal, 4)
    }

    private var submitButton: some View {
        Button(action: submitPost) {
            HStack {
                if isPosting {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(locManager.t("create_post.share")).font(AppTheme.Typography.bodyEm)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSubmit ? AnyView(AppTheme.Gradients.accent) : AnyView(Color.gray.opacity(0.3)))
            .cornerRadius(AppTheme.Spacing.radiusMd)
        }
        .disabled(!canSubmit || isPosting)
    }

    // MARK: - Logic

    private var canSubmit: Bool {
        selectedImage != nil || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitPost() {
        guard !isPosting else { return }
        isPosting = true
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let capturedData = imageData
        let capturedName = capturedData != nil ? "post_\(UUID().uuidString).jpg" : nil
        Task {
            do {
                try await viewModel.createPost(
                    content:     trimmed.isEmpty ? nil : trimmed,
                    emoji:       emoji,
                    isAnonymous: isAnonymous,
                    imageData:   capturedData,
                    imageName:   capturedName
                )
                dismiss()
            } catch {
                isPosting    = false
                errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
}
