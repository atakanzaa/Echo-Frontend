//
//  CreatePostView.swift
//  Echo

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var content      = ""
    @State private var emoji:       String? = nil
    @State private var isAnonymous  = false
    @State private var isPosting    = false
    @State private var errorMessage: String? = nil

    @State private var selectedItem:  PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var imageData:     Data? = nil

    private let emojiOptions = ["😊", "😢", "😤", "😴", "🥰", "😎", "🤔", "💪"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.063, green: 0.098, blue: 0.133)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Image Picker
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 220)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            self.selectedItem  = nil
                                            self.selectedImage = nil
                                            self.imageData     = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .shadow(radius: 4)
                                                .padding(8)
                                        }
                                    }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    Text("Add a Photo")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color(red: 0.118, green: 0.161, blue: 0.231))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                        .foregroundColor(Color.white.opacity(0.15))
                                )
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    selectedImage = img
                                    imageData = data
                                }
                            }
                        }

                        // Caption
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedImage != nil ? "Caption (optional)" : "What's on your mind?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                            TextEditor(text: $content)
                                .frame(minHeight: 100)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(Color(red: 0.118, green: 0.161, blue: 0.231))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }

                        // Emoji
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How are you feeling?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                            HStack(spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { e in
                                    Button(action: { emoji = emoji == e ? nil : e }) {
                                        Text(e).font(.system(size: 24))
                                            .padding(6)
                                            .background(emoji == e
                                                ? Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3)
                                                : Color.clear)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        // Anonymous Toggle
                        Toggle(isOn: $isAnonymous) {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.slash")
                                    .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                                Text("Post Anonymously")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .tint(Color(red: 0.498, green: 0.075, blue: 0.929))
                        .padding(.horizontal, 4)

                        // Submit Button
                        Button(action: submitPost) {
                            HStack {
                                if isPosting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Share with Community")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit
                                ? Color(red: 0.498, green: 0.075, blue: 0.929)
                                : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!canSubmit || isPosting)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                        .disabled(isPosting)
                }
                ToolbarItem(placement: .principal) {
                    Text("New Post")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 0.063, green: 0.098, blue: 0.133), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Post Oluşturulamadı", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var canSubmit: Bool {
        // Image seçilmişse (preview gösteriliyor) → gönderebilir (caption opsiyonel)
        // Image yoksa → text zorunlu
        selectedImage != nil || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitPost() {
        guard !isPosting else { return }
        isPosting = true

        let trimmed    = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // imageData yüklenmediyse bile selectedImage varsa bekle
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
                // Başarılı → sheet'i kapat
                dismiss()
            } catch {
                // Hata → kullanıcıya göster, sheet'te kal
                isPosting    = false
                errorMessage = (error as? NetworkError)?.localizedDescription
                    ?? error.localizedDescription
            }
        }
    }
}
