# TODOS

## P2: Tap Streak Indicator for Widgets
**What:** Show a flame emoji + streak count (e.g., "🔥 7") in tap widgets when both partners have tapped each other daily for consecutive days.

**Why:** Creates a daily ritual and emotional hook (like Snapchat streaks). Makes the widget feel alive and gamifies the core interaction.

**Context:** The InteractiveTapWidget and LastTapWidget already show tap data. Streak would be an additional data field synced via SharedDataManager. Key decision: does "today" mean the sender's timezone or UTC? What breaks a streak — midnight UTC or midnight local? Consecutive day tracking needs careful timezone handling.

**Effort:** M (2-3 hours)
**Depends on:** InteractiveTapWidget (shipped)

---

## P2: Live Activities for Partner Presence
**What:** Use ActivityKit to show a persistent Dynamic Island / lock screen indicator when your partner is online (using the existing Supabase Presence channel).

**Why:** The ultimate "ambient awareness" feature. Glance at phone → Dynamic Island shows a tiny beating heart → partner is on their phone right now. No notification, no app open.

**Context:** The app already tracks `isPartnerOnline` via Supabase Presence channels. The challenge is bridging that to ActivityKit since the widget extension can't subscribe to realtime channels. Would need push-to-start Live Activities via APNs, which requires the push notification infrastructure to be fully operational.

**Effort:** L (4-6 hours)
**Depends on:** Push notification infrastructure

---

## P3: Answer Today's Question from Widget
**What:** Make the TodayQuestionWidget interactive — user can type a short answer directly in the widget using AppIntent + TextFieldIntent (iOS 17+), without opening the app.

**Why:** Reduces friction on the daily question ritual. See question on home screen, type answer, done.

**Context:** The read-only TodayQuestionWidget and WidgetAPIClient already exist. Adding interactivity would be incremental. But TextFieldIntent in widgets can feel clunky (opens a system text input overlay). Better to ship read-only first and see if users want inline answers.

**Effort:** S (1-2 hours)
**Depends on:** TodayQuestionWidget + WidgetAPIClient (shipped)
