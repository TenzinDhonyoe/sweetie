import WidgetKit
import SwiftUI

@main
struct SweetieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        LatestPhotoWidget()
        LastTapWidget()
        InteractiveTapWidget()
        TodayQuestionWidget()
        LockScreenCountdownWidget()
        PartnerTimeWidget()
    }
}
