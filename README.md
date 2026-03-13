# Sweetie

A native SwiftUI couples app for long-distance relationships. Built with iOS 18+ support and an iOS 26 Liquid Glass upgrade path.

## Features

- **Heart Button** — Send love with haptics and ripple animations
- **Moments** — Share photos and memories together
- **Notes** — Leave sweet messages for your partner
- **Countdown** — Track days until you're together again
- **Pairing** — Simple invite-code partner linking

## Tech Stack

- **UI**: SwiftUI (iOS 18 minimum, iOS 26 Liquid Glass on supported devices)
- **Backend**: Supabase (auth, database, realtime)
- **Build**: XcodeGen
- **Swift**: 6.0 with strict concurrency

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```

2. Create a `.env` file in the project root with your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

3. Generate the Xcode project and open it:
   ```bash
   xcodegen generate
   open Sweetie.xcodeproj
   ```

4. Build and run on a simulator or device (iOS 18+).

## Project Structure

```
Sweetie/
├── Theme/          # Colors, Typography, Spacing, Animations
├── Models/         # Codable structs matching Supabase tables
├── Services/       # SupabaseService, HapticService, SoundService
├── Views/
│   ├── Components/ # GlassCard, MascotView, HeartButton, etc.
│   ├── Home/
│   ├── Moments/
│   ├── Notes/
│   ├── Settings/
│   ├── Auth/
│   └── Onboarding/
supabase/           # Database migrations and config
```

## Design

See [design.md](design.md) for the full design spec. Key principles:

- Native above all — use built-in SwiftUI components
- Content is the interface — photos and countdowns ARE the screens
- One delightful moment per screen — one animation, one haptic, one smile
