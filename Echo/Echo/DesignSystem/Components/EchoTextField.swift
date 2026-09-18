import SwiftUI

/// Tek satırlık metin alanı (implementation.md §4.6). Hata metni sunucudan gelen `detail` olabilir.
struct EchoTextField: View {
    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey
    @Binding private var text: String
    private let isSecure: Bool
    private let errorText: String?
    private let contentType: UITextContentType?
    private let keyboardType: UIKeyboardType
    private let submitLabel: SubmitLabel
    @FocusState private var isFocused: Bool

    init(_ title: LocalizedStringKey,
         placeholder: LocalizedStringKey = "",
         text: Binding<String>,
         isSecure: Bool = false,
         errorText: String? = nil,
         contentType: UITextContentType? = nil,
         keyboardType: UIKeyboardType = .default,
         submitLabel: SubmitLabel = .return) {
        self.title = title
        self.placeholder = placeholder
        _text = text
        self.isSecure = isSecure
        self.errorText = errorText
        self.contentType = contentType
        self.keyboardType = keyboardType
        self.submitLabel = submitLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
            Text(title)
                .echoTextStyle(.subhead)
                .foregroundStyle(AppTheme.color.content.secondary)
            field
                .echoTextStyle(.body)
                .foregroundStyle(AppTheme.color.content.primary)
                .textInputAutocapitalization(contentType == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(contentType == .emailAddress || isSecure)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .submitLabel(submitLabel)
                .focused($isFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: AppTheme.layout.minTouchTarget)
                .background(RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous)
                    .fill(isFocused ? AppTheme.color.bg.surface : AppTheme.color.bg.surfaceSunken))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                }
                .animation(.easeInOut(duration: AppTheme.motion.duration.fast), value: isFocused)
            if let errorText {

                Text(errorText)
                    .echoTextStyle(.footnote)
                    .foregroundStyle(AppTheme.color.feedback.danger)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }

    @ViewBuilder private var field: some View {
        if isSecure {

            SecureField(placeholder, text: $text)
        } else {
            TextField(placeholder, text: $text)
        }
    }

    private var borderColor: Color {
        if errorText != nil { return AppTheme.color.feedback.danger }
        return isFocused ? AppTheme.color.border.accent : .clear
    }

    private var borderWidth: CGFloat {
        errorText != nil || isFocused ? 2 : 0
    }
}

/// Çok satırlı alan (§4.6). `characterLimit` sunucudan gelen sınırdır; uygulamada sabit yazılmaz.
struct EchoTextEditor: View {
    private let placeholder: LocalizedStringKey
    @Binding private var text: String
    private let characterLimit: Int?
    private let minHeight: CGFloat
    private let usesEntryTypography: Bool
    @FocusState private var isFocused: Bool

    init(placeholder: LocalizedStringKey = "",
         text: Binding<String>,
         characterLimit: Int? = nil,
         minHeight: CGFloat = 120,
         usesEntryTypography: Bool = false) {
        self.placeholder = placeholder
        _text = text
        self.characterLimit = characterLimit
        self.minHeight = minHeight
        self.usesEntryTypography = usesEntryTypography
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: AppTheme.space.xxxs) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {

                    Text(placeholder)
                        .echoTextStyle(usesEntryTypography ? .entry : .body)
                        .foregroundStyle(AppTheme.color.content.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .echoTextStyle(usesEntryTypography ? .entry : .body)
                    .foregroundStyle(AppTheme.color.content.primary)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: minHeight, alignment: .topLeading)
            }
            .background(RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous)
                .fill(isFocused ? AppTheme.color.bg.surface : AppTheme.color.bg.surfaceSunken))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.radius.sm, style: .continuous)
                    .strokeBorder(isFocused ? AppTheme.color.border.accent : .clear, lineWidth: 2)
            }
            .animation(.easeInOut(duration: AppTheme.motion.duration.fast), value: isFocused)
            if let characterLimit {

                Text(verbatim: "\(text.count)/\(characterLimit)")
                    .echoTextStyle(.caption2)
                    .foregroundStyle(text.count > characterLimit ? AppTheme.color.feedback.danger : AppTheme.color.content.tertiary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview("Metin alanları") {
    @Previewable @State var email = ""
    @Previewable @State var password = "hatali"
    @Previewable @State var note = ""

    return VStack(spacing: AppTheme.space.sm) {
        EchoTextField("E-posta", placeholder: "ornek@echo.app", text: $email, contentType: .emailAddress, keyboardType: .emailAddress)
        EchoTextField("Şifre", text: $password, isSecure: true, errorText: "Şifre en az 8 karakter olmalı.", contentType: .password)
        EchoTextEditor(placeholder: "Bugün ne düşündün?", text: $note, characterLimit: 10_000, usesEntryTypography: true)
    }
    .padding()
    .background(AppTheme.color.bg.canvas)
}
