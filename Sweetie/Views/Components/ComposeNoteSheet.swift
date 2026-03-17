import SwiftUI

struct ComposeNoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onSend: (_ content: String) -> Void

    @State private var content = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    TextEditor(text: $content)
                        .font(.romantic)
                        .foregroundStyle(Color.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                        .padding(Spacing.lg)
                        .sweetieGlass(cornerRadius: 16)

                    Button {
                        isSending = true
                        onSend(content)
                        dismiss()
                    } label: {
                        Text("Send now")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
            }
            .background(BackgroundGradient(style: .notes))
            .navigationTitle("Love Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.inkSoft)
                }
            }
        }
        .presentationDetents([.large])
    }
}
