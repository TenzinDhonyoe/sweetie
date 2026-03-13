# DESIGN.md — Sweetie (SwiftUI Native)

> Single source of truth for all visual and interaction design.
> Every view, modifier, and animation MUST reference this file.
> Minimum target: iOS 18. Use .glassEffect() on iOS 26+ with fallback to .ultraThinMaterial on iOS 18-25.

---

## 0. Design Philosophy

Sweetie is a native iOS 26 app. Not "inspired by" iOS — it IS iOS. Liquid Glass is not a style we're replicating; it's the system material we're building with. SwiftUI gives us `.glassEffect()`, native NavigationStack, native TabView, native haptics, and native spring animations — use them all.

The romance comes from the content, the mascot, the typography pairing, and the moments of delight. The chrome should be invisible. When she opens this app, she should feel like Apple built it for couples.

**Three mantras:**
1. **Native above all** — If SwiftUI has a built-in component for it, use it. Don't custom-build what the system provides
2. **Content is the interface** — Her photo IS the app. The countdown IS the screen. Chrome vanishes behind what matters
3. **One delightful moment per screen** — One animation, one haptic, one thing that makes her smile. Not ten

**What this app is NOT:**
- Not a "pink app" — color comes from content refracting through system glass
- Not a design exercise — it's functional, fast, and feels like home
- Not overbuilt — 10 days of use, not 10 years of features

---

## 1. Glass Materials (iOS 18+ with iOS 26 enhancement)

The app targets iOS 18 minimum. Use SwiftUI's built-in materials with an iOS 26 upgrade path.

```swift
// REUSABLE MODIFIER — use this everywhere instead of raw .glassEffect()
struct SweetieGlass: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .glassEffect()
            )
        } else {
            content.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.ink.opacity(0.06), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            )
        }
    }
}

extension View {
    func sweetieGlass(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(SweetieGlass(cornerRadius: cornerRadius))
    }
}

// Usage — same everywhere:
VStack { ... }
    .padding(16)
    .sweetieGlass()
```

**How materials work on iOS 18-25:**
- `.ultraThinMaterial` — lightest blur, most transparent. Use for nav bar, tab bar overlays
- `.thinMaterial` — slightly more opaque. Use for floating cards
- `.regularMaterial` — standard frosted glass. Use for prominent glass cards
- All materials automatically adapt to the content behind them
- Add a subtle white stroke (0.5pt, 25% opacity) for the glass edge highlight
- Add warm shadow: `.shadow(color: Color.ink.opacity(0.06), radius: 8, y: 2)`

**On iOS 26 devices:** `.glassEffect()` kicks in automatically via the `if #available` check, giving users the full Liquid Glass experience with refraction, lensing, and specular highlights.

**Where glass appears (system handles it):**
- TabView bar — automatic material in iOS 18+, glass in iOS 26
- NavigationStack bar — automatic with `.navigationBarTitleDisplayMode(.large)`
- Sheet presentations — automatic
- You don't build ANY of these. The system does it.

**Where YOU add `.sweetieGlass()`:**
- Content cards (countdown, partner status, activity items)
- Quick action buttons
- Segmented controls
- Modal overlays

**Glass rules:**
- Max 3 custom glass surfaces visible per screen (system bars don't count)
- Glass needs content behind it — always use gradient backgrounds
- `.continuous` corner style everywhere (Apple's squircle)
- Don't apply `.glassEffect()` to text, images, or the mascot — only containers

---

## 2. Color System

Define as SwiftUI Color extensions. Use semantic naming.

```swift
extension Color {
    // Backgrounds (beneath glass)
    static let cream = Color(red: 0.992, green: 0.965, blue: 0.941)         // #FDF6F0
    static let blush = Color(red: 0.961, green: 0.902, blue: 0.863)         // #F5E6DC
    static let rosePale = Color(red: 0.980, green: 0.867, blue: 0.882)      // #FADDE1

    // Text
    static let ink = Color(red: 0.110, green: 0.086, blue: 0.094)           // #1C1618
    static let inkSoft = Color(red: 0.420, green: 0.361, blue: 0.380)       // #6B5C61
    static let inkFaint = Color(red: 0.659, green: 0.584, blue: 0.600)      // #A89599

    // Accent
    static let rose = Color(red: 0.831, green: 0.447, blue: 0.494)          // #D4727E
    static let roseLight = Color(red: 0.949, green: 0.710, blue: 0.737)     // #F2B5BC
    static let roseDark = Color(red: 0.722, green: 0.333, blue: 0.380)      // #B85561

    // Semantic
    static let gold = Color(red: 0.788, green: 0.663, blue: 0.431)          // #C9A96E
    static let sage = Color(red: 0.561, green: 0.663, blue: 0.549)          // #8FA98C
    static let lavender = Color(red: 0.722, green: 0.663, blue: 0.788)      // #B8A9C9
    static let night = Color(red: 0.239, green: 0.192, blue: 0.282)         // #3D3148
    static let dawn = Color(red: 0.910, green: 0.769, blue: 0.627)          // #E8C4A0
    static let sunset = Color(red: 0.831, green: 0.584, blue: 0.420)        // #D4956B
}
```

**Color rules:**
- NEVER use `.black` for text. Use `.ink`
- NEVER use `.white` for backgrounds. Use `.cream`
- Rose accent in max 3 places per screen: one interactive element, one indicator, one highlight
- Backgrounds are ALWAYS gradients (cream → blush minimum) so glass has content to refract
- Shadows: `.shadow(color: Color.ink.opacity(0.06), radius: 8, y: 2)` — warm, not gray

---

## 3. Typography

Two fonts. System for UI, Playfair Display for romance. The boundary is absolute.

```swift
// System font for ALL UI (this is what makes it feel native)
.font(.system(size: 17))                    // body
.font(.system(size: 28, weight: .bold))     // title1
.font(.system(size: 22, weight: .bold))     // title2
.font(.system(size: 17, weight: .semibold)) // headline
.font(.system(size: 13))                    // footnote
.font(.system(size: 11))                    // caption2

// Playfair Display for EMOTIONAL CONTENT ONLY
// Register in Info.plist, load .ttf files in bundle
.font(.custom("PlayfairDisplay-Bold", size: 48))      // heroDisplay — countdown
.font(.custom("PlayfairDisplay-Regular", size: 20))    // romantic — love notes
.font(.custom("PlayfairDisplay-Italic", size: 17))     // romanticSub — subtext
.font(.custom("PlayfairDisplay-Regular", size: 15))    // romanticSmall — questions
```

**Type scale:**
```
heroDisplay:    48pt  Playfair Bold       ← Countdown number ONLY
title1:         28pt  System Bold         ← Screen titles (native large title)
title2:         22pt  System Bold         ← Section headers
title3:         20pt  System SemiBold     ← Card titles
headline:       17pt  System SemiBold     ← Emphasized body
body:           17pt  System Regular      ← Primary body
callout:        16pt  System Regular      ← Secondary
subheadline:    15pt  System Regular      ← Descriptions
footnote:       13pt  System Regular      ← Captions
caption2:       11pt  System Regular      ← Timestamps (minimum size)

romantic:       20pt  Playfair Regular    ← Love note content
romanticSub:    17pt  Playfair Italic     ← "until I hold you again"
romanticSmall:  15pt  Playfair Regular    ← Question text
```

**Rules:**
- If it's navigation, a button, a timestamp, or a label → System font
- If it's a love note, countdown, question, or romantic subtext → Playfair
- ONE Playfair Italic line per screen maximum
- Never go below 11pt
- Left-align everything. Center only countdown numbers and short romantic text

---

## 4. Spacing & Layout

Use SwiftUI's native spacing and the iOS standard grid.

```swift
enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let hero: CGFloat = 48
    static let superHero: CGFloat = 64
}
```

**Screen structure:**
```
NavigationStack {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // Content sections
        }
        .padding(.horizontal, Spacing.xl)  // 20pt edges
    }
    .background(BackgroundGradient())       // ALWAYS
    .navigationTitle("Sweetie")
    .navigationBarTitleDisplayMode(.large)   // Glass nav bar automatic
}
```

**Rules:**
- `.padding(.horizontal, 20)` on all screen content
- `.padding()` (16pt default) inside glass cards
- VStack spacing between cards: 12pt
- VStack spacing between sections: 32pt
- ScrollView content bottom padding: 100pt (clear of tab bar)
- Use `.safeAreaInset` for floating elements, not manual padding

---

## 5. Background Gradients

Every screen MUST have a gradient background. Glass looks dead on flat colors.

```swift
struct BackgroundGradient: View {
    var style: GradientStyle = .default

    enum GradientStyle {
        case `default`  // cream → blush (most screens)
        case heart      // cream → rosePale → roseLight
        case photo      // adaptive based on latest photo
        case notes      // cream → warm parchment
    }

    var body: some View {
        switch style {
        case .default:
            LinearGradient(
                colors: [.cream, .blush],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        case .heart:
            LinearGradient(
                colors: [.cream, .rosePale, .roseLight],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        case .photo:
            LinearGradient(
                colors: [.cream, .blush],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        case .notes:
            LinearGradient(
                colors: [.cream, Color(red: 0.973, green: 0.929, blue: 0.890)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        }
    }
}
```

---

## 6. App Structure — Tab Bar with Center Heart Button

```
┌──────────────────────────────────────────────┐
│  🏠 Home     📸 Moments     💌 Notes     ⚙️  │
│                    ❤️                         │
│              ↑ Raised 60pt circle             │
│              Rose bg, white heart icon        │
│              Floats above tab bar             │
└──────────────────────────────────────────────┘
```

**4 tabs + 1 center action button:**
- Home — countdown, partner status, recent activity
- Moments — photo feed
- Center Heart (NOT a tab) — raised rose circle, overlaps tab bar by 20pt
  - Single tap: instant "thinking of you" tap + haptic
  - Long press / 3D Touch: radial menu with Send Tap, Send Photo, Write Note, Today's Question
- Notes — love notes + open when + daily questions combined
- Settings — profile, timezone, reunion date, notifications

**Tab bar styling:**
- System glass (automatic in iOS 26 TabView)
- Active: `.rose` tint
- Inactive: `.inkFaint`
- Heart button: 60pt circle, `.rose` background, white heart SF Symbol, shadow with rose tint
- Heart button sits in a custom `.safeAreaInset(.bottom)` or custom TabView implementation

---

## 7. Component Library

### GlassCard
```swift
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.lg)
            .sweetieGlass()
    }
}

// Usage:
GlassCard {
    VStack { ... }
}
```

### Buttons
```swift
// Primary — solid rose (the ONE non-glass interactive)
Button("Send with love") { }
    .buttonStyle(PrimaryButtonStyle())

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.rose)
            )
            .shadow(color: .rose.opacity(0.25), radius: 7, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// Secondary — glass
Button("Schedule for morning") { }
    .buttonStyle(GlassButtonStyle())

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.rose)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .sweetieGlass(cornerRadius: 14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
```

### Mascot
```swift
struct MascotView: View {
    enum Pose: String {
        case `default` = "mascot-default"
        case excited = "mascot-excited"
        case happy = "mascot-happy"
        case hug = "mascot-hug"
        case love = "mascot-love"
        case peek = "mascot-peek"
        case sleep = "mascot-sleep"
        case wave = "mascot-wave"
    }

    enum Animation {
        case breathe    // scale 0.97→1.03, 2s
        case bounce     // translateY 0→-8→0, 1s
        case wiggle     // rotate -3°→3°, 1.5s
        case none
    }

    let pose: Pose
    var size: CGFloat = 80
    var animation: Animation = .breathe

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .interpolation(.none)  // Keep pixel art crisp
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .modifier(MascotAnimationModifier(animation: animation))
    }
}
```

---

## 8. Motion & Animation

Use SwiftUI's native spring animations. Never use `.linear` or `.easeInOut` for interactive elements.

```swift
// Standard springs
.animation(.spring(duration: 0.3, bounce: 0.2))     // snappy — buttons, tabs
.animation(.spring(duration: 0.5, bounce: 0.3))     // gentle — cards, modals
.animation(.spring(duration: 0.4, bounce: 0.4))     // bouncy — heart tap, celebrations
.animation(.spring(duration: 0.8, bounce: 0.1))     // slow — page transitions

// Haptics
UIImpactFeedbackGenerator(style: .medium).impactOccurred()   // standard tap
UIImpactFeedbackGenerator(style: .heavy).impactOccurred()    // heart tap
UINotificationFeedbackGenerator().notificationOccurred(.success) // received tap
```

**Specific animations:**

Heart tap:
- Press: scale 0.88, spring(duration: 0.15)
- Release: scale 1.15 → 1.0, spring(duration: 0.4, bounce: 0.5)
- Ripple: 3 concentric circles expanding from touch, `.rose.opacity(0.3)` → `.clear`
- Haptic: `.heavy` impact on press, `.success` notification on release

Glass card entry:
- `.transition(.scale(scale: 0.95).combined(with: .opacity))`
- `.animation(.spring(duration: 0.5, bounce: 0.3))`

Countdown tick:
- `.contentTransition(.numericText())` — native iOS numeric transition
- This single line gives you the slot-machine digit animation for free

Photo received:
- `.transition(.move(edge: .top).combined(with: .opacity))`

**What NOT to animate:**
- Tab bar switches: instant
- Text input: instant
- Status dots (online/offline): instant color change
- Scroll: native momentum only

---

## 9. Iconography

Use SF Symbols exclusively. No icon libraries.

```swift
// Tab bar
Image(systemName: "house")          // Home
Image(systemName: "camera")         // Moments
Image(systemName: "heart.fill")     // Center button (always filled)
Image(systemName: "envelope")       // Notes
Image(systemName: "gearshape")      // Settings

// In-app
Image(systemName: "camera.fill")            // send photo action
Image(systemName: "square.and.pencil")      // write note
Image(systemName: "questionmark.circle")    // daily question
Image(systemName: "xmark")                  // dismiss modal
Image(systemName: "chevron.left")           // back (automatic)
Image(systemName: "globe")                  // timezone
Image(systemName: "circle.fill")            // status dot (8pt)
```

- 22pt for tab bar and in-content
- 24pt for action buttons
- Active: `.rose`, Inactive: `.inkFaint`
- Use `.symbolRenderingMode(.hierarchical)` for subtle depth

---

## 10. Timezone Design

```swift
struct PartnerStatusPill: View {
    // Glass pill showing partner's current state
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Avatar(size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Partner Name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.ink)
                HStack(spacing: 4) {
                    Text(timeOfDayEmoji)  // ☀️🌤️🌅🌙💤
                    Text("11:30 PM · Evening in Toronto")
                        .font(.system(size: 13))
                        .foregroundStyle(.inkSoft)
                }
            }
            Spacer()
            OnlineIndicator()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .glassEffect()
        )
    }
}
```

Time-of-day mapping:
- 6-12: ☀️ "Morning"
- 12-17: 🌤️ "Afternoon"
- 17-20: 🌅 "Evening"
- 20-23: 🌙 "Night"
- 23-6: 💤 "Likely sleeping" + mascot-sleep inline (32pt)

Smart send: inline non-blocking warning below send button when partner is sleeping.

---

## 11. Mascot Placement

All mascot images in `Assets.xcassets/Mascot/` — preserve as 1x at 1024x1024, let Xcode handle scaling.

| Pose | File | Where | Size | Animation |
|------|------|-------|------|-----------|
| default | mascot-default | Splash screen, general loading | 120pt / 48pt | breathe / bounce |
| excited | mascot-excited | Partner joins, countdown milestone | 100pt | bounce 3x |
| happy | mascot-happy | Onboarding, general delight | 60pt | breathe |
| hug | mascot-hug | Taps empty, "Open When" opened | 80pt | breathe |
| love | mascot-love | Notes empty, good morning/night | 80pt | breathe |
| peek | mascot-peek | Photos empty, onboarding screen 3 | 80pt / 64pt | none |
| sleep | mascot-sleep | Partner sleeping indicator | 32pt | breathe (3s) |
| wave | mascot-wave | Pairing wait, daily Q waiting | 100pt / 64pt | wiggle |

**Rules:**
- ONE mascot per screen max
- Mascot sits on background layer, NEVER inside a GlassCard
- Use `Image(pose).interpolation(.none)` to keep pixel art crisp
- Mascot supplements Liquid Glass — doesn't replace it

---

## 12. Anti-Patterns — NEVER Do These

1. **No custom navigation bars.** Use NavigationStack with `.navigationTitle()` and `.navigationBarTitleDisplayMode(.large)`. System handles the glass
2. **No custom tab bars** unless absolutely necessary for the center heart button. Even then, keep the system tab bar and overlay the heart
3. **No `.background(.white)` or `.background(Color.white)` anywhere.** Backgrounds are gradients or glass
4. **No custom fonts for UI text.** `.font(.system(...))` for everything except romantic content
5. **No `.easeInOut` or `.linear` for interactive animations.** Springs only
6. **No ALL CAPS.** Not in buttons, not in labels. `.textCase(nil)` if needed
7. **No raw `.glassEffect()` calls.** Always use `.sweetieGlass()` modifier so the iOS 18 fallback works automatically
8. **No dark mode.** Set `Info.plist` UIUserInterfaceStyle to "Light"
9. **No UIKit unless absolutely necessary.** Stay in SwiftUI
10. **No third-party UI libraries.** SwiftUI + SF Symbols + Supabase Swift SDK. That's it
11. **No spinners.** Mascot bounce animation for loading states
12. **No emoji in button labels or navigation.** Emoji in content only

---

## 13. Project Structure

```
Sweetie/
├── SweetieApp.swift              ← @main, app entry, Supabase init
├── Info.plist                    ← Light mode only, font registration
├── Assets.xcassets/
│   ├── Colors/                   ← All color assets
│   ├── Mascot/                   ← 8 mascot PNGs
│   └── AppIcon.appiconset/       ← Mascot on gradient
├── Fonts/
│   ├── PlayfairDisplay-Regular.ttf
│   ├── PlayfairDisplay-Bold.ttf
│   ├── PlayfairDisplay-Medium.ttf
│   └── PlayfairDisplay-Italic.ttf
├── Models/
│   ├── Profile.swift
│   ├── Couple.swift
│   ├── Tap.swift
│   ├── Photo.swift
│   ├── LoveNote.swift
│   └── DailyQuestion.swift
├── Services/
│   ├── SupabaseService.swift     ← Client, auth, realtime
│   ├── NotificationService.swift
│   └── HapticService.swift
├── Views/
│   ├── MainTabView.swift         ← 4 tabs + center heart
│   ├── Home/
│   │   └── HomeView.swift        ← Countdown, partner status, activity
│   ├── Moments/
│   │   └── MomentsView.swift     ← Photo feed
│   ├── Notes/
│   │   └── NotesView.swift       ← Love notes + open when + questions
│   ├── Settings/
│   │   └── SettingsView.swift    ← Profile, timezone, reunion, notifications
│   ├── Onboarding/
│   │   └── OnboardingView.swift  ← 4 swipeable screens with mascot
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── PairingView.swift
│   └── Components/
│       ├── GlassCard.swift
│       ├── PrimaryButton.swift
│       ├── GlassButton.swift
│       ├── MascotView.swift
│       ├── BackgroundGradient.swift
│       ├── PartnerStatusPill.swift
│       ├── CountdownCard.swift
│       ├── HeartButton.swift     ← The center tab button
│       └── QuickActionMenu.swift ← Radial/sheet from heart
├── Theme/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Animations.swift
└── Utilities/
    ├── TimezoneHelper.swift
    └── DateFormatting.swift
```

---

## 14. Quality Checklist

Before any screen is "done":

- [ ] Uses `NavigationStack` with `.navigationTitle()` (system glass nav)
- [ ] Background is `BackgroundGradient()`, not flat color
- [ ] Cards use `.sweetieGlass()` modifier (not raw `.glassEffect()` or opaque backgrounds)
- [ ] All UI text uses `.font(.system(...))`, Playfair only for romantic content
- [ ] No text below 11pt
- [ ] Touch targets 44pt minimum (`.frame(minWidth: 44, minHeight: 44)`)
- [ ] Rose accent max 3 places per screen
- [ ] 20pt horizontal padding on content
- [ ] Pressed states on all buttons (`.scaleEffect` in `ButtonStyle`)
- [ ] Animations use `.spring()`, never `.linear` or `.easeInOut`
- [ ] Mascot appears in empty/loading states with correct pose
- [ ] Content scrolls beneath glass tab bar and nav bar
- [ ] Haptic feedback on heart tap and key interactions
- [ ] Runs on iOS 18+ without warnings (iOS 26 gets enhanced glass automatically)