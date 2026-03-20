# Auth & Onboarding Flow — Design Spec
Date: 2026-03-20

## Overview
The DataGigs iOS app needs a landing screen, unauthenticated gig browsing, and a full auth flow (Apple Sign In + Email OTP). All API calls go through `datagigbackend`. The iOS app never calls the website or Supabase directly.

## Decisions Made
- **Role**: iOS app is data collectors only — all sign-ups create `user` role. No role selector.
- **Email auth**: OTP 6-digit code (not magic link) — user stays in the app, no deep link needed.
- **Google Sign In**: Not included in v1.
- **Custom URL scheme**: Not needed for v1. Can be added additively later (~2h of work).
- **Backend as gateway**: All GET and POST operations from iOS go through `datagigbackend`.

## Navigation Architecture
```
AuthRouter (@Observable @MainActor)
  ├── session == nil → LandingView
  │     ├── Browse Gigs → GigListView (no auth)
  │     └── Sign Up / Sign In → AuthView (sheet)
  │           ├── Sign Up tab
  │           │     ├── Continue with Apple → [inline loading] → MainAppView
  │           │     ├── Continue with Email → EmailEntryView → OTPEntryView → MainAppView
  │           │     └── Already a member? → Log In tab
  │           └── Log In tab (same buttons)
  └── session != nil → MainAppView
```

## Screens

### LandingView
- Full-screen with tagline "DataGigs: Earn money doing the things you love"
- Two buttons: "Browse Gigs" and "Sign Up / Sign In"

### GigListView
- Calls `GET /gigs` (no auth)
- Shows list: title, company, activity type, payout range (min_rate_cents–max_rate_cents in dollars), device types
- Tap → GigDetailView
- "Apply" button prompts sign up if unauthenticated

### AuthView
- Segmented Sign Up / Log In control
- Both tabs: "Continue with Apple" + "Continue with Email"
- Sign Up only: "Already a member? Log in" link

### EmailEntryView
- Single email text field
- "Send Code" button → calls `POST /auth/otp/send`
- On success → OTPEntryView

### OTPEntryView
- 6 individual digit input boxes
- "Verify" button → calls `POST /auth/otp/verify`
- "Resend code" link
- On success → saves tokens to Keychain, updates AuthRouter.session → MainAppView

### Apple Sign In
- No separate screen — handled inline on AuthView button tap
- Uses `ASAuthorizationController` + `ASAuthorizationAppleIDProvider` (AuthenticationServices)
- On credential received → calls `POST /auth/apple` → saves tokens → MainAppView

## Session Management
- `access_token` + `refresh_token` stored in Keychain (never UserDefaults)
- On app launch: load from Keychain → if expired call `POST /auth/refresh` → if fails clear + show Landing
- `AuthRouter` is the single source of truth, injected via `@Environment`

## Backend Endpoints Required (datagigbackend)
| Method | Path | Purpose |
|---|---|---|
| POST | /auth/otp/send | Send 6-digit OTP via Supabase |
| POST | /auth/otp/verify | Verify OTP, return JWT session |
| POST | /auth/apple | Exchange Apple identity token for session |
| POST | /auth/refresh | Refresh expired access token |
| GET | /gigs | List open gigs |
| GET | /gigs/{id} | Gig detail with labels |

## User Record Creation
On first sign-in (any method), backend checks if `users` row exists. If not:
- Inserts into `users` (id, email, role='user')
- Inserts into `user_profiles` (user_id, display_name from Apple name or email prefix)

## File Structure (iOS)
```
Auth/
  AuthRouter.swift          — @Observable session state
  AuthView.swift            — Sign Up / Log In tabs
  EmailEntryView.swift      — Email input
  OTPEntryView.swift        — 6-digit code entry
  AppleSignInHandler.swift  — ASAuthorizationController wrapper
Gigs/
  GigListView.swift         — Unauthenticated gig browser
  GigDetailView.swift       — Single gig detail
  GigListViewModel.swift    — Fetch + state
Models/
  Session.swift             — access_token, refresh_token, user_id
  Gig.swift                 — Gig + GigLabel + GigDeviceRequirement
Services/
  APIClient.swift           — URLSession wrapper, base URL, auth header injection
  KeychainService.swift     — Store/load/delete tokens
LandingView.swift
```
