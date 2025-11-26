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
| Moon phase meanings | `Horoscope.swift` → `MoonPhase` | Full Moon = "emotionally heightened" |
| Moon sign traits | `MoonSign.emotionalFlavor` | Moon in Cancer = "nurturing" |
| Base compatibility scores | `AstralCompatibility.swift` | Aries + Leo = 88% (hardcoded matrix) |
| Elemental dynamics | `ElementalDynamic` | Fire + Fire = "Passionate" |
| Harmony level descriptions | `HarmonyLevel` | 85%+ = "Soulmates" |

**Source:** Hardcoded in Swift files  
**Updates:** Only with app updates  
**Currently:** ✅ All implemented locally

---

## 🌙 TIER 2: Weekly Global Content (Same for All Users of a Sign)

**What:** Content that changes each week but is the same for everyone with that zodiac sign.

| Content | Current State | Should Be |
|---------|---------------|-----------|
| Weekly horoscope per sign | ❌ Hardcoded in `Horoscope.swift` | 🔄 Fetch from Supabase (AI-generated weekly) |
| Moon phase for the week | ✅ Calculated locally | ✅ Could also fetch from AstrologyAPI |
| Planetary transits | ✅ Fetched from AstrologyAPI | ✅ Stored as `WeeklySky` in Supabase |
| Lucky number/color per sign | ❌ Hardcoded | 🔄 Part of weekly AI generation |
| Sign's mood for the week | ✅ AI-generated | ✅ Stored in oracle, reused in compatibility |

**How it should work (target architecture):**
1. Every Monday, a scheduled job generates 12 horoscopes (one per sign)
2. Uses AstrologyAPI for current transits
3. Uses Gemini to write the content
4. Stores in Supabase `weekly_horoscopes` table
5. All Aries users see the same Aries horoscope that week

**Currently:** ⚠️ Partially implemented - `Horoscope.getWeeklyHoroscope()` still returns hardcoded content as fallback

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
2. `OracleManager.generateOracleContent()` is called
3. Creates `AstroProfile` (sun/moon/rising)
4. Calls Gemini with their specific chart data
5. Returns personalized reading
6. Cached in Supabase `oracle_content` table

**Currently:** ✅ Implemented and working!

---

## 🤝 Compatibility: From Static to Live

Compatibility has evolved from a purely static system to a **three-layer model** that mixes local logic, live sky data, and AI.

### Layer 1: Overall Compatibility (static, timeless) ✅

**What it is:**
- A stable, "baseline" score between two contacts.

**Inputs:**
- Sun–Sun compatibility (existing 12×12 matrix in `AstralCompatibility.swift`)
- Elemental harmony (Fire / Earth / Air / Water)
- Modality harmony (Cardinal / Fixed / Mutable)
- Moon compatibility bonus (existing)
- Rising compatibility bonus (optional)

**Properties:**
- Does **not** change over time.
- Calculated locally in Swift.
- Shown as the "Overall" score in the UI.

**Status:** ✅ Implemented

---

### Layer 2: This Week Compatibility (dynamic, weekly) ✅

**What it is:**
- A **weekly modifier** on top of Overall Compatibility that reflects the current sky and each person's weekly mood.

**Additional inputs:**
- `WeeklySky` (moon phase + major transits for the week)
- Each person's weekly mood from their horoscope (Tier 3 / Oracle)
- Optional synastry summary (from AstrologyAPI `synastry_horoscope`, sanitized)

**How it's computed:**
- `OracleManager.generateWeeklyCompatibility()` orchestrates the flow
- `GeminiService.generateWeeklyCompatibility()` generates the AI reading
- Gemini receives profiles, moods, and sky data, outputs structured JSON

**Gemini Output:**
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

**Properties:**
- Updated every Monday (or on-demand).
- Stored in Supabase `compatibility_cache` table.
- Shown as "This Week" tab in CompatibilityView.

**Status:** ✅ Implemented

---

### Layer 3: Live Compatibility (optional, daily or event-based) ⏳

**What it is:**
- A more granular "today's vibe between you two" score/label.

**Additional inputs:**
- Current moon sign / phase
- Short-term transits that strongly affect emotions/relationships

**Properties:**
- Can be updated daily or only when a big relevant transit occurs.
- Shown as a subtle hint: e.g. "Today your connection feels a bit closer than usual."
- Optional for MVP, but the architecture allows adding this layer later.

**Status:** 🔜 Future enhancement

---

## 🧩 Contact Completion & Locked Astro Features

The more astro data we have for a contact, the deeper the readings we can offer. The UI makes this transparent and motivating.

### Completion Levels ✅

| Level | Data Known | Features Available |
|-------|------------|-------------------|
| **None** | No birthday | Nothing (add birthday prompt) |
| **Basic** | Birthday only | Sun sign traits, basic horoscope, Overall compatibility |
| **Extended** | Birthday + time OR place | Moon sign insights, better Oracle readings |
| **Full** | Birthday + time + place | Full chart, Rising sign, This Week compatibility, synastry |

### Implementation ✅

**Contact Model:**
```swift
var astroCompletionLevel: AstroCompletionLevel
var astroCompletionPercentage: Int  // 0-100
var missingAstroData: [String]      // ["birth time", "birth place"]
```

**UI Pattern:**
- `ContactDetailView` shows completion indicator card when not full
- Progress ring with percentage
- "Add X to unlock deeper readings" inline CTA
- `CompatibilityView` shows locked "This Week" tab with unlock prompt

**Privacy Note:** Birth details stay on-device. Only derived astro data (signs, not dates) is sent to Supabase/Gemini.

---

## 📍 Where Content Comes From (Current State)

```
┌─────────────────────────────────────────────────────────┐
│                     CONTACT DETAIL VIEW                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Astro Completion Card (if not full):                   │
│  └─ Completion %          → Local (Contact model)       │
│                                                         │
│  Weekly Horoscope Card:                                 │
│  ├─ Sign emoji/name/dates  → Static (ZodiacSign)       │
│  ├─ Mood badge             → AI Oracle ✨ OR Fallback   │
│  ├─ Reading text           → AI Oracle ✨ OR Fallback   │
│  └─ Lucky #, Color         → AI Oracle ✨               │
│                                                         │
│  Compatibility Card:                                    │
│  ├─ Score percentage       → Static (AstralCompatibility)│
│  ├─ Harmony level          → Static (HarmonyLevel enum) │
│  └─ Poetic summary         → Static (hardcoded strings) │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   COMPATIBILITY VIEW                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Tab: Overall                                           │
│  ├─ Harmony score          → Static (AstralCompatibility)│
│  ├─ Poetic summary         → Static                     │
│  ├─ Oracle reading         → Static                     │
│  ├─ Moon/Rising compat     → Static (if data available) │
│  ├─ Strengths/Growth       → Static                     │
│  └─ Nurturing advice       → Static                     │
│                                                         │
│  Tab: This Week ✨ (or 🔒 if locked)                    │
│  ├─ This week score        → AI (Gemini) via Supabase   │
│  ├─ Weekly vibe badge      → AI                         │
│  ├─ Love/Communication     → AI                         │
│  ├─ Weekly reading         → AI                         │
│  ├─ Celestial influence    → AI + WeeklySky             │
│  └─ Growth tip             → AI                         │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     HOME VIEW                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Your Weekly Horoscope:                                 │
│  ├─ All content            → Static (Horoscope.swift)  │
│  └─ Moon phase             → Calculated locally         │
│                                                         │
│  Best/Growth Connections:                               │
│  └─ Scores                 → Static (AstralCompatibility)│
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
        ┌──────────┐  ┌──────────────┐  ┌──────────┐
        │  LOCAL   │  │ ASTROLOGYAPI │  │  GEMINI  │
        │ (Static) │  │   (Charts)   │  │   (AI)   │
        └────┬─────┘  └──────┬───────┘  └────┬─────┘
             │               │               │
             │               ▼               │
             │        ┌──────────────┐       │
             │        │ AstroProfile │       │
             │        │ + WeeklySky  │       │
             │        └──────┬───────┘       │
             │               │               │
             │               └───────┬───────┘
             │                       ▼
             │         ┌─────────────────────┐
             │         │ OracleContent       │
             │         │ CompatibilityCache  │
             │         │ (personalized)      │
             │         └─────────┬───────────┘
             │                   │
             │                   ▼
             │          ┌────────────────┐
             │          │   SUPABASE     │
             │          │   (cache)      │
             │          └────────────────┘
             │
             ▼
    ┌────────────────┐
    │  Fallback if   │
    │  no API/cache  │
    └────────────────┘
```

---

## 📋 Summary: What Should Change vs What's Static

| Question | Answer |
|----------|--------|
| "What sign is someone born March 25?" | **Static** - Aries, always |
| "What element is Aries?" | **Static** - Fire, always |
| "Are Aries and Leo compatible?" | **Static base** - 88% (Overall) |
| "How compatible are they THIS WEEK?" | **Dynamic** - AI-generated weekly |
| "What's this week's horoscope for Aries?" | **Weekly Global** - Same for all Aries |
| "What's Kate's (Aquarius ☀️ Sagittarius 🌙) reading?" | **Personalized** - Unique to her chart |
| "What's Kate's lucky number this week?" | **Personalized** - Generated by AI |
| "What can I unlock by adding birth time?" | **Completion Level** - Extended → Full features |

---

## 🚀 Future Improvements

1. ~~**Weekly Global Horoscopes**~~ - Run scheduled job to generate 12 sign horoscopes every Monday
2. ~~**AI Compatibility**~~ - ✅ "This Week" compatibility implemented
3. **Synastry** - Use AstrologyAPI's synastry endpoint for detailed chart comparison
4. **Push Notifications** - "Your weekly reading is ready!"
5. **Birth Time Prompts** - Ask users for birth time to improve Rising sign accuracy
6. **Live Compatibility** - Daily vibe based on moon transits (Layer 3)
7. **Venus/Mars placements** - Enhanced love compatibility
