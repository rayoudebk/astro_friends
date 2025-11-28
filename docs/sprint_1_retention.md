# Sprint 1: Retention & Notifications Foundations

## 🎯 Goal

Improve user retention by:
- Showing "New this week" indicators for fresh content
- Adding a simple client-side streak system
- Laying foundation for notifications + analytics

---

## ✅ In Scope

### 1. "New ✨" Pill Indicators
- **Weekly Horoscope** (Home): Show badge when new weekly content is available and unseen
- **"This Week" Compatibility** (CompatibilityView): Show badge for fresh weekly compatibility

### 2. StreakManager
Track user engagement locally (UserDefaults):
- `lastActiveDate` - Last day user opened the app
- `currentStreakDays` - Current consecutive days
- `longestStreakDays` - Personal best streak

### 3. NotificationManager
Foundation for push notifications:
- `requestPermissionIfNeeded()` - Request notification permission
- `scheduleWeeklyReminderPlaceholder()` - Placeholder for weekly reminder scheduling

### 4. AnalyticsManager
Simple event tracking (console logging for now):
- `trackEvent(name:properties:)` - Log events with optional properties
- Events: `weekly_horoscope_viewed`, `compatibility_weekly_viewed`, `streak_updated`

---

## ❌ Out of Scope (Sprint 2+)

- Real remote push notification scheduling
- StoreKit / monetization
- Complex gamification (badges, levels, rewards)
- Server-side streak persistence
- Real analytics backend (Mixpanel, Amplitude, etc.)

---

## 📁 Files Created

| File | Purpose |
|------|---------|
| `Managers/StreakManager.swift` | Client-side streak tracking |
| `Managers/NotificationManager.swift` | Notification permission + placeholder |
| `Managers/AnalyticsManager.swift` | Event tracking abstraction |
| `docs/sprint_1_retention.md` | This document |

---

## ✅ Definition of Done

- [ ] StreakManager correctly tracks consecutive app opens
- [ ] NotificationManager requests permission without being annoying
- [ ] AnalyticsManager logs events to console
- [ ] "New ✨" badge appears on fresh weekly horoscope
- [ ] "New ✨" badge appears on fresh "This Week" compatibility
- [ ] Badges disappear after user views the content
- [ ] All managers are wired into the app lifecycle
- [ ] Project builds without errors
- [ ] All changes committed to `feature/sprint1-retention` branch

---

## 💡 Follow-up Ideas for Sprint 2

### Notifications
- [ ] Implement actual weekly reminder scheduling (Monday 9am)
- [ ] Add "Mercury Retrograde" alert notifications
- [ ] Add birthday reminder notifications for contacts

### Streaks
- [ ] Display streak in UI (flame icon + counter)
- [ ] Add streak milestone celebrations (7 days, 30 days, etc.)
- [ ] Sync streak to backend for cross-device persistence

### Analytics
- [ ] Wire to real analytics service (Mixpanel/Amplitude)
- [ ] Add funnel tracking (onboarding → first horoscope → first compatibility)
- [ ] Track premium conversion events

### Engagement
- [ ] Add daily check-in reward system
- [ ] Implement "Share your horoscope" for social retention
- [ ] Add weekly email digest option

---

## 📝 Implementation Notes

### Streak Logic
```
if no lastActiveDate:
    streak = 1
else if same calendar day:
    no change
else if exactly 1 day since lastActiveDate:
    streak += 1
else (gap > 1 day):
    streak = 1 (reset)
    
always: update longestStreak if currentStreak > longestStreak
```

### Week Detection
Uses ISO week number (`Calendar.component(.weekOfYear)`) to determine if content is "new this week".

### Storage Keys (UserDefaults)
- `streak_lastActiveDate` - ISO date string
- `streak_currentDays` - Int
- `streak_longestDays` - Int
- `horoscope_lastSeenWeek_[SIGN]` - Week identifier string
- `compatibility_thisWeek_seen_[PAIR_KEY]` - Bool

---

*Created: Sprint 1 | AstroFriends v2*

