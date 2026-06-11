# Seizure Alert App — Project Overview

**SeizureAlert** is a clinical-grade Flutter app for people living with epilepsy and their emergency contact circles. It provides two core alert mechanisms — a one-tap SOS and a scheduled "Heads Up" check-in window — and automatically notifies contacts via Firebase Cloud Messaging when an alert fires or is missed.

---

## Problem Statement

People with epilepsy often seize alone. Standard ICE contacts help after an incident, but do nothing before or during one. This app closes that gap: users can signal distress instantly (SOS), or pre-announce that they are about to be alone and may need help if they go quiet (Heads Up). Their emergency circle gets a push notification automatically, with no user action required at the critical moment.

---

## Core Features

| Feature | Description |
|---|---|
| **SOS Alert** | One-tap emergency alert. Captures GPS location, logs a seizure entry, notifies all push-enabled contacts via FCM. Persists across app restarts via SharedPreferences. |
| **Heads Up** | Timed check-in window (30/60/120 min). User declares they are alone. Contacts are notified when the window is started, and again if the user fails to check in before it expires. |
| **Seizure Log** | Manual log of seizure events: date/time, duration, location, trigger, notes. Feeds the dashboard statistics. |
| **Contacts** | Priority-ordered list of emergency contacts. Each contact has SMS and/or push notification flags. Push-enabled contacts receive FCM notifications when alerts fire. |
| **Dashboard** | Shows days since last seizure, 7-day and monthly counts, and a 28-day activity grid (4 rows × 7 cols). |
| **Profile** | User medical info: blood type, seizure type, medications, emergency note. Also manages notification and location permissions. |
| **Onboarding** | Three-step flow for new users: name, first emergency contact, permissions. |

---

## Technical Architecture

- **Framework**: Flutter 3.10+ (Dart SDK ^3.10.7) — Android, iOS, Web
- **State Management**: GetX 4.7 — `GetxController` view models, `Rx` observables, `Get.find<T>()` for cross-feature access
- **Routing**: GetX named routes with `AuthMiddleware` protecting `root` and `onboarding`
- **Database**: Cloud Firestore — 6 collections (users, contacts, seizureLogs, alerts, headsUp, alert_responses)
- **Auth**: Firebase Authentication — email/password
- **Notifications**: Firebase Cloud Messaging (push to contacts) + `flutter_local_notifications` (in-app display)
- **Cloud Functions**: Node.js functions triggered on Firestore writes — send FCM messages to contact circles
- **Location**: `geolocator` package — GPS capture on alert creation
- **Persistence**: `shared_preferences` — active SOS/Heads Up state survives cold restarts

---

## User Interface

Design philosophy is minimal, clinical, and serious. Black-and-white palette. Red Hat Display font. No gradients, no illustrations, no gamified language. Every element communicates trust and calm. See `CLAUDE.md` for the full design system.

Navigation is a bottom tab bar with 5 tabs: Home, Seizure Log, SOS, Contacts, Profile.
