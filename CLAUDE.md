# CLAUDE.md — datagigios

This file provides guidance to Claude Code when working in this repository.

---

## Project Goal

**datagigios** is the iOS data-collection app for the DataGigs platform. Data collectors browse gigs, sign up/sign in, enter their assignment code, record sensor data, and submit recordings. The app communicates **exclusively with datagigbackend** — it never calls the website or Supabase directly. The backend is the sole API gateway.

---

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.

---

## Core Instructions

- Target **iOS 26.0** or later.
- **Swift 6.2** or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.

---

## Swift Instructions

- `@Observable` classes must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless unavoidable.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods (e.g. `replacing("hello", with: "world")` over `replacingOccurrences(of:with:)`).
- Prefer modern Foundation API: `URL.documentsDirectory`, `appending(path:)`, etc.
- Never use C-style number formatting (`String(format: "%.2f", ...)`). Use `FormatStyle` instead.
- Prefer static member lookup (`.circle` not `Circle()`, `.borderedProminent` not `BorderedProminentButtonStyle()`).
- Never use GCD (`DispatchQueue.main.async`). Use modern Swift concurrency instead.
- Filter user-input text with `localizedStandardContains()`, not `contains()`.
- Avoid force unwraps and force `try` unless unrecoverable.
- Never use legacy `Formatter` subclasses (`DateFormatter`, `NumberFormatter`, etc.). Use the modern `FormatStyle` API (`myDate.formatted(date:time:)`, `Date(inputString, strategy: .iso8601)`, `myNumber.formatted(.number)`).

---

## SwiftUI Instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes.
- Never use the `onChange()` modifier in its 1-parameter variant.
- Never use `onTapGesture()` for simple taps; use `Button` instead.
- Never use `Task.sleep(nanoseconds:)`; use `Task.sleep(for:)`.
- Never use `UIScreen.main.bounds`.
- Do not break views into computed properties; use new `View` structs.
- Do not force specific font sizes; use Dynamic Type.
- Use `navigationDestination(for:)` and `NavigationStack` (not `NavigationView`).
- Button with image: always include text (`Button("Label", systemImage: "plus", action: ...)`).
- Prefer `ImageRenderer` over `UIGraphicsImageRenderer`.
- Use `bold()` not `fontWeight(.bold)` unless there's a specific reason.
- Avoid `GeometryReader` when `containerRelativeFrame()` or `visualEffect()` suffice.
- `ForEach` over enumerated: use `ForEach(x.enumerated(), id: \.element.id)` (no `Array()` wrap).
- Hide scroll indicators with `.scrollIndicators(.hidden)`.
- Use newest ScrollView APIs (`ScrollPosition`, `defaultScrollAnchor`); avoid `ScrollViewReader`.
- Place view logic into view models so it can be tested.
- Avoid `AnyView` unless absolutely required.
- Avoid hard-coded padding/spacing values unless requested.
- Avoid UIKit colors in SwiftUI code.

---

## Project Structure

```
datagigios/
├── datagigios/                   ← Xcode project root
│   ├── datagigios/               ← App source (feature-based folders)
│   │   ├── datagigiosApp.swift
│   │   ├── ContentView.swift
│   │   ├── Auth/                 ← Apple Sign In, Email OTP, AuthRouter
│   │   ├── Dashboard/            ← DashboardView + DashboardViewModel (hub screen)
│   │   ├── Gigs/                 ← GigListView, GigDetailView, GigListViewModel, GigDetailViewModel
│   │   ├── Apply/                ← ApplyView + ApplyViewModel
│   │   ├── Applications/         ← ApplicationsListView, ApplicationDetailView, ApplicationsViewModel
│   │   ├── Recording/            ← Sensor data collection, label selection
│   │   ├── Submissions/          ← Upload + confirm flow
│   │   ├── Models/               ← Data models (Gig, Application, Session, UserProfile)
│   │   ├── Services/             ← APIClient, KeychainService
│   │   └── Assets.xcassets
│   ├── datagigiosTests/
│   └── datagigiosUITests/
```

- Use feature-based folder structure.
- One type per Swift file.
- Write unit tests for core logic (networking, sensor processing, data models).
- Only write UI tests if unit tests are not possible.
- Never commit secrets or API keys to the repository. Use `Config.xcconfig` or environment injection.

---

## Backend & API Contracts

**All API calls go through `datagigbackend`.** Never call the website or Supabase directly from the iOS app. Store `BACKEND_BASE_URL` in a config file — never hardcode it.

- Dev backend URL: `http://localhost:8000`
- Authenticated requests include header: `Authorization: Bearer {access_token}`

---

### Auth Flow

The iOS app is for **data collectors only** — all sign-ups create a `user` role account.

#### Navigation structure
```
App root → AuthRouter (checks persisted session in Keychain on launch)
  ├── No session → LandingView
  │     ├── Browse Gigs → GigListView → GigDetailView
  │     │     └── "Sign in to Apply" → AuthView sheet
  │     └── Sign Up / Sign In → AuthView sheet
  │           ├── Continue with Apple (inline)
  │           └── Continue with Email → EmailEntryView → OTPEntryView
  └── Has session → DashboardView  (hub screen, no tab bar)
        ├── Browse Gigs card → GigListView → GigDetailView
        │     └── "Apply to Gig" → ApplyView (full screen push)
        │           └── success → back to GigDetailView, button shows "Applied ✓"
        └── My Applications card → ApplicationsListView
              └── tap row → ApplicationDetailView (accepted applications only)
                    ├── "Start Collecting Data" button → GigCollectionView
                    │     └── tap label row → "Begin <Label>" sheet → Start button
                    │           └── 10-sec countdown overlay (green glow, Cancel button)
                    │                 └── LabelRecordingView (circular timer, REC badge, no live data)
                    │                       └── recording ends → RecordingSummaryView
                    │                             ├── Done   → back to GigCollectionView
                    │                             ├── Submit → (placeholder, upload TBD)
                    │                             └── Delete → back to GigCollectionView
                    └── "View Recordings" button → GigRecordingsLibraryView
                          ├── swipe trailing → Delete (single, with confirmation)
                          ├── swipe leading → Submit (single, placeholder)
                          └── Select mode → Submit (N) / Delete (N) bottom bar
```

AuthView is a single unified screen (no Sign Up / Log In tabs) — both flows are identical since Supabase creates the user automatically on first sign-in.

#### Session storage
- Store `access_token` + `refresh_token` in **Keychain** (never UserDefaults).
- `AuthRouter` is `@Observable @MainActor` — holds `session: Session?`, injected as `@Environment`.
- On launch, load session from Keychain. If expired, call `POST /auth/refresh`. If refresh fails, clear and show LandingView.

#### POST /auth/otp/send
```
Body:     { "email": "user@example.com" }
Response: { "message": "OTP sent" }
```
Supabase sends a 6-digit code to the email. Navigate to OTPEntryView on success.

#### POST /auth/otp/verify
```
Body:     { "email": "user@example.com", "token": "482917" }
Response: { "access_token": "...", "refresh_token": "...", "user_id": "uuid" }
```
Save both tokens to Keychain. Set `AuthRouter.session`. Navigate to MainAppView.

#### POST /auth/apple
```
Body:     { "identity_token": "<Apple JWT from ASAuthorizationAppleIDCredential>" }
Response: { "access_token": "...", "refresh_token": "...", "user_id": "uuid" }
```
Use `ASAuthorizationController` with `ASAuthorizationAppleIDProvider` (AuthenticationServices framework — no third-party SDK). Extract `identityToken` from credential, send to backend.

#### POST /auth/refresh
```
Body:     { "refresh_token": "..." }
Response: { "access_token": "...", "refresh_token": "..." }
```

---

### Gigs API

#### GET /gigs
No auth required.
Query params: `page` (default 1), `limit` (default 20)
```json
Response: [
  {
    "id": "uuid",
    "title": "Horse riding sensor data",
    "description": "...",
    "activity_type": "horse_riding",
    "status": "open",
    "total_slots": 20,
    "filled_slots": 4,
    "application_deadline": "2026-04-01T00:00:00Z",
    "data_deadline": "2026-04-15T00:00:00Z",
    "company_name": "Equine Research Co",
    "min_rate_cents": 500,
    "max_rate_cents": 1000,
    "device_types": ["generic_ios", "apple_watch"]
  }
]
```

#### GET /gigs/{id}
No auth required.
```json
Response: {
  "id": "uuid", "title": "...", "description": "...", "activity_type": "...",
  "status": "open", "total_slots": 20, "filled_slots": 4,
  "application_deadline": "...", "data_deadline": "...", "company_name": "...",
  "labels": [
    { "id": "uuid", "label_name": "walking on horse", "description": "...",
      "duration_seconds": 120, "rate_cents": 500, "quantity_needed": 20, "quantity_fulfilled": 4 }
  ],
  "device_types": ["generic_ios"]
}
```

---

### Applications API (authenticated)

All calls require `Authorization: Bearer {access_token}` header.

#### POST /applications
```json
Body:     { "gig_id": "uuid", "device_type": "generic_ios|apple_watch|generic_android", "note_from_user": "optional" }
Response: { "id": "uuid", "gig_id": "uuid", "status": "pending", "applied_at": "ISO8601" }
```

#### GET /applications
```json
Response: [
  { "id": "uuid", "gig_id": "uuid", "gig_title": "...", "status": "pending|accepted|denied|withdrawn",
    "device_type": "generic_ios", "assignment_code": "ABC123DEF456" | null,
    "applied_at": "ISO8601", "note_from_company": "..." | null }
]
```
Fetch once after sign-in. Cache in `ApplicationsViewModel`. Used to determine "Applied ✓" state on GigDetailView.

#### GET /applications/{id}
```json
Response: {
  ...same as list item,
  "note_from_user": "..." | null,
  "gig_detail": {
    "title": "...", "description": "...", "activity_type": "...", "data_deadline": "ISO8601" | null,
    "company_name": "...",
    "labels": [ { "id": "uuid", "label_name": "...", "description": "..." | null, "duration_seconds": 120, "rate_cents": 500 } ]
  }
}
```
`company_name` and label `description` were added to support GigCollectionView and GigRecordingsLibraryView headers.

#### GET /profile
```json
Response: { "display_name": "Natalya", "credits_balance_cents": 2450 }
```
Used by DashboardView for earnings display. Always divide credits_balance_cents by 100 and display as `.currency(code: "USD")`.

---

### Submission Flow (authenticated)

All submission calls require `Authorization: Bearer {access_token}` header.

#### Step 1 — Get Signed Upload URL
```
POST /submissions/upload-url
Body: { "assignmentCode": "ABC123DEF456", "gigLabelId": "uuid", "deviceType": "generic_ios", "fileExtension": "csv" }
Response: { "signedUrl": "https://...", "token": "...", "storagePath": "submissions/...", "applicationId": "uuid" }
```

#### Step 2 — Upload File
PUT sensor CSV directly to `signedUrl` (Supabase Storage — this is the only direct Supabase call, via the signed URL).

#### Step 3 — Confirm Submission
```
POST /submissions/confirm
Body: { "applicationId": "uuid", "gigLabelId": "uuid", "assignmentCode": "ABC123DEF456",
        "storagePath": "submissions/...", "fileSizeBytes": 12345, "durationSeconds": 120,
        "deviceType": "generic_ios", "deviceMetadata": { "model": "iPhone 16", "osVersion": "26.0" } }
Response: { "submissionId": "uuid" }
```

---

### Assignment Code
- 12-character uppercase alphanumeric string (e.g. `ABC123DEF456`).
- Received via email after application is accepted.
- Used in all submission API calls as the authorization key.

---

## Recording Flow (Data Collection)

### Screens
- **GigCollectionView** — label list for an accepted application. Header: `<GigTitle> - <CompanyName>`. Labels shown with green left accent bar, duration, rate, description (if any), chevron. Hint at bottom: "Tap any label to begin". Entry point from ApplicationDetailView "Start Collecting Data" button.
- **LabelRecordingView** — full-screen recording. Label name above red REC badge. Circular red arc timer counts down from `duration_seconds`. No live sensor data shown. "Stop Early" button. Auto-ends when timer reaches zero.
- **RecordingSummaryView** — shown after recording ends. Displays: label name, recorded duration, frame count. Buttons: **Done** (back to GigCollectionView), **Submit** (placeholder — upload TBD), **Delete** (discard + back).
- **GigRecordingsLibraryView** — all locally saved recordings for this gig. Title: `<GigTitle> - <CompanyName>`. Flat list ordered newest-first. Each row: timestamp + blue label tag + frame count. Swipe trailing to Delete (with confirmation alert), swipe leading to Submit (placeholder). "Select" button top-right for bulk mode → bottom bar with Submit (N) / Delete (N).

### Countdown Overlay
- 10-second full-screen overlay before recording begins.
- Green glowing number fills screen, counts down 10→0.
- Label name and rate shown below number.
- **Cancel** button lets user abort before recording starts.

### Permissions
- Request location + motion permissions when user taps **"Start Collecting Data"** on ApplicationDetailView.
- If either permission is denied: show an info screen explaining that phone sensor data requires these permissions and directing user to Settings. Do not proceed to GigCollectionView until granted.

### Multiple Recordings Per Label
- A label can be recorded unlimited times (up to `quantity_needed` submissions per the company's gig config).
- All recordings are stored locally — user manages them from GigRecordingsLibraryView.
- **DB note**: the `submissions` table must support multiple rows per (application_id, gig_label_id). The `quantity_needed` / `quantity_fulfilled` fields on `gig_labels` track how many total submissions are still needed across all users.

### SensorManager Architecture
- `SensorManager` is `@Observable @MainActor`, owned by `GigCollectionViewModel`.
- Created when user enters GigCollectionView, torn down on exit. Sensors only run during active recording.
- Recordings saved per-gig: `GigRecordings/<assignmentCode>/<labelId>/<uuid>.json`
- Each `GigRecordingSession` includes: `gigId`, `gigTitle`, `companyName`, `labelId`, `labelName`, `assignmentCode`, `startTime`, `frames: [SensorFrame]`.

### Sample Rate
- **Variable** — `SensorManager` accepts a `sampleRate: SampleRate` parameter.
- Two modes:
  - `.standard` → 10 Hz (0.1s interval) — walking, slow activities
  - `.high` → 50 Hz (0.02s interval) — jumping, trotting, dynamic activities
- `deviceMotionUpdateInterval` and `magnetometerUpdateInterval` are set from this value at recording start.
- CMPedometer runs continuously regardless of sample rate (it has its own internal cadence).
- Default is `.standard`. Future: gig could specify preferred rate in its metadata.

### Sensor Data Collected (per frame, at configured sample rate)
```
timestamp, label_name,
pitch, roll, yaw,
latitude, longitude, altitude,
pressure, heading, speed,
accel_x, accel_y, accel_z,       // user acceleration (gravity removed)
gforce_x, gforce_y, gforce_z,    // total acceleration (user + gravity)
gravity_x, gravity_y, gravity_z, // gravity vector (for freefall/jump detection)
gyro_x, gyro_y, gyro_z,
mag_x, mag_y, mag_z,
cadence                           // steps per second from CMPedometer (nil if unavailable)
```
CSV header matches the above field order.

**Notes:**
- `altitude` (relative, from CMAltimeter) + `gravity_x/y/z` enable jump height detection via hang time.
- `cadence` comes from `CMPedometer.startUpdates` — updated ~1/sec by the OS, same value stamped on all frames within that second. Will be `nil` / empty for non-pedestrian activities.
- CMPedometer requires motion permission (same `NSMotionUsageDescription` already needed for CoreMotion).

## Sensor Data Collection (legacy note)

- Collect sensor data using **CoreMotion** (accelerometer, gyroscope, etc.) and/or **HealthKit** as appropriate for each gig's `activity_type`.
- The `duration_seconds` for each label is specified by the gig (`gig_labels.duration_seconds`).
- Device types: `generic_ios` (iPhone sensors) and `apple_watch` (Watch sensors).
- Save sensor samples to a **CSV file** in the app's documents directory before uploading.
- Include device metadata in the confirm call: device model, OS version, sensor sample rate, etc.

---

## Gig & Label Data Model (read from API)

```swift
// Gig (from GET /api/gigs/{id})
struct Gig {
    let id: String
    let title: String
    let description: String
    let activityType: String
    let status: String          // "open" | "paused" | "completed" | "cancelled"
    let totalSlots: Int
    let filledSlots: Int
    let applicationDeadline: Date?
    let dataDeadline: Date?
    let labels: [GigLabel]
    let deviceRequirements: [GigDeviceRequirement]
}

struct GigLabel {
    let id: String
    let labelName: String       // e.g. "walking on horse"
    let description: String?
    let durationSeconds: Int    // how long to record
    let rateCents: Int          // payout per accepted submission
    let quantityNeeded: Int
    let quantityFulfilled: Int
}

struct GigDeviceRequirement {
    let deviceType: String      // "apple_watch" | "generic_ios" | "generic_android"
}
```

---

## Important Rules

- **No git commits** — only the human makes commits.
- **Credentials alert** — if any code, config, or file you write or encounter contains credentials, passwords, API keys, or tokens, immediately alert the user and add a `// credentials` comment on the line immediately after.
- **No third-party dependencies** without asking first (this includes Supabase Swift SDK — use URLSession for API calls unless instructed otherwise).
- Keep API base URL and Supabase keys in a config/secrets file, never hardcoded in source.
- Monetary values from the API are in **cents** — always display as dollars (divide by 100).
- When the master agent (orchestrator) adds new API endpoints or changes the data model, this CLAUDE.md will be updated — always re-read it before making networking changes.
- If Xcode MCP tools are available (`BuildProject`, `GetBuildLog`, `RenderPreview`, etc.), prefer them over generic file tools.
