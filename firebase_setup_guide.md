# Orça+ - Firebase Setup Guide

## Prerequisites

- Flutter SDK installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Google account for Firebase Console

## Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name your project: `orcafacil` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create project"

### 2. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3. Configure Firebase for Flutter

From your project root directory:

```bash
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Ask which platforms to configure (select Android, iOS, Web)
- Automatically generate `firebase_options.dart`
- Update your platform-specific files

### 4. Enable Firebase Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Enable sign-in methods:
   - **Email/Password**: Enable this provider
   - **Google**: Enable this provider
     - Download the configuration files when prompted
     - Follow platform-specific setup instructions

#### Android Google Sign-In Setup

1. Add SHA-1 fingerprint to Firebase project:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy the SHA-1 from the debug variant
3. In Firebase Console → Project Settings → Add fingerprint

#### iOS Google Sign-In Setup

1. Open `ios/Runner/Info.plist`
2. Add the `CFBundleURLTypes` array (FlutterFire should handle this automatically)

### 5. Create Cloud Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Select "Start in production mode"
4. Choose a location closest to your users
5. Click "Enable"

### 6. Deploy Firestore Security Rules

From your project root:

```bash
firebase deploy --only firestore:rules
```

Or manually:
1. Go to **Firestore Database** → **Rules**
2. Copy the content from `firestore.rules`
3. Click "Publish"

### 7. Enable Firebase Storage

1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Accept the default security rules (we'll update them)
4. Choose the same location as Firestore
5. Click "Done"

### 8. Deploy Storage Security Rules

```bash
firebase deploy --only storage:rules
```

Or manually:
1. Go to **Storage** → **Rules**
2. Copy the content from `storage.rules`
3. Click "Publish"

### 9. Create Firestore Indexes

Create composite indexes for queries:

1. Go to **Firestore Database** → **Indexes**
2. Create the following indexes:

**Budgets Collection:**
- Collection ID: `budgets`
- Fields to index:
  - `userId` (Ascending)
  - `createdAt` (Descending)

**Services Collection:**
- Collection ID: `services`
- Fields to index:
  - `userId` (Ascending)
  - `name` (Ascending)

**Clients Collection:**
- Collection ID: `clients`
- Fields to index:
  - `userId` (Ascending)
  - `name` (Ascending)

### 10. Google Play Billing Setup (For Production)

#### In Google Play Console:

1. Create your app in Play Console
2. Go to **Monetization** → **In-app products** → **Subscriptions**
3. Create a new subscription:
   - Product ID: `orcamais_pro_monthly`
   - Name: `Orça+ Pro`
   - Description: `Plano profissional com orçamentos ilimitados`
   - Price: R$ 19,90
   - Billing period: 1 month

#### Testing Subscriptions:

1. Add license testers in Play Console
2. Build and upload to internal testing track
3. Install from Play Store (internal testing)
4. Test purchase flow

### 11. Environment Setup Verification

Run these commands to verify your setup:

```bash
# Check Flutter
flutter doctor

# Check dependencies
flutter pub get

# Run the app
flutter run
```

## Common Issues

### Firebase not initialized

**Error:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution:** Make sure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`.

### Google Sign-In not working on Android

**Solution:** 
1. Verify SHA-1 fingerprint is added to Firebase project
2. Download latest `google-services.json`
3. Place it in `android/app/`
4. Clean and rebuild

### Firestore permission denied

**Solution:**
1. Verify security rules are deployed
2. Check that `userId` field matches `request.auth.uid`
3. Ensure user is authenticated

### Storage upload fails

**Solution:**
1. Check file size (max 5MB)
2. Verify file type is image
3. Ensure user is authenticated
4. Check storage rules

## Production Checklist

Before releasing to production:

- [ ] Configure Firebase for Production mode
- [ ] Update security rules
- [ ] Set up proper error logging (Firebase Crashlytics)
- [ ] Configure backup strategy for Firestore
- [ ] Test all subscription flows
- [ ] Add proper ProGuard rules (Android)
- [ ] Configure app signing
- [ ] Test on multiple devices
- [ ] Set up Firebase Analytics (optional)
- [ ] Configure Cloud Functions for subscription webhooks (advanced)

## Support

For issues, check:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Documentation](https://flutter.dev/docs)
