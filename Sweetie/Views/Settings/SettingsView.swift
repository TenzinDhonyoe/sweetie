import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(SupabaseService.self) private var supabase

    @State private var partnerProfile: Profile?
    @State private var editedDisplayName: String = ""
    @State private var reunionDate: Date = Date()
    @State private var showReunionPicker: Bool = false
    @State private var showSleepPicker: Bool = false
    @State private var sleepStart: Date = Date()
    @State private var sleepEnd: Date = Date()
    @State private var showSignOutAlert: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var codeCopied: Bool = false
    @State private var nameSaveTask: Task<Void, Never>?
    @State private var hasSetReunionDate: Bool = false
    @State private var isSavingReunion: Bool = false
    @State private var reunionSaveError: String?
    @State private var showMyTimezonePicker: Bool = false
    @State private var showPartnerTimezonePicker: Bool = false
    @State private var selectedMyTimezone: String = TimeZone.current.identifier
    @State private var selectedPartnerTimezone: String = ""
    @State private var timezoneSearch: String = ""

    @AppStorage("notif_taps") private var tapNotifications: Bool = true
    @AppStorage("notif_photos") private var photoNotifications: Bool = true
    @AppStorage("notif_notes") private var noteNotifications: Bool = true
    @AppStorage("notif_questions") private var questionReminder: Bool = true
    @AppStorage("notif_time_sensitive") private var timeSensitive: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    sectionWithHeader("PROFILE") { profileSection }
                    sectionWithHeader("COUPLE") { coupleSection }
                    sectionWithHeader("TIMEZONE") { timezoneSection }
                    sectionWithHeader("NOTIFICATIONS") { notificationsSection }
                    sectionWithHeader("ABOUT") { aboutSection }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 100)
            }
            .background(BackgroundGradient())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .onAppear {
            loadInitialData()
        }
        .onDisappear {
            saveAllPendingChanges()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                await handlePhotoSelection(newValue)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await supabase.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                HStack(spacing: Spacing.lg) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        avatarView
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Display Name")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSoft)

                        TextField("Your name", text: $editedDisplayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .textFieldStyle(.plain)
                            .onChange(of: editedDisplayName) { _, newValue in
                                debounceSaveName(newValue)
                            }
                    }

                    Spacer()
                }
                .padding(.vertical, Spacing.xs)

                Divider()
                    .padding(.leading, Spacing.lg)

                settingsRow(
                    label: "Partner",
                    value: partnerProfile?.displayName ?? "Not paired"
                )
            }
            .padding(.vertical, -Spacing.sm)
        }
    }

    private var avatarView: some View {
        Group {
            if let avatarUrl = supabase.profile?.avatarUrl,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.rose.opacity(0.3), lineWidth: 2)
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(6)
                .background(Color.rose)
                .clipShape(Circle())
                .offset(x: 4, y: 4)
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.roseLight
            Text(initials)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.rose)
        }
    }

    private var initials: String {
        let name = supabase.profile?.displayName ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    // MARK: - Couple Section

    private var coupleSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showReunionPicker.toggle()
                    }
                } label: {
                    HStack {
                        Text("Reunion Date")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.ink)

                        Spacer(minLength: Spacing.md)

                        Text(formattedReunionDate)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSoft)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkFaint)
                            .rotationEffect(.degrees(showReunionPicker ? 90 : 0))
                    }
                    .frame(minHeight: 44)
                }

                if showReunionPicker {
                    DatePicker(
                        "Select date",
                        selection: $reunionDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(.rose)

                    if let reunionSaveError {
                        Text(reunionSaveError)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.horizontal, Spacing.sm)
                    }

                    Button {
                        isSavingReunion = true
                        reunionSaveError = nil
                        Task {
                            do {
                                try await supabase.updateReunionDate(reunionDate)
                                hasSetReunionDate = true
                                withAnimation(.spring(duration: 0.3)) {
                                    showReunionPicker = false
                                }
                            } catch {
                                reunionSaveError = "Failed to save: \(error.localizedDescription)"
                            }
                            isSavingReunion = false
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isSavingReunion {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Save Date")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.rose)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSavingReunion)
                    .padding(.bottom, Spacing.sm)
                }

                Divider()
                    .padding(.leading, Spacing.lg)

                HStack {
                    Text("Invite Code")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.ink)
                        .layoutPriority(1)

                    Spacer(minLength: Spacing.md)

                    Text(supabase.couple?.inviteCode ?? "—")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Button {
                        if let code = supabase.couple?.inviteCode {
                            UIPasteboard.general.string = code
                            withAnimation {
                                codeCopied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    codeCopied = false
                                }
                            }
                        }
                    } label: {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundStyle(codeCopied ? Color.sage : Color.rose)
                    }
                }
                .frame(minHeight: 44)

                Divider()
                    .padding(.leading, Spacing.lg)

                settingsRow(
                    label: "Days Together",
                    value: "\(daysTogether)"
                )
            }
            .padding(.vertical, -Spacing.sm)
        }
    }

    private var formattedReunionDate: String {
        if hasSetReunionDate || supabase.couple?.reunionDate != nil {
            return DateFormatting.shortDate(reunionDate)
        }
        return "Not set"
    }

    private var daysTogether: Int {
        guard let createdAtString = supabase.couple?.createdAt,
              let createdAt = DateFormatting.parse(createdAtString) else {
            return 0
        }
        let components = Calendar.current.dateComponents([.day], from: createdAt, to: Date())
        return components.day ?? 0
    }

    // MARK: - Timezone Section

    private var timezoneSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                // Your timezone
                timezoneRow(
                    label: "Your Timezone",
                    value: friendlyTimezone(selectedMyTimezone),
                    isExpanded: showMyTimezonePicker
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        showMyTimezonePicker.toggle()
                        showPartnerTimezonePicker = false
                        timezoneSearch = ""
                    }
                }

                if showMyTimezonePicker {
                    timezonePickerContent { tz in
                        selectedMyTimezone = tz
                        withAnimation(.spring(duration: 0.3)) {
                            showMyTimezonePicker = false
                        }
                        Task {
                            try? await supabase.updateProfile(
                                displayName: supabase.profile?.displayName ?? "",
                                timezone: tz
                            )
                        }
                    }
                }

                Divider()
                    .padding(.leading, Spacing.lg)

                // Partner timezone
                timezoneRow(
                    label: "Their Timezone",
                    value: selectedPartnerTimezone.isEmpty ? "Not set" : friendlyTimezone(selectedPartnerTimezone),
                    isExpanded: showPartnerTimezonePicker
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        showPartnerTimezonePicker.toggle()
                        showMyTimezonePicker = false
                        timezoneSearch = ""
                    }
                }

                if showPartnerTimezonePicker {
                    timezonePickerContent { tz in
                        selectedPartnerTimezone = tz
                        withAnimation(.spring(duration: 0.3)) {
                            showPartnerTimezonePicker = false
                        }
                        UserDefaults.standard.set(tz, forKey: "partnerTimezoneOverride")
                    }
                }

                Divider()
                    .padding(.leading, Spacing.lg)

                // Sleep schedule
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showSleepPicker.toggle()
                    }
                } label: {
                    HStack {
                        Text("Sleep Schedule")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.ink)
                            .layoutPriority(1)

                        Spacer(minLength: Spacing.md)

                        Text(sleepScheduleText)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.inkFaint)
                            .rotationEffect(.degrees(showSleepPicker ? 90 : 0))
                    }
                    .frame(minHeight: 44)
                }

                if showSleepPicker {
                    VStack(spacing: Spacing.md) {
                        HStack {
                            Text("Sleep at")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSoft)
                            Spacer()
                            DatePicker("", selection: $sleepStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(.rose)
                        }

                        HStack {
                            Text("Wake at")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.inkSoft)
                            Spacer()
                            DatePicker("", selection: $sleepEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(.rose)
                        }
                    }
                    .padding(.bottom, Spacing.md)
                    .onChange(of: sleepStart) { _, _ in saveSleepSchedule() }
                    .onChange(of: sleepEnd) { _, _ in saveSleepSchedule() }
                }

                Divider()
                    .padding(.leading, Spacing.lg)

                settingsRow(
                    label: "Current Overlap",
                    value: overlapText
                )
            }
            .padding(.vertical, -Spacing.sm)
        }
    }

    private func timezoneRow(label: String, value: String, isExpanded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.ink)
                    .layoutPriority(1)

                Spacer(minLength: Spacing.md)

                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkFaint)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .frame(minHeight: 44)
        }
    }

    private func timezonePickerContent(onSelect: @escaping (String) -> Void) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.inkFaint)
                    .font(.system(size: 14))

                TextField("Search city or timezone", text: $timezoneSearch)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.ink)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredTimezones, id: \.self) { tz in
                        Button {
                            onSelect(tz)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friendlyTimezone(tz))
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.ink)

                                    Text(timezoneOffset(tz))
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.inkFaint)
                                }

                                Spacer()
                            }
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.xs)
                        }

                        if tz != filteredTimezones.last {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(.bottom, Spacing.sm)
    }

    private var filteredTimezones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        if timezoneSearch.isEmpty {
            // Show common ones first
            let common = [
                "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
                "America/Toronto", "Europe/London", "Europe/Paris", "Europe/Berlin",
                "Asia/Tokyo", "Asia/Shanghai", "Asia/Kolkata", "Asia/Seoul",
                "Australia/Sydney", "Pacific/Auckland"
            ]
            let rest = all.filter { !common.contains($0) }
            return common + rest
        }
        let query = timezoneSearch.lowercased()
        return all.filter {
            $0.lowercased().contains(query) || friendlyTimezone($0).lowercased().contains(query)
        }
    }

    private func friendlyTimezone(_ identifier: String) -> String {
        let city = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return city.replacingOccurrences(of: "_", with: " ")
    }

    private func timezoneOffset(_ identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        if minutes == 0 {
            return "GMT\(hours >= 0 ? "+" : "")\(hours)"
        }
        return "GMT\(hours >= 0 ? "+" : "")\(hours):\(String(format: "%02d", minutes))"
    }

    private var sleepScheduleText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: sleepStart)) – \(formatter.string(from: sleepEnd))"
    }

    private var overlapText: String {
        guard let partner = partnerProfile else {
            return "—"
        }

        let myTimezone = selectedMyTimezone
        let mySleep = (
            start: supabase.profile?.sleepStart ?? "23:00",
            end: supabase.profile?.sleepEnd ?? "07:00"
        )
        let theirTimezone = selectedPartnerTimezone.isEmpty ? myTimezone : selectedPartnerTimezone
        let theirSleep = (start: partner.sleepStart, end: partner.sleepEnd)

        return TimezoneHelper.overlapDescription(
            myTimezone: myTimezone,
            mySleep: mySleep,
            theirTimezone: theirTimezone,
            theirSleep: theirSleep
        )
    }

    private func saveSleepSchedule() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startString = formatter.string(from: sleepStart)
        let endString = formatter.string(from: sleepEnd)

        Task {
            try? await supabase.updateSleepSchedule(sleepStart: startString, sleepEnd: endString)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                toggleRow(label: "Tap Notifications", isOn: $tapNotifications)

                Divider()
                    .padding(.leading, Spacing.lg)

                toggleRow(label: "Photo Notifications", isOn: $photoNotifications)

                Divider()
                    .padding(.leading, Spacing.lg)

                toggleRow(label: "Love Note Notifications", isOn: $noteNotifications)

                Divider()
                    .padding(.leading, Spacing.lg)

                toggleRow(label: "Daily Question Reminder", isOn: $questionReminder)

                Divider()
                    .padding(.leading, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Toggle(isOn: $timeSensitive) {
                        Text("Time Sensitive")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.ink)
                    }
                    .tint(.rose)
                    .frame(minHeight: 44)

                    Text("Allows notifications during Focus mode")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSoft)
                }
            }
            .padding(.vertical, -Spacing.sm)
        }
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Color.ink)
        }
        .tint(.rose)
        .frame(minHeight: 44)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        GlassCard {
            VStack(spacing: 0) {
                settingsRow(label: "Version", value: "1.0.0")

                Divider()
                    .padding(.leading, Spacing.lg)

                settingsRow(label: "Made with", value: "❤️")

                Divider()
                    .padding(.leading, Spacing.lg)

                Button {
                    showSignOutAlert = true
                } label: {
                    HStack {
                        Text("Sign Out")
                            .font(.system(size: 17))
                            .foregroundStyle(.red)

                        Spacer()
                    }
                    .frame(minHeight: 44)
                }
            }
            .padding(.vertical, -Spacing.sm)
        }
    }

    // MARK: - Section Helper

    private func sectionWithHeader<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .sectionHeader()
                .padding(.leading, Spacing.xs)
            content()
        }
    }

    // MARK: - Helpers

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Color.ink)
                .layoutPriority(1)

            Spacer(minLength: Spacing.md)

            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minHeight: 44)
    }

    private func loadInitialData() {
        if let profile = supabase.profile {
            editedDisplayName = profile.displayName ?? ""
            sleepStart = parseTimeToDate(profile.sleepStart)
            sleepEnd = parseTimeToDate(profile.sleepEnd)
            selectedMyTimezone = profile.timezone ?? TimeZone.current.identifier
        }

        if let dateString = supabase.couple?.reunionDate,
           let date = DateFormatting.parse(dateString) {
            reunionDate = date
            hasSetReunionDate = true
        }

        // Load partner timezone: prefer local override, then partner profile
        let override = UserDefaults.standard.string(forKey: "partnerTimezoneOverride")
        selectedPartnerTimezone = override ?? ""

        syncTimezone()

        Task {
            partnerProfile = await supabase.fetchPartnerProfile()
            if selectedPartnerTimezone.isEmpty, let partnerTZ = partnerProfile?.timezone {
                selectedPartnerTimezone = partnerTZ
            }
        }
    }

    private func parseTimeToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        // PostgreSQL time columns return "HH:mm:ss", try that first
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: timeString) {
            return date
        }
        // Fallback for "HH:mm" format (what we write)
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }

        try? await supabase.updateAvatar(imageData: data)
    }

    private func debounceSaveName(_ name: String) {
        nameSaveTask?.cancel()
        nameSaveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            try? await supabase.updateDisplayName(name)
        }
    }

    private func saveAllPendingChanges() {
        nameSaveTask?.cancel()
        let name = editedDisplayName
        let currentTimezone = TimeZone.current.identifier
        Task {
            try? await supabase.updateProfile(displayName: name, timezone: currentTimezone)
        }
    }

    private func syncTimezone() {
        let currentTimezone = TimeZone.current.identifier
        if supabase.profile?.timezone != currentTimezone {
            Task {
                try? await supabase.updateProfile(
                    displayName: supabase.profile?.displayName ?? "",
                    timezone: currentTimezone
                )
            }
        }
    }
}
