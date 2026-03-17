import AppIntents
import WidgetKit

struct SendTapIntent: AppIntent {
    static let title: LocalizedStringResource = "Send a Tap"
    static let description = IntentDescription("Send a love tap to your partner")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = await WidgetAPIClient.sendTap(emoji: "💕")

        switch result {
        case .success:
            return .result(value: "Sent 💕")
        case .noCredentials:
            return .result(value: "Open Sweetie to connect")
        case .tokenExpired:
            return .result(value: "Open Sweetie to reconnect")
        case .networkError:
            return .result(value: "No connection")
        case .serverError:
            return .result(value: "Try again later")
        }
    }
}
