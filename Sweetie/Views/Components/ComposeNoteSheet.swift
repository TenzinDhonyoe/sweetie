import SwiftUI

struct ComposeNoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let category: NoteCategory
    var onSend: (_ content: String, _ openWhenLabel: String?, _ deliverAt: Date?) -> Void

    @State private var content = ""
    @State private var openWhenLabel = ""
    @State private var deliveryOption: DeliveryOption = .morning
    @State private var customDeliveryDate = Date()
    @State private var isSending = false

    enum DeliveryOption: String, CaseIterable {
        case morning = "Their morning (7:30 AM)"
        case evening = "Their evening (8:00 PM)"
        case custom = "Custom time"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if category == .openWhen {
                        openWhenFields
                    }

                    TextEditor(text: $content)
                        .font(.romantic)
                        .foregroundStyle(Color.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                        .padding(Spacing.lg)
                        .sweetieGlass(cornerRadius: 16)

                    Button {
                        isSending = true
                        let label = category == .openWhen ? openWhenLabel : nil
                        let deliverAt = category == .openWhen ? computeDeliveryDate() : nil
                        onSend(content, label, deliverAt)
                        dismiss()
                    } label: {
                        Text(category == .instant ? "Send now 💌" : "Schedule letter 💌")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
            }
            .background(BackgroundGradient(style: .notes))
            .navigationTitle(category == .instant ? "Love Note" : "Open When")
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

    private var openWhenFields: some View {
        VStack(spacing: Spacing.md) {
            TextField("Open when...", text: $openWhenLabel)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.ink)
                .padding(Spacing.lg)
                .sweetieGlass(cornerRadius: 14)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Deliver at")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkFaint)

                ForEach(DeliveryOption.allCases, id: \.self) { option in
                    Button {
                        deliveryOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(.system(size: 15))
                                .foregroundStyle(deliveryOption == option ? Color.rose : Color.inkSoft)
                            Spacer()
                            if deliveryOption == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.rose)
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)
                }

                if deliveryOption == .custom {
                    DatePicker("", selection: $customDeliveryDate, in: Date()...)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            .padding(Spacing.lg)
            .sweetieGlass(cornerRadius: 14)
        }
    }

    private func computeDeliveryDate() -> Date {
        switch deliveryOption {
        case .morning:
            return nextTimeInPartnerTZ(hour: 7, minute: 30)
        case .evening:
            return nextTimeInPartnerTZ(hour: 20, minute: 0)
        case .custom:
            return customDeliveryDate
        }
    }

    private func nextTimeInPartnerTZ(hour: Int, minute: Int) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var date = calendar.date(from: components) else { return Date() }
        if date <= Date() {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }
}
