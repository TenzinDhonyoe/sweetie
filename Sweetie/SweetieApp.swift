import SwiftUI
import UserNotifications

@main
struct SweetieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var supabase = SupabaseService()
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasOnboarded {
                    WelcomeView()
                } else {
                    switch supabase.authState {
                    case .loading:
                        ZStack {
                            BackgroundGradient(style: .heart)
                            MascotView(pose: .default, size: 120, animation: .bounce)
                        }
                    case .unauthenticated:
                        ZStack {
                            BackgroundGradient(style: .heart)
                            MascotView(pose: .default, size: 120, animation: .bounce)
                        }
                        .task {
                            await supabase.signInAnonymously()
                        }
                    case .unpaired:
                        if supabase.isWaitingForPartner {
                            MainTabView(selectedTab: $selectedTab)
                        } else {
                            PairingView()
                        }
                    case .paired:
                        if supabase.hasCompletedOnboarding {
                            MainTabView(selectedTab: $selectedTab)
                        } else {
                            OnboardingView()
                        }
                    }
                }
            }
            .environment(supabase)
            .task {
                appDelegate.supabaseService = supabase
                await setupNotifications()
            }
            .onChange(of: supabase.authState) {
                if supabase.authState == .paired {
                    supabase.syncWidgetData()
                    Task {
                        await supabase.syncWidgetDataFull()
                    }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "sweetie" else { return }
        switch url.host {
        case "heart":
            selectedTab = 1
        case "settings":
            selectedTab = 2
        default:
            selectedTab = 0
        }
    }

    private func setupNotifications() async {
        NotificationService.shared.setupNotificationCategories()
        _ = await NotificationService.shared.requestAuthorization()
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    var supabaseService: SupabaseService?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = NotificationService.shared.handleDeviceToken(deviceToken)
        Task { @MainActor in
            try? await supabaseService?.updatePushToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        switch categoryIdentifier {
        case "TAP", "PHOTO", "NOTE", "QUESTION":
            break
        default:
            break
        }
    }
}
