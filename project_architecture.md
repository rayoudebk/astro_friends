🌟 Astrology MVP Architecture (Supabase + AstrologyAPI + Gemini 3, GDPR‑Compliant)
This document defines the complete, GDPR‑safe architecture for an astrology‑powered mobile app using:

Supabase for backend + storage

AstrologyAPI (Growth Plan) as the astrology engine

Gemini 3 as the AI interpretation layer

Client‑side only PII processing (no sensitive data stored in Supabase)

Use this as a reference for implementing services, endpoints, schemas, and prompts.

0. 🔐 GDPR‑Compliant Principles
To comply with GDPR while doing astrology:

❌ Do NOT store:

name

birthdate

birth time

birthplace

lat/lon

any raw PII sent to AstrologyAPI

✔ Store ONLY derived, non‑identifying astrology data:

sun_sign

moon_sign

rising_sign

element (fire/earth/air/water)

modality (cardinal/fixed/mutable)

weekly horoscope JSON (AI-generated)

compatibility JSON (AI-generated)

This data is NOT personal data and cannot identify a user.

1. 🧱 Supabase Database Schema (GDPR‑safe)
Below are the only tables you need.
No PII stored.

Table: user_astro_profile
Derived natal data computed client-side.

id (uuid) PK
user_id (uuid)
sun_sign (text)
moon_sign (text)
rising_sign (text)
element (text)        // fire / earth / air / water
modality (text)       // cardinal / fixed / mutable
raw (jsonb)           // optional: cleaned astro summary, no PII
created_at (timestamp)


Table: weekly_sky
Global weekly sky context.

id (uuid)
week_start (date)
moon_phase (text)
transits (jsonb)      // list of notable aspects
created_at (timestamp)


Table: weekly_horoscopes
Final weekly reading per user.

id (uuid)
user_id (uuid)
week_start (date)
json (jsonb)          // Gemini horoscope schema
created_at (timestamp)


Table: compatibility_cache
Compatibility output between two users.

id (uuid)
user_a (uuid)
user_b (uuid)
base_score (int)       // from AstrologyAPI sign compatibility
synastry (jsonb)       // simplified aspects, no PII
weekly_context (jsonb) // transit-based adjustments
ai_output (jsonb)      // Gemini final text
week_start (date)
created_at (timestamp)

2. 🔭 AstrologyAPI Endpoints Needed (Growth Plan)
We use 6 endpoints from AstrologyAPI.

All API calls with sensitive birth info MUST be done on the client, never on Supabase (to avoid logs + PII storage).

2.1 Natal Chart Calculation
📍 planets/tropical
→ Client uses this to compute Sun, Moon, Rising.

Store only:

sun_sign

moon_sign

rising_sign

element

modality

optional raw astro summary (no birth data)

2.2 Daily Moon Phase
📍 moon_phase_report
→ Run daily, store in weekly_sky.

2.3 Weekly Global Transits
📍 tropical_transits/weekly
→ Weekly sky for all users.

Used in:

weekly horoscopes

compatibility

2.4 Personal Weekly Transits (Optional but strong)
📍 natal_transits/weekly
→ This uses birthdata → must be run client-side.

Client sends ONLY derived results to Supabase.

2.5 Base Sign Compatibility
📍 zodiac_compatibility/:signA/:signB
→ Gives % score + long explanation.

This is safe (no PII), server-side OK.

2.6 Synastry (Chart-Based Compatibility)
📍 synastry_horoscope
→ Requires both birth charts → must be run client-side.

Then client sends a stripped-down, anonymous synastry summary to Supabase.

Example sanitized synastry data:

{
  "personA": { "sun": "aries", "moon": "libra", "rising": "leo" },
  "personB": { "sun": "taurus", "moon": "cancer", "rising": "scorpio" },
  "notableAspects": [
    "Sun–Moon harmony",
    "Venus–Mars tension"
  ]
}
3. 🤖 Gemini 3 AI Layer (Weekly + Compatibility)
Gemini receives NO PII — only derived astro data.

3.1 Weekly Horoscope Prompt Inputs
{
  "sign": "aries",
  "natalSummary": { "sun": "aries", "moon": "libra", "rising": "leo" },
  "moonPhase": "Waxing Gibbous",
  "weeklySky": { "transits": [...] },
  "personalTransits": { "keyTransits": [...] }
}
Gemini output is stored in weekly_horoscopes.json.

3.2 Compatibility Prompt Inputs
{
  "personA": { "natal": { ... }, "weeklyMood": "Energetic" },
  "personB": { "natal": { ... }, "weeklyMood": "Reflective" },
  "zodiacCompatibility": { "baseScore": 84, "report": "..." },
  "synastry": { "notableAspects": [...] },
  "weeklySky": { "transits": [...] }
}
Gemini returns a structured JSON compatibility report.

Stored in compatibility_cache.ai_output.

4. 📅 Scheduled Jobs (Supabase Cron)
Task	Runs	Notes
Fetch moon phase	Daily	Store in weekly_sky
Fetch weekly sky	Weekly	Monday morning
Trigger weekly horoscopes	Weekly	Use Gemini
Trigger weekly compatibility (optional)	Weekly	Use Gemini
All personal data operations stay client-side.

5. 🔗 End-to-End Flow (GDPR-safe)
User onboarding (client-side only)
User enters birthdate, time, city

Client converts city → lat/lon

Client calls AstrologyAPI → gets natal chart

Client extracts Sun/Moon/Rising

Client sends only derived astro summary to Supabase
(no birthdate/time/location)

Weekly horoscopes
Server fetches weekly sky

Server fetches moon phase

Server builds weekly context

Server calls Gemini with ONLY derived astro fields

Result saved in weekly_horoscopes

Compatibility between two users
Client runs synastry for both users (AstrologyAPI client-side)

Client strips down PII → sends only Sun/Moon/Rising + aspects to Supabase

Supabase fetches zodiac_compatibility score

Server calls Gemini with sanitized data

Result cached in compatibility_cache

6. 🎯 Summary
This architecture ensures:

GDPR compliant (no PII stored)

Supabase stays clean

AstrologyAPI does raw calculations

Gemini produces all final text

Cohesive, branded, weekly-updating astrology experience

Social features (compatibility) without storing sensitive info