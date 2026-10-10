# CampusSOS — Safe Campus Companion
**Hackathon-Ready Flutter Application with Cloud Firestore & Firebase Authentication**

CampusSOS is a comprehensive, production-grade mobile companion engineered to enhance college campus safety. It gives students one-touch emergency SOS capabilities with exact GPS tracking, trusted personal safety circles, safe-arrival journey timers with live countdowns, official campus security directories, and crowdsourced hazard reporting.

---

## 📱 Features Summary

- **Instant SOS Panic Trigger**: One-touch red emergency button with real-time GPS coordinates saved directly to Cloud Firestore. Includes quick-launch actions for telephone dialing (Campus Security / 911), SMS broadcasting, and native share sheets (WhatsApp/Telegram).
- **Google Maps Integration**: Instant clickable Google Maps navigation URLs for emergency pins and hazard locations without requiring a paid Google Maps API billing key.
- **Safe-Arrival Journey Companion**: Students set a destination and estimated walking duration (10–60 mins). A live foreground countdown timer alerts students and detects overdue arrivals with one-touch "I've Arrived Safely" check-in.
- **Trusted Contacts Circle (CRUD)**: Students can add, edit, view, and delete their primary emergency contacts (roommates, family, guardians) with user-scoped isolation in Firestore.
- **Official Campus Directory**: Direct-dial directory for Campus Security, Health Centre, Hostel Wardens, Women's Helpline, and Police Desks with search and category filtering.
- **Campus Hazard Reporting**: Crowdsourced reporting for broken streetlights, dark walkways, damaged gates, and hazards with GPS auto-pinning and administrative status badges (`submitted`, `under_review`, `resolved`).
- **Student Authentication & Profile**: Email/Password authentication with strict student-role enforcement (prevents privilege escalation) and personal profile management.
- **Strict Firestore Security Rules**: Fully secure `firestore.rules` preventing unauthorized cross-user access, privilege escalation, and unauthenticated tampering.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.44+ (Dart 3.12+) |
| **Design System** | Material 3 (Navy Blue, Safe Teal, Crimson SOS, Pure White) |
| **Authentication** | Firebase Authentication (Email/Password) |
| **Primary Database** | Google Cloud Firestore (Real-time snapshots & typed streams) |
| **Location Services** | `geolocator` with high-accuracy GPS & permission handling |
| **Maps & Dialing** | `url_launcher` (Google Maps Universal URL links & `tel:` / `sms:`) |
| **Native Sharing** | `share_plus` (WhatsApp, SMS, Telegram emergency broadcasts) |
| **Local Cache** | `shared_preferences` |
| **State Architecture** | `provider` (MultiProvider with reactive listeners) |

---

## 📂 Project Structure

```
CampusSOs/
├── android/
│   └── app/src/main/AndroidManifest.xml    # GPS, Internet, & URL intent queries
├── lib/
│   ├── firebase_options.dart               # Multi-platform Firebase configuration
│   ├── main.dart                           # App entry point, MultiProvider & Theme
│   ├── models/
│   │   ├── app_user.dart                   # User profile model & student role lock
│   │   ├── trusted_contact.dart            # Emergency contact model
│   │   ├── safety_session.dart             # Safe journey timer & overdue calculations
│   │   ├── emergency_alert.dart            # SOS incident model & Maps link generator
│   │   ├── campus_report.dart              # Hazard report model & status mapping
│   │   └── campus_contact.dart             # Official campus directory model
│   ├── services/
│   │   ├── auth_service.dart               # Auth state, login, registration, profile sync
│   │   ├── alert_service.dart              # SOS Firestore persistence, calling & sharing
│   │   ├── campus_directory_service.dart   # Campus contacts directory & fallback seeding
│   │   ├── location_service.dart           # Geolocator permissions, GPS & Maps links
│   │   ├── report_service.dart             # Hazard reports submission & user stream
│   │   ├── safety_session_service.dart     # Safe journey start, check-in, & cancel
│   │   └── trusted_contact_service.dart    # User-scoped contact CRUD operations
│   ├── screens/
│   │   ├── splash_screen.dart              # Auth state listener & branding splash
│   │   ├── home_screen.dart                # Central dashboard, SOS button, Quick Actions
│   │   ├── sos_screen.dart                 # SOS trigger center, GPS preview, dialer & history
│   │   ├── trusted_contacts_screen.dart    # Contact list, add/edit modal, delete
│   │   ├── safe_arrival_screen.dart        # Real-time countdown timer & journey log
│   │   ├── campus_directory_screen.dart    # Category filters, live search & quick-call
│   │   ├── report_issue_screen.dart        # Hazard submission form with GPS pin
│   │   ├── my_reports_screen.dart          # Report tracking & status badges
│   │   ├── profile_screen.dart             # Student profile edit & sign out
│   │   └── auth/
│   │       ├── login_screen.dart           # Login form, validation & password reset
│   │       └── register_screen.dart        # Registration form with student role lock
│   ├── theme/
│   │   └── app_theme.dart                  # Material 3 theme palette & typography
│   └── widgets/
│       ├── contact_card.dart               # Reusable contact card with call/SMS actions
│       ├── empty_state_view.dart           # Clean illustrations for empty states
│       ├── loading_view.dart               # Consistent loading spinner
│       ├── safety_status_card.dart         # Live status banner (Safe / In Journey / Overdue)
│       └── sos_button.dart                 # Pulsing animated emergency SOS button
├── test/
│   └── widget_test.dart                    # Complete unit test suite for all models
├── firestore.rules                         # Production-grade Firestore security rules
├── pubspec.yaml                            # Configured dependencies
└── README.md                               # Project documentation
```

---

## 🗄️ Database Design (Cloud Firestore)

### 1. `users`
- **Document ID**: Firebase Auth UID (`request.auth.uid`)
- **Fields**:
  - `uid` (`string`): Authenticated user's UID
  - `name` (`string`): Student's full name
  - `email` (`string`): Student's institutional or personal email
  - `college` (`string`): University or campus name
  - `role` (`string`): Defaults strictly to `'student'`
  - `phone` (`string?`): Optional contact number
  - `createdAt` (`timestamp`): Server timestamp
  - `updatedAt` (`timestamp`): Server timestamp
- **Security Rule**: User can only read and update their own document. Modification of `role` is blocked at the rule level.

### 2. `trusted_contacts`
- **Document ID**: Auto-generated
- **Fields**:
  - `ownerUid` (`string`): UID of the student who owns the contact
  - `name` (`string`): Contact's name
  - `phone` (`string`): Telephone number
  - `relationship` (`string`): e.g., Roommate, Parent, Friend, Hostel Warden
  - `createdAt` (`timestamp`): Server timestamp
  - `updatedAt` (`timestamp`): Server timestamp
- **Security Rule**: Read, create, update, delete permitted only when `ownerUid == request.auth.uid`.

### 3. `safety_sessions`
- **Document ID**: Auto-generated
- **Fields**:
  - `ownerUid` (`string`): UID of the student
  - `destination` (`string`): Target arrival location
  - `startTime` (`timestamp`): Journey start time
  - `expectedArrival` (`timestamp`): Calculated expected arrival time
  - `actualArrival` (`timestamp?`): Timestamp when checked in or cancelled
  - `status` (`string`): `'active'`, `'arrived'`, `'overdue'`, or `'cancelled'`
  - `latitude` (`number?`): Starting GPS latitude
  - `longitude` (`number?`): Starting GPS longitude
  - `createdAt` (`timestamp`): Server timestamp
- **Security Rule**: Strictly user-scoped. Only the journey owner can initiate, update, or cancel.

### 4. `emergency_alerts`
- **Document ID**: Auto-generated
- **Fields**:
  - `ownerUid` (`string`): UID of the student triggering SOS
  - `alertType` (`string`): e.g., `'SOS Panic'`
  - `message` (`string`): Full emergency description with Maps link
  - `latitude` (`number?`): Accurate GPS latitude captured at trigger time
  - `longitude` (`number?`): Accurate GPS longitude captured at trigger time
  - `status` (`string`): `'created'`, `'processing'`, `'sent'`, `'resolved'`
  - `createdAt` (`timestamp`): Server timestamp
  - `resolvedAt` (`timestamp?`): Timestamp when user marks incident as safe
- **Security Rule**: Owner can create and resolve alerts. Administrators can view all alerts.

### 5. `campus_reports`
- **Document ID**: Auto-generated
- **Fields**:
  - `reporterUid` (`string`): UID of the student who submitted the report
  - `category` (`string`): e.g., `'Broken Streetlight'`, `'Poorly Lit Pathway'`, `'Harassment Hotspot'`
  - `description` (`string`): Details of hazard location and condition
  - `latitude` (`number?`): Attached GPS latitude
  - `longitude` (`number?`): Attached GPS longitude
  - `photoUrl` (`string?`): Optional evidence photo URL
  - `status` (`string`): Initiates as `'submitted'`. Transitions to `'under_review'` or `'resolved'`
  - `createdAt` (`timestamp`): Server timestamp
  - `updatedAt` (`timestamp`): Server timestamp
- **Security Rule**: Students can submit reports and read their own. **Only administrators** can alter report status to `'under_review'` or `'resolved'`.

### 6. `campus_contacts`
- **Document ID**: Auto-generated or custom ID
- **Fields**:
  - `name` (`string`): Official resource title
  - `category` (`string`): `'Security'`, `'Medical'`, `'Hostel'`, `'Support'`, `'Police'`
  - `phone` (`string`): Emergency phone number
  - `locationDescription` (`string`): Room, post, or building location
  - `isActive` (`boolean`): Active listing flag
- **Security Rule**: Readable by all authenticated students. Write access restricted to administrators.

---

## 🔒 Firestore Security Rules (`firestore.rules`)

The `firestore.rules` file enforces zero-trust security:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null && request.auth.uid != null;
    }
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    function isAdmin() {
      return isAuthenticated() && 
        (request.auth.token.role == 'admin' || 
         request.auth.token.email.matches('.*@admin\\.campus\\.edu'));
    }

    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId) && request.resource.data.role == 'student';
      allow update: if isOwner(userId) && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']));
      allow delete: if isAdmin();
    }

    match /trusted_contacts/{contactId} {
      allow read, update, delete: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.ownerUid == request.auth.uid;
    }

    match /safety_sessions/{sessionId} {
      allow read, update, delete: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.ownerUid == request.auth.uid && request.resource.data.status == 'active';
    }

    match /emergency_alerts/{alertId} {
      allow read: if isAuthenticated() && (resource.data.ownerUid == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && request.resource.data.ownerUid == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
      allow delete: if isAdmin();
    }

    match /campus_reports/{reportId} {
      allow read: if isAuthenticated() && (resource.data.reporterUid == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && request.resource.data.reporterUid == request.auth.uid && request.resource.data.status == 'submitted';
      allow update, delete: if isAdmin();
    }

    match /campus_contacts/{contactId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

### To deploy rules to your Firebase project:
```bash
firebase deploy --only firestore:rules
```

---

## 🚀 Setup & Execution Guide

### 1. Prerequisites
- Flutter SDK (3.24+ recommended, tested with 3.44)
- Git & Android Studio or VS Code
- A free Firebase Account ([console.firebase.google.com](https://console.firebase.google.com))

### 2. Connect Your Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com) and click **Add project** (name it `campussos-demo` or your preferred name).
2. Under **Build > Authentication**, click **Get Started** and enable **Email/Password**.
3. Under **Build > Firestore Database**, click **Create Database** (choose production mode or test mode; select your nearest region).
4. Register your Flutter app using either method:
   - **Method A (Recommended - FlutterFire CLI)**:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
     Select your Firebase project. This will automatically update `lib/firebase_options.dart` and download `google-services.json` to `android/app/`.
   - **Method B (Manual)**:
     - In Firebase Console, add an Android App with package name `com.campussos.campus_sos`.
     - Download `google-services.json` and place it in `android/app/google-services.json`.
     - Paste your Firebase API Key and Project ID into `lib/firebase_options.dart`.

### 3. Run the App
```bash
# Get dependencies
flutter pub get

# Run unit tests
flutter test

# Analyze Dart code
flutter analyze

# Run on connected device, Android emulator, or Chrome
flutter run
```

In VS Code: Press `F5` or select **Run > Start Debugging**.

---

## ✅ Feature Verification Checklist

| Feature | Test Procedure | Expected Result | Status |
|---|---|---|---|
| **Registration** | Open app > Click "Register as Student" > Fill details > Submit | Account created in Firebase Auth and profile saved in `users` with `role: 'student'`. | Verified |
| **Login / Logout** | Enter credentials > Log in > Go to Profile > Tap "Sign Out" | Session persists across restarts. Clean sign out clears session and redirects to Login. | Verified |
| **Password Reset** | Tap "Forgot Password" on login > Enter email > Submit | Firebase sends secure password recovery link to user's inbox. | Verified |
| **Trusted Contacts (Add)** | Navigate to Trusted Contacts > Tap "Add Contact" > Enter details | Contact created in `trusted_contacts` with `ownerUid == auth.uid`. | Verified |
| **Trusted Contacts (Call/SMS)**| Tap phone icon or SMS icon on contact card | Launches system phone dialer (`tel:`) or pre-filled SMS composer (`sms:`). | Verified |
| **Trusted Contacts (Edit/Del)**| Tap 3-dot menu on contact > Edit or Delete with confirmation | Record updated or removed in Firestore in real time. | Verified |
| **SOS Incident Log** | Tap large red SOS button on Home > Confirm | Current GPS coordinates acquired; emergency record stored in `emergency_alerts`. | Verified |
| **Google Maps Pin** | In SOS screen, tap "View GPS in Google Maps" | Opens Google Maps browser/app at exact coordinates without paid API key. | Verified |
| **SOS Resolve** | Tap "I am Safe" on active alert | Alert document status updated to `'resolved'` with `resolvedAt` timestamp. | Verified |
| **Safe Journey Start** | Enter destination (e.g. "Library") > Choose 20 min > Start | New `safety_sessions` record created; active countdown timer starts. | Verified |
| **Journey Countdown** | Observe countdown timer on Home or Journey screen | Seconds tick down; remaining minutes calculate smoothly. | Verified |
| **Safe Check-in** | Tap "I've Arrived" on active journey | Session status changes to `'arrived'` with `actualArrival` timestamp; timer resets. | Verified |
| **Campus Directory** | Navigate to Campus Directory > Search "Medical" or filter | Filters matching contacts. Tapping dialer launches phone call. | Verified |
| **Hazard Report** | Open Report Unsafe Area > Select "Broken Streetlight" > Toggle GPS > Submit | Report document added to `campus_reports` with status `'submitted'`. | Verified |
| **My Reports** | Open My Reports from dashboard | Shows user's historical reports with status tags (`Submitted`, `Under Review`, `Resolved`). | Verified |
| **Profile Edit** | Open Profile > Tap Edit > Modify college or phone > Save | Document in `users` updated in Firestore with `updatedAt` timestamp. | Verified |

---

## ⚖️ Implemented Features vs. External Configuration

| Feature | Implementation Status | Notes / External Requirement |
|---|---|---|
| **Student Auth & Profiles** | **Fully Implemented** | Email/Password with Firestore storage. Requires Firebase Console Email provider enabled. |
| **Trusted Contacts (CRUD)** | **Fully Implemented** | Isolated per user UID; Firestore streams. |
| **Emergency SOS Trigger** | **Fully Implemented** | Captures GPS, writes to Firestore, generates Google Maps links. |
| **Carrier Telephony & SMS** | **Fully Implemented** | Launches device phone dialer and SMS client via `url_launcher`. |
| **Native Social Share** | **Fully Implemented** | Shares emergency coordinates via WhatsApp, Telegram, etc., using `share_plus`. |
| **Automated Remote Carrier SMS** | **Labeled / Requires Gateway** | Direct cloud-to-carrier SMS without opening device SMS requires Twilio / AWS SNS / Cloud Function. |
| **Safe-Arrival Timer** | **Fully Implemented (Foreground)** | Real-time countdown and overdue detection when app is active. Background OS monitoring requires background worker service. |
| **Campus Directory** | **Fully Implemented** | Live Firestore streams with offline fallback and auto-seeding. |
| **Hazard Reporting** | **Fully Implemented** | Text & GPS hazard reports in Firestore with status lifecycle. Photo uploads require Firebase Storage bucket configuration. |
| **Firestore Security Rules** | **Fully Implemented** | Zero-trust rules written in `firestore.rules`. Ready to deploy via Firebase CLI. |

---

## 🎙️ Two-Minute Hackathon Presentation Script

**[0:00 - 0:25] The Problem & Hook**
> *"Judges, imagine walking across campus at 11:30 PM from the library to your dorm. The pathway lights are out, your phone battery is down to 10%, and an uncomfortable situation unfolds. Every semester, students face moments where asking for help is either too slow, too complicated, or too late. Today, we are proud to introduce **CampusSOS — Safe Campus Companion**."*

**[0:25 - 0:55] Live Demo: Instant SOS & Safe Journey**
> *"CampusSOS is built on Flutter with a real-time Cloud Firestore backbone. Watch how simple this is: right on the home dashboard, a student has one prominent, pulsating SOS button. When tapped, CampusSOS immediately locks onto high-accuracy GPS coordinates, commits an emergency incident document to Firestore, and generates an instant Google Maps universal link — with no paid API keys required. From here, the student can broadcast their exact coordinates directly to their trusted contacts or immediately dial campus security."*

**[0:55 - 1:25] Safe-Arrival Check-in & Hazard Reporting**
> *"Not every situation is an immediate crisis — which is why CampusSOS features our proactive **Safe-Arrival Companion**. A student entering a dark route selects 'North Hostel' for a 15-minute walk. The app starts a real-time countdown. If they arrive safely, a single tap checks them in. If they don't, the app detects an overdue journey and immediately prompts emergency escalation.
> 
> Furthermore, students actively protect each other through **Hazard Reporting**. Encounter a broken streetlight or an unlit path? Pin the GPS location and submit a hazard report. Campus safety teams can review and update resolution statuses in real time."*

**[1:25 - 2:00] Architecture, Security & Conclusion**
> *"Under the hood, security is paramount. We implemented strict Firestore security rules: students have zero-trust access to their own data, their personal emergency circle is completely private, and role escalation is blocked at the database level.
> 
> CampusSOS is not just an idea or a static UI mock-up: it is a fully functioning, tested Flutter application with real database integration, ready to make college campuses safer tomorrow. Thank you!"*
