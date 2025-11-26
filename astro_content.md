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
| Planetary transits | ❌ Hardcoded | 🔄 Fetch from AstrologyAPI weekly |
| Lucky number/color per sign | ❌ Hardcoded | 🔄 Part of weekly AI generation |
| Sign's mood for the week | ❌ Hardcoded | 🔄 Part of weekly AI generation |

**How it should work:**
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

## 🤝 Compatibility: A Hybrid Approach

| Layer | Type | Source |
|-------|------|--------|
| Base score (Sun signs only) | Static | Hardcoded in `AstralCompatibility.swift` |
| Elemental harmony | Static | Fire+Water = challenging, etc. |
| Moon compatibility bonus | Static | Calculated from moon sign pairing |
| Weekly compatibility reading | Personalized | 🔄 Could use Gemini with both charts |
| Synastry aspects | Personalized | 🔄 Requires AstrologyAPI `synastry_horoscope` |

**Current state:**
- ✅ Base scores work (hardcoded 12x12 matrix)
- ✅ Moon/Rising bonuses calculated locally
- ❌ AI-enhanced compatibility not wired up yet (service exists but not used in UI)

---

## 📍 Where Content Comes From (Current State)

```
┌─────────────────────────────────────────────────────────┐
│                     CONTACT DETAIL VIEW                 │
├─────────────────────────────────────────────────────────┤
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
             │        │ sun/moon/    │       │
             │        │ rising       │       │
             │        └──────┬───────┘       │
             │               │               │
             │               └───────┬───────┘
             │                       ▼
             │              ┌────────────────┐
             │              │ OracleContent  │
             │              │ (personalized) │
             │              └────────┬───────┘
             │                       │
             │                       ▼
             │              ┌────────────────┐
             │              │   SUPABASE     │
             │              │   (cache)      │
             │              └────────────────┘
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
| "Are Aries and Leo compatible?" | **Static base** - 88% (could enhance with AI) |
| "What's this week's horoscope for Aries?" | **Weekly Global** - Same for all Aries |
| "What's Kate's (Aquarius ☀️ Sagittarius 🌙) reading?" | **Personalized** - Unique to her chart |
| "What's Kate's lucky number this week?" | **Personalized** - Generated by AI |

---

## 🚀 Future Improvements

1. **Weekly Global Horoscopes** - Run scheduled job to generate 12 sign horoscopes every Monday
2. **AI Compatibility** - Wire up `GeminiService.generateCompatibilityReading()` in the UI
3. **Synastry** - Use AstrologyAPI's synastry endpoint for detailed chart comparison
4. **Push Notifications** - "Your weekly reading is ready!"
5. **Birth Time Prompts** - Ask users for birth time to improve Rising sign accuracy
