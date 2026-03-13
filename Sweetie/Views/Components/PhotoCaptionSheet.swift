import SwiftUI

struct PhotoCaptionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    var onSend: (String?) -> Void

    @State private var caption = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            // Photo preview — top 60%
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.xl)

            Spacer()

            // Caption + Send
            VStack(spacing: Spacing.lg) {
                TextField("Say something sweet...", text: $caption)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.ink)
                    .padding(Spacing.lg)
                    .sweetieGlass(cornerRadius: 14)

                Button {
                    isSending = true
                    let captionToSend = caption.isEmpty ? nil : caption
                    onSend(captionToSend)
                    dismiss()
                } label: {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send with ❤️")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSending)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(BackgroundGradient())
        .presentationDetents([.large])
    }
}
