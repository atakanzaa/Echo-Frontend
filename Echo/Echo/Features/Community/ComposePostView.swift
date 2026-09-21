import PhotosUI
import SwiftUI

struct ComposePostView: View {
    let onCreated: (CommunityPost) -> Void
    @Environment(AppRouter.self) private var router
    @State private var model: ComposePostViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    init(prefilledText: String?, community: any CommunityServicing, user: any UserServicing,
         onCreated: @escaping (CommunityPost) -> Void) {
        self.onCreated = onCreated
        _model = State(initialValue: ComposePostViewModel(prefilledText: prefilledText, community: community, user: user))
    }

    var body: some View {
        VStack(spacing: AppTheme.space.sm) {
            if let error = model.error {
                EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error), action: {
                    if model.isLocked, !model.requiresTerms {
                        EchoButton("common.retry", variant: .ghost, size: .sm) { Task { await submit() } }
                    }
                })
            }
            if model.requiresTerms {
                EchoBanner(kind: .warning, title: String(localized: "community.termsRequired"),
                           message: String(localized: "community.termsRequiredMessage"), action: {
                    EchoButton("community.acceptTerms", variant: .secondary, size: .sm, isLoading: model.isWorking) {
                        Task {
                            if let post = await model.acceptCommunityTerms() { onCreated(post) }
                        }
                    }
                })
            }
            EchoTextEditor(placeholder: "community.composePlaceholder", text: $model.content,
                           characterLimit: 1_000, minHeight: 180, usesEntryTypography: true)
                .disabled(model.isLocked)
            Toggle("community.anonymous", isOn: $model.isAnonymous)
                .tint(AppTheme.color.accent.primary)
                .disabled(model.isLocked)
            if let data = model.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.md, style: .continuous))
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("community.addImage", systemImage: "photo")
                    .echoTextStyle(.subhead)
                    .foregroundStyle(AppTheme.color.content.accent)
            }
            .disabled(model.isLocked)
            EchoButton("community.publish", size: .lg, fullWidth: true, isLoading: model.isWorking) {
                Task { await submit() }
            }
            .disabled(!model.canSubmit && !model.isLocked)
            Spacer(minLength: 0)
        }
        .padding(AppTheme.layout.screenHorizontalPadding)
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("community.composeTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("common.cancel") { router.dismissSheet() }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task { model.setImageData(try? await item?.loadTransferable(type: Data.self)) }
        }
        .alert("community.sensitiveTitle", isPresented: Binding(
            get: { model.needsSensitiveConfirmation },
            set: { if !$0 { model.dismissSensitiveWarning() } }
        )) {
            Button("common.cancel", role: .cancel) { model.dismissSensitiveWarning() }
            Button("community.publishAnyway") { Task { await submit(sensitiveContentConfirmed: true) } }
        } message: {
            Text("community.sensitiveMessage")
        }
    }

    private func submit(sensitiveContentConfirmed: Bool = false) async {
        if let post = await model.submit(sensitiveContentConfirmed: sensitiveContentConfirmed) { onCreated(post) }
    }
}
