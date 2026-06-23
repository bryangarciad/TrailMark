# TrailMark 🧭

**A personal adventure-journal app for iPhone & Apple Watch.** TrailMark records
*where you went, how you moved, how your body responded, and what you captured*
along the way — and keeps it in sync between your wrist and your pocket.

It's also a complete, buildable teaching project: one app, one shared codebase,
built across three short courses (iOS → watchOS → intermediate watchOS). The
full courseware lives in [`Docs/`](Docs/index.html).

> **Platforms:** iOS & watchOS · **Built with:** Swift, SwiftUI, Swift Package Manager · **Tooling:** Xcode 26 (iOS/watchOS 26 app targets)

---

## ✨ What it does

TrailMark is two apps sharing one engine:

### 📱 iPhone app
- **Today dashboard** — your steps, walking/running distance, and active energy for the day, read live from HealthKit with graceful empty/denied states.
- **Field journal** — record **voice and video memos**, saved with metadata (date, duration, location). Browse them in a list with video thumbnails and durations, play them back, and delete (which also removes the file from disk).
- **Recovery view** — write a workout to HealthKit (and see it appear in Apple's Health app), read **last night's sleep**, and chart your **7-day active-energy trend** with Swift Charts.
- **Journeys** — record a **GPS route**, geotag the memos you capture along it, and view a unified **Journey detail** screen with the route polyline, memo pins, and activity stats on one MapKit map.

### ⌚️ Apple Watch app
- **Glanceable home** — today's headline metric and one quick action, readable in about two seconds (mirrors the phone's summary when connected).
- **Wrist voice memos** — record, save, list, and play back — reusing the exact same media engine as the phone.
- **Live vitals** — current **heart rate**, steps, and active energy, updating live on the wrist.
- **Motion** — cadence and activity type derived from **Core Motion** (pedometer, motion-activity, accelerometer).
- **Live workout** — start an **`HKWorkoutSession`** that keeps streaming heart rate, time, and energy while backgrounded, then saves a real `HKWorkout` to Health.

### 🔗 Across both devices
- **Wrist-to-pocket sync** over **WatchConnectivity** — a workout or memo recorded on the watch appears on the phone, with the right transfer type chosen per payload (live state vs. queued record vs. file).
- **Complication** (WidgetKit) — today's steps on the watch face and in the Smart Stack, shared from the app via an App Group.

---

## 🏛️ Architecture — one shared core, two platforms

The whole project is organized to **never write the same logic twice**. All
models and managers live in a single local Swift package, **`TrailmarkCore`**,
which *both* app targets import. Views never touch HealthKit, CoreLocation, etc.
directly — they read published state from a manager in the package.

```
┌─────────────────┐     ┌──────────────────────┐     ┌──────────────────┐
│   iOS app        │     │  TrailmarkCore        │     │  watchOS app      │
│  (SwiftUI views) │ ──▶ │  (models + managers)  │ ◀── │  (SwiftUI views)  │
└─────────────────┘     └──────────────────────┘     └──────────────────┘
                          ▲ shared by both, written once
```

### Inside `TrailmarkCore`

| Area | Type(s) | Responsibility |
|---|---|---|
| **Models** | `ActivitySummary`, `MediaMemo`, `RouteTrack` / `TrackPoint`, `Journey`, `WorkoutRecord`, `SleepSummary`, `EnergyTrendPoint`, `LiveVitals` | Plain, `Codable`/`Sendable` value types — no framework imports |
| **Health** | `HealthKitManager` | Auth, read totals (`HKStatisticsQuery`), sleep, 7-day trend (`HKStatisticsCollectionQuery`), write workouts (`HKWorkoutBuilder`), live vitals (`HKAnchoredObjectQuery`) |
| **Media** | `MediaStore`, `AudioRecorder`, `AudioPlayer` | Persist/list/delete media + metadata index, record & play audio, video thumbnails (iOS) |
| **Location** | `LocationManager` | When-in-use auth, route recording, current coordinate for geotagging |
| **Motion** | `MotionManager` | Pedometer cadence, motion-activity classification, accelerometer magnitude |
| **Connectivity** | `ConnectivityManager` | `WCSession` wrapper — applicationContext / userInfo / file transfer |
| **Workout** | `WorkoutSessionManager` *(watchOS only)* | `HKWorkoutSession` + `HKLiveWorkoutBuilder` live session |
| **Persistence** | `JourneyStore` | Save/load journeys (JSON) |
| **Support** | `Coding` | Shared JSON coders |

Managers use the **Observation framework** (`@Observable`) and are `@MainActor`;
HealthKit/CoreLocation callbacks hop back to the main actor before publishing.

---

## 🧰 Tech stack

Swift · SwiftUI · Observation (`@Observable`) · Swift Concurrency (`async/await`)
· **HealthKit** · **AVFoundation** / AVKit · **CoreLocation** · **MapKit** ·
**Core Motion** · **WatchConnectivity** · **WidgetKit** · **Swift Charts** ·
Swift Package Manager.

---

## 📁 Project structure

```
TrailMark/
├── Docs/                              # Courseware website (open Docs/index.html)
│   ├── index.html                     # Hub
│   ├── trailmark-curriculum.html      # The 12-session arc
│   ├── setup-guide.html               # Build the project from scratch + deploy
│   ├── teaching-guide.html            # Class-by-class build guide
│   ├── concepts.html                  # Concept notes (the "why")
│   ├── assignments.html               # Graded builds + rubrics
│   ├── final-reports.html             # Course capstones
│   ├── class-overviews.html           # Canvas-embeddable schedule + grading
│   └── welcome-email.{html,txt}       # Student welcome email
├── TrailMark/
│   ├── TrailMark.xcodeproj            # iOS + watchOS app targets
│   ├── TrailmarkCore/                 # 🟦 Shared Swift package (the engine)
│   │   └── Sources/TrailmarkCore/{Models,Health,Media,Location,Motion,Connectivity,Workout,Persistence,Support}
│   ├── TrailMark/                     # 📱 iOS app (Today, Journal, Recovery, Journeys)
│   ├── TrailMarkCompanion Watch App/  # ⌚️ watchOS app (Home, Memo, Vitals, Motion, Workout)
│   └── TrailMarkComplication/         # 🧩 Complication source (add target — see setup guide)
└── .github/workflows/deploy-pages.yml # Publishes Docs/ to GitHub Pages
```

---

## 🚀 Getting started

### Requirements
- A **Mac** with **Xcode 26** or later.
- An **Apple ID** (free is enough for the Simulator + 7-day device testing).
- For the wrist-only features (heart rate, Core Motion, live workouts, true sync): a physical **iPhone + paired Apple Watch** — sensors can't be simulated.

### Build & run
```bash
# Open the project
open TrailMark/TrailMark.xcodeproj
```
- Select the **TrailMark** scheme → an iPhone simulator → **⌘R**.
- Select the **TrailMarkCompanion Watch App** scheme → a paired Apple Watch simulator → **⌘R**.

`TrailmarkCore` is already linked to both targets. HealthKit shows no data until
you add samples in the Simulator's **Health** app; use **Features → Location →
Freeway Drive** to feed the route recorder.

> First-time project setup, permissions (Info.plist usage strings), capabilities
> (HealthKit, Workout Processing, App Groups), the complication target, and full
> device-deployment steps are documented in **[Docs/setup-guide.html](Docs/setup-guide.html)**.

### Command-line build (sanity check)
```bash
xcodebuild build -project TrailMark/TrailMark.xcodeproj -scheme TrailMark \
  -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild build -project TrailMark/TrailMark.xcodeproj -scheme "TrailMarkCompanion Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'
```

---

## 🧪 Simulator vs. device

| Feature | Simulator | Notes |
|---|:--:|---|
| UI, navigation, charts, persistence | ✅ | Fully works |
| HealthKit reads (steps/sleep/energy) | ⚠️ | Only after you add sample data in the Health app |
| HealthKit write (save workout) | ✅ | Writes to the simulated Health store |
| Voice memos | ✅ | Uses the Mac microphone |
| Video memos | ⚠️ | No camera → falls back to the photo library |
| Location / route | ✅ | Use *Freeway Drive* to simulate movement |
| Live heart rate / Core Motion | ❌ | Needs a real device |
| Live workout session | ⚠️ | Starts/saves, but won't stream metrics |
| WatchConnectivity sync | ✅ | Works across a paired iPhone+Watch sim pair |

---

## 🎓 Course context

TrailMark is built as a 12-session program across three courses:

1. **iOS — Foundations & the Shared Core**
2. **watchOS — Designing & Building for the Wrist**
3. **Intermediate watchOS — Live, Connected & Performant**

Course 1 builds the iPhone app *and* the shared package; Course 2 adds the watch
target that simply *imports* it; Course 3 takes on the genuinely watch-hard
topics (live sessions, sync, power tuning, complications). The complete
curriculum, setup guide, concept notes, assignments, and final reports are in
**[`Docs/`](Docs/index.html)** (also publishable to GitHub Pages).

---

## ✅ Status

- `TrailmarkCore` builds for **both iOS and watchOS**.
- Both app targets **build on the Simulator**.
- The package's pure-logic **unit tests pass**.
- The complication ships as source; its **Widget Extension target is created from Xcode's template** (see the setup guide).

---

*TrailMark is a working name — rename it to make it your own.*
