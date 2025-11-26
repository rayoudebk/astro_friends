# 📊 Astro Friends - Content Architecture

## Overview

The app uses **three tiers of content** that differ by how often they change and whether they're personalized.

---

## 🏛️ TIER 1: Static Content (Never Changes)

**What:** Fundamental astrological facts that are universally true.

| Content | Location | Example |
|---------|----------|---------|
| Zodiac sign traits | `Contact.swift` → `ZodiacSign` | "Aries is courageous, pioneering" |
| Element associations | `ZodiacSign.element` | Aries = Fire |
| Modality | `ZodiacSign.modality` | Aries = Cardinal |
| Date ranges | `ZodiacSign.dateRange` | "Mar 21 - Apr 19" |
| Emojis & icons | `ZodiacSign.emoji` | ♈️ |
| Key traits | `ZodiacSign.keyTraits` | "courageous, pioneering, competitive" |
| Moon phase meanings | `Horoscope.swift` → `MoonPhase` | Full Moon = "emotionally heightened" |
| Moon sign traits | `MoonSign.emotionalFlavor` | Moon in Cancer = "nurturing" |
| Base compatibility scores | `CompatibilityEngine.swift` | Aries + Leo = 88% |
| Elemental dynamics | `ElementalDynamic` | Fire + Fire = "Passionate" |
| Harmony level descriptions | `HarmonyLevel` | 85%+ = "Soulmates" |

**Source:** Hardcoded in Swift files  
**Updates:** Only with app updates  
**Currently:** ✅ All implemented locally

---

## 🌙 TIER 2: Weekly Global Content (Same for All Users of a Sign)

**What:** Content that changes each week but is the same for everyone with that zodiac sign.

| Content | Current State | Source |
|---------|---------------|--------|
| Weekly horoscope per sign | ✅ AI or fallback | `ContentService.getWeeklyHoroscope()` |
| Moon phase for the week | ✅ Calculated/API | `Horoscope.currentMoonPhase` |
| Planetary transits | ✅ Fetched from API | `WeeklySky.transits` |
| Lucky number/color per sign | ✅ AI-generated | `WeeklyHoroscope.luckyNumber/Color` |
| Sign's mood for the week | ✅ AI-generated | `WeeklyHoroscope.mood` (authoritative) |
| Power/Challenge days | ✅ AI-generated | `WeeklyHoroscope.powerDay/challengeDay` |
| Weekly affirmation | ✅ AI-generated | `WeeklyHoroscope.affirmation` |

**Architecture:**
```
┌─────────────────────────────────────────────────────────┐
│              TIER 2 FETCH FLOW                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  HomeView / HoroscopeCardView                           │
│           │                                             │
│           ▼                                             │
│  ContentService.getWeeklyHoroscope(sign)                │
│           │                                             │
│           ├─► Check local cache (7-day expiry)          │
│           │         │                                   │
│           │         ├─► Cache hit → return              │
│           │         │                                   │
│           │         └─► Cache miss ↓                    │
│           │                                             │
│           ├─► Fetch from Supabase weekly_horoscopes     │
│           │         │                                   │
│           │         ├─► Found → cache & return          │
│           │         │                                   │
│           │         └─► Not found ↓                     │
│           │                                             │
│           └─► Fallback to static Tier 1                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Supabase Table:** `weekly_horoscopes`
```sql
CREATE TABLE weekly_horoscopes (
    sign TEXT NOT NULL,
    week_start DATE NOT NULL,
    weekly_reading TEXT NOT NULL,
    mood TEXT NOT NULL,           -- AUTHORITATIVE for Tier 2
    lucky_number INTEGER,
    lucky_color TEXT,
    love_forecast TEXT,
    career_forecast TEXT,
    power_day TEXT,
    challenge_day TEXT,
    affirmation TEXT,
    UNIQUE(sign, week_start)
);
```

**Currently:** ✅ Implemented - `ContentService.swift` unifies fetching

---

## ✨ TIER 3: Personalized Content (Unique Per Person)

**What:** Content generated specifically for an individual based on their full birth chart.

| Content | Location | Personalization Factors |
|---------|----------|------------------------|
| Oracle reading | `OracleManager` → Gemini | Sun + Moon + Rising + Weekly transits |
| Lucky number | `OracleContent.luckyNumber` | Generated per person |
| Lucky color | `OracleContent.luckyColor` | Generated per person |
| Celestial insight | `OracleContent.celestialInsight` | Chart-specific advice |
| Love advice | `OracleContent.loveAdvice` | Based on Venus placement (future) |
| Career advice | `OracleContent.careerAdvice` | Based on Saturn/10th house (future) |

**How it works now:**
1. User opens contact with birthday
2. `ContentService.getOracleContent()` is called
3. Creates `AstroProfile` (sun/moon/rising)
4. Calls Gemini with their specific chart data
5. Returns personalized reading
6. Cached in Supabase `oracle_content` table

**Currently:** ✅ Implemented and working!

---

## 🤝 Compatibility: From Static to Live

Compatibility uses a **three-layer model** with centralized logic in `CompatibilityEngine.swift`.

### Layer 1: Overall Compatibility (static, timeless) ✅

**Location:** `CompatibilityEngine.swift`

**Functions:**
```swift
CompatibilityEngine.overallCompatibility(signA:signB:)
CompatibilityEngine.fullCompatibility(sunA:moonA:risingA:sunB:moonB:risingB:)
CompatibilityEngine.elementBonus(signA:signB:)
CompatibilityEngine.modalityBonus(signA:signB:)
CompatibilityEngine.moonCompatibility(moonA:moonB:)
CompatibilityEngine.risingCompatibility(risingA:risingB:)
CompatibilityEngine.poeticSummary(signA:signB:)
CompatibilityEngine.nurturingAdvice(signA:signB:)
```

**Properties:**
- Does **not** change over time.
- Calculated locally in Swift.
- Shown as the "Overall" tab in CompatibilityView.

**Status:** ✅ Implemented

---

### Layer 2: This Week Compatibility (dynamic, weekly) ✅

**Location:** `ContentService.getThisWeekCompatibility()` → `OracleManager` → `GeminiService`

**Inputs:**
- `WeeklySky` (moon phase + major transits)
- Each person's weekly mood from Oracle
- Base compatibility from Layer 1

**Output:**
```json
{
  "thisWeekScore": 78,
  "loveCompatibility": "High",
  "communicationCompatibility": "Medium",
  "weeklyVibe": "Magnetic",
  "summary": "This week brings a heightened sense of connection...",
  "growthAdvice": "Practice active listening when emotions run high.",
  "celestialInfluence": "Venus trine Mars amplifies attraction energy."
}
```

**Status:** ✅ Implemented

---

### Layer 3: Live Compatibility (optional, daily) ⏳

**What it is:**
- A more granular "today's vibe" score/label.

**Placeholders:**
```swift
// Future: Add to CompatibilityCache
var liveCompatibilityScore: Int?
var liveCompatibilityStatus: LiveStatus? // .loading | .locked | .available
var liveVibe: String?
```

**Status:** 🔜 Architecture ready for future

---

## 🧩 Contact Completion & Feature Unlock System

The app uses `FeatureUnlock` to determine what features are available based on contact data.

### Completion Levels ✅

| Level | Data Known | Percentage |
|-------|------------|------------|
| **None** | No birthday | 0% |
| **Basic** | Birthday only | 40% |
| **Extended** | Birthday + time OR place | 70% |
| **Full** | Birthday + time + place | 100% |

### Feature Unlock Table ✅

| Feature | Required Level | Source |
|---------|---------------|--------|
| Sun Sign Traits | Basic | Local |
| Basic Horoscope | Basic | Local |
| Overall Compatibility | Basic | Local |
| Weekly Horoscope | Basic | Supabase (Tier 2) |
| Moon Sign Insights | Extended | Local + Gemini |
| Personal Oracle | Extended | Gemini (Tier 3) |
| Rising Sign | Full | AstrologyAPI |
| This Week Compatibility | Full | Gemini |
| Synastry Insights | Full | Future |
| Live Compatibility | Full | Future |

### Implementation ✅

**Contact Model:**
```swift
var astroCompletionLevel: AstroCompletionLevel
var astroCompletionPercentage: Int  // 0-100
var missingAstroData: [String]      // ["birth time", "birth place"]
```

**Feature Unlock:**
```swift
FeatureUnlock.canAccess(.thisWeekCompatibility, for: contact)
FeatureUnlock.unlockedFeatures(for: contact)
FeatureUnlock.lockedFeatures(for: contact)
FeatureUnlock.nextUnlocks(for: contact) // What to add to unlock more
```

**UI Pattern:**
- `ContactDetailView` shows completion indicator card
- `CompatibilityView` shows locked "This Week" tab
- Inline CTAs: "Add birth time to unlock deeper readings"

---

## 📦 Unified Services Architecture

### ContentService.swift ✅

Centralizes all content fetching with caching:

```swift
ContentService.shared.getWeeklyHoroscope(for: sign)      // Tier 2
ContentService.shared.getAllWeeklyHoroscopes()           // Batch Tier 2
ContentService.shared.getWeeklySky()                     // Tier 2
ContentService.shared.getOracleContent(for: contact)     // Tier 3
ContentService.shared.getOverallCompatibility(user:contact:) // Tier 1
ContentService.shared.getThisWeekCompatibility(user:contact:) // Dynamic
ContentService.shared.clearCache()                       // Cache management
ContentService.shared.refreshWeeklyContent()             // Force refresh
```

### CompatibilityEngine.swift ✅

Centralizes all static compatibility calculations:

```swift
CompatibilityEngine.overallCompatibility(signA:signB:)
CompatibilityEngine.fullCompatibility(...)
CompatibilityEngine.elementBonus(signA:signB:)
CompatibilityEngine.modalityBonus(signA:signB:)
CompatibilityEngine.moonCompatibility(moonA:moonB:)
CompatibilityEngine.risingCompatibility(risingA:risingB:)
CompatibilityEngine.poeticSummary(signA:signB:)
CompatibilityEngine.nurturingAdvice(signA:signB:)
```

---

## 📍 Where Content Comes From (Current State)

```
┌─────────────────────────────────────────────────────────┐
│                      HOME VIEW                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Weekly Horoscope Card:                                 │
│  ├─ Reading text           → Tier 2 ✨ OR Tier 1        │
│  ├─ Mood badge             → Tier 2 ✨ OR Tier 1        │
│  └─ ✨ badge if AI         → isAIGenerated flag        │
│                                                         │
│  Best/Growth Connections:                               │
│  └─ Scores                 → CompatibilityEngine        │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                  CONTACT DETAIL VIEW                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Astro Completion Card (if not full):                   │
│  ├─ Completion %          → Contact.astroCompletionLevel│
│  └─ Missing data          → Contact.missingAstroData    │
│                                                         │
│  Weekly Horoscope Card:                                 │
│  ├─ Sign emoji/dates      → Static (ZodiacSign)        │
│  ├─ Mood badge            → AI Oracle ✨ OR Fallback    │
│  ├─ Reading text          → AI Oracle ✨ OR Fallback    │
│  └─ Lucky #, Color        → AI Oracle ✨                │
│                                                         │
│  Compatibility Card:                                    │
│  ├─ Score percentage      → CompatibilityEngine         │
│  ├─ Harmony level         → CompatibilityEngine         │
│  └─ Poetic summary        → CompatibilityEngine         │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   COMPATIBILITY VIEW                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Tab: Overall                                           │
│  ├─ Harmony score         → CompatibilityEngine         │
│  ├─ Poetic summary        → CompatibilityEngine         │
│  ├─ Moon/Rising compat    → CompatibilityEngine         │
│  ├─ Strengths/Growth      → AstralCompatibility         │
│  └─ Nurturing advice      → CompatibilityEngine         │
│                                                         │
│  Tab: This Week ✨ (or 🔒 if locked)                    │
│  ├─ This week score       → ContentService → Gemini     │
│  ├─ Weekly vibe badge     → Gemini                      │
│  ├─ Love/Communication    → Gemini                      │
│  ├─ Weekly reading        → Gemini                      │
│  ├─ Celestial influence   → Gemini + WeeklySky          │
│  └─ Growth tip            → Gemini                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

```
                    ┌──────────────────┐
                    │   CONTACT DATA   │
                    │  (birthday, etc) │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────┐
        │   CONTENT    │ │ ASTROLOGYAPI │ │  GEMINI  │
        │   SERVICE    │ │   (Charts)   │ │   (AI)   │
        └──────┬───────┘ └──────┬───────┘ └────┬─────┘
               │                │               │
               ▼                ▼               │
        ┌──────────────┐ ┌──────────────┐      │
        │ COMPATIBILITY│ │ AstroProfile │      │
        │   ENGINE     │ │ + WeeklySky  │      │
        │  (Static)    │ └──────┬───────┘      │
        └──────────────┘        │              │
                                └──────┬───────┘
                                       ▼
                         ┌─────────────────────┐
                         │ OracleContent       │
                         │ WeeklyHoroscope     │
                         │ CompatibilityCache  │
                         └─────────┬───────────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │   SUPABASE     │
                          │   (cache)      │
                          └────────────────┘
```

---

## 📋 Summary: What Should Change vs What's Static

| Question | Answer | Source |
|----------|--------|--------|
| "What sign is March 25?" | **Static** - Aries | ZodiacSign |
| "What element is Aries?" | **Static** - Fire | ZodiacSign |
| "Base compatibility?" | **Static** - 88% | CompatibilityEngine |
| "This week's connection?" | **Dynamic** - AI | ContentService → Gemini |
| "Aries horoscope this week?" | **Tier 2** - Same for all | ContentService |
| "Kate's personal reading?" | **Tier 3** - Unique | OracleManager → Gemini |
| "What can I unlock?" | **Feature Table** | FeatureUnlock |

---

## 🚀 Implementation Status

### Completed ✅
1. ~~Weekly horoscopes table schema~~
2. ~~ContentService.swift (unified fetching)~~
3. ~~CompatibilityEngine.swift (centralized static)~~
4. ~~FeatureUnlock system (truth table)~~
5. ~~HomeView Tier 2 integration~~
6. ~~HoroscopeCardView Tier 2 integration~~
7. ~~GeminiService.generateWeeklySignHoroscope()~~
8. ~~"This Week" Compatibility UI + logic~~

### In Progress 🔄
9. Separate Tier 2 vs Tier 3 cards in ContactDetailView
10. WeeklySky cron job (Supabase function)

### Future 🔜
11. Live Compatibility (Layer 3) placeholders
12. Synastry deep compatibility
13. Push notifications
14. Birth time prompts
15. Venus/Mars placements
