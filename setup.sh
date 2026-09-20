#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# INWIN — Complete setup script
# Run this once after cloning the repo to get everything working.
# ─────────────────────────────────────────────────────────────────────────────

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INWIN]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Check prerequisites ────────────────────────────────────────────────
info "Checking prerequisites..."
command -v flutter  >/dev/null 2>&1 || error "Flutter not found. Install from https://flutter.dev"
command -v firebase >/dev/null 2>&1 || warning "Firebase CLI not found. Install: npm i -g firebase-tools"
command -v node     >/dev/null 2>&1 || error "Node.js not found. Install from https://nodejs.org"

FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
info "Found: $FLUTTER_VERSION"

# ── 2. Flutter dependencies ───────────────────────────────────────────────
info "Installing Flutter dependencies..."
flutter pub get

# ── 3. Cloud Functions dependencies ──────────────────────────────────────
info "Installing Cloud Functions dependencies..."
cd functions && npm install && cd ..

# ── 4. FlutterFire CLI ───────────────────────────────────────────────────
if ! command -v flutterfire >/dev/null 2>&1; then
  info "Installing FlutterFire CLI..."
  dart pub global activate flutterfire_cli
fi

# ── 5. Firebase configuration ────────────────────────────────────────────
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  NEXT STEP: Configure Firebase${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  1. Create a Firebase project at: https://console.firebase.google.com"
echo "  2. Enable Authentication (Email/Password)"
echo "  3. Enable Firestore Database"
echo "  4. Enable Storage"
echo "  5. Enable Cloud Messaging (FCM)"
echo "  6. Run: firebase login"
echo "  7. Run: flutterfire configure"
echo "     → This replaces lib/firebase_options.dart with real credentials"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 6. Check if firebase is configured ───────────────────────────────────
if grep -q "YOUR_ANDROID_API_KEY" lib/firebase_options.dart 2>/dev/null; then
  warning "firebase_options.dart still contains placeholders."
  warning "Run 'flutterfire configure' before building the app."
else
  info "firebase_options.dart looks configured ✓"
fi

# ── 7. Android: check google-services.json ───────────────────────────────
if [ ! -f "android/app/google-services.json" ]; then
  warning "android/app/google-services.json not found."
  warning "Download it from Firebase Console → Project Settings → Android app."
fi

# ── 8. iOS: check GoogleService-Info.plist ───────────────────────────────
if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
  warning "ios/Runner/GoogleService-Info.plist not found."
  warning "Download it from Firebase Console → Project Settings → iOS app."
fi

info "Setup complete! Next steps:"
echo "  • Run the app:          flutter run"
echo "  • Deploy functions:     firebase deploy --only functions"
echo "  • Deploy Firestore:     firebase deploy --only firestore"
echo "  • Deploy storage rules: firebase deploy --only storage"
echo "  • Start emulators:      firebase emulators:start"
echo ""
echo "  • Make yourself admin:  Set users/{uid}/role = 'admin' in Firestore Console"
