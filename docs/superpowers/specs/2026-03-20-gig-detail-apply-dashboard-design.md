# Gig Detail, Apply Flow & User Dashboard — Design Spec
Date: 2026-03-20

## Overview
Adds gig detail view, application submission, and an authenticated user dashboard to the DataGigs iOS app. All API calls go through `datagigbackend`.

## Navigation Flow

```
App root
  ├── No session → LandingView
  │     └── GigListView → GigDetailView
  │           └── "Sign in to Apply" → AuthView sheet
  └── Has session → DashboardView  (replaces MainAppView placeholder)
        ├── Browse Gigs card → GigListView → GigDetailView
        │     └── "Apply to Gig" → ApplyView (full screen)
        │           └── success → back to GigDetailView, button shows "Applied ✓"
        └── My Applications card → ApplicationsListView
              └── tap row → ApplicationDetailView
```

## Screens

### DashboardView
Replaces `MainAppView` placeholder. Shows:
- Stats row: earnings (credits_balance_cents ÷ 100 as USD), active gig count, pending count
- "Browse Gigs" card → navigates to GigListView
- "My Applications" card → navigates to ApplicationsListView
- Sign Out button (in navigation bar)
Fetches: `GET /profile` (credits, display name) + `GET /applications` (for counts)

### GigDetailView
Replaces stub in GigListView.swift. Shows:
- Title, company name, activity type, payout range
- Description
- Labels list: label name, duration, rate per label
- Device types accepted
- Sticky bottom button with 3 states:
  - Unauthenticated: "Sign in to Apply" → presents AuthView sheet
  - Authenticated, not applied: "Apply to Gig" → pushes ApplyView
  - Authenticated, already applied: "Applied ✓" (disabled)
- Applied state determined by checking cached applications list for matching gigId

### ApplyView
Full screen pushed onto nav stack. Shows:
- Gig title in nav bar
- Device type selector — segmented/chip picker, only shows device types the gig accepts
- Optional note text editor, max 500 chars, char count shown
- "Submit Application" button → POST /applications → on success pops back
- Loading state on submit button
- Error shown inline if submission fails

### ApplicationsListView
Full list of user's applications. Shows:
- Filter pills: All / Active / Pending / Denied
- Each row: gig title, device type icon, applied date, status badge
- Color coding: Active = green, Pending = yellow, Denied = red
- Tap row → ApplicationDetailView

### ApplicationDetailView
Shows:
- Status badge (Accepted / Pending / Denied)
- Assignment code card (only if accepted) — large monospace display, "Use this code when submitting recordings"
- Data deadline (if set and accepted)
- Gig labels + rates
- Company note (if provided)
- User's original note (if provided)

## Backend API Contracts

### POST /applications
Auth: Bearer token required
```json
Request:  { "gigId": "uuid", "deviceType": "generic_ios", "noteFromUser": "optional" }
Response: { "id": "uuid", "gigId": "uuid", "status": "pending", "appliedAt": "ISO8601" }
```
Validation: gig must be open, device type must be in gig's requirements, user must not have already applied.

### GET /applications
Auth: Bearer token required
```json
Response: [
  {
    "id": "uuid",
    "gigId": "uuid",
    "gigTitle": "Horse Riding Sensor Data",
    "status": "pending" | "accepted" | "denied" | "withdrawn",
    "deviceType": "generic_ios",
    "assignmentCode": "ABC123DEF456" | null,
    "appliedAt": "ISO8601",
    "noteFromCompany": "string" | null
  }
]
```

### GET /applications/{id}
Auth: Bearer token required
```json
Response: {
  ...same as list item,
  "noteFromUser": "string" | null,
  "gigDetail": {
    "title": "...", "description": "...", "activityType": "...",
    "dataDeadline": "ISO8601" | null,
    "labels": [ { "id", "labelName", "durationSeconds", "rateCents" } ]
  }
}
```

### GET /profile
Auth: Bearer token required
```json
Response: { "displayName": "Natalya", "creditsBalanceCents": 2450 }
```

## New iOS Files

```
Gigs/
  GigDetailView.swift         — replaces stub (moved out of GigListView.swift)
  GigDetailViewModel.swift    — fetches GET /gigs/{id}, checks applied state
Apply/
  ApplyView.swift             — full screen apply form
  ApplyViewModel.swift        — POST /applications, validation
Dashboard/
  DashboardView.swift         — hub screen replacing MainAppView
  DashboardViewModel.swift    — fetches /profile + /applications
Applications/
  ApplicationsListView.swift  — flat list with filter pills
  ApplicationDetailView.swift — single application detail
  ApplicationsViewModel.swift — fetches GET /applications, GET /applications/{id}
Models/
  Application.swift           — Application + ApplicationDetail models
```

## New Backend Files

```
app/routers/applications.py    — POST /applications, GET /applications, GET /applications/{id}
app/routers/profile.py         — GET /profile
app/models/applications.py     — Pydantic request/response models
app/services/applications_service.py  — DB queries for applications
app/services/profile_service.py       — DB query for user profile
```

## "Has User Applied?" Logic
iOS fetches `GET /applications` once after sign-in and stores in `ApplicationsViewModel`. `GigDetailViewModel` checks this list for a matching `gigId` — no extra per-gig call needed. List is refreshed on pull-to-refresh and after successful application submission.
