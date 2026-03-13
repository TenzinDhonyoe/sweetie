import SwiftUI

extension Animation {
    static let snappy = Animation.spring(duration: 0.3, bounce: 0.2)
    static let gentle = Animation.spring(duration: 0.5, bounce: 0.3)
    static let bouncy = Animation.spring(duration: 0.4, bounce: 0.4)
    static let slow = Animation.spring(duration: 0.8, bounce: 0.1)
}
