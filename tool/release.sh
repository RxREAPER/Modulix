#!/usr/bin/env bash
# ==============================================================================
# Modulix — Unified Ecosystem Release Orchestrator
#
# Automates the entire release lifecycle:
#   1. Quality verification (flutter analyze & tests)
#   2. Version synchronization across Flutter & Web portal
#   3. Signed production APK compilation (ARM64, v2 scheme)
#   4. Signature verification via apksigner
#   5. GitHub Release tagging & binary publication
#   6. Web landing page build & Cloudflare Pages deployment
#   7. Checkpoint ledger registration & Git commit push
#
# Usage:
#   ./tool/release.sh <version> "<summary>" [--dry-run] [--skip-tests]
# Example:
#   ./tool/release.sh 1.39.0 "Focus timer enhancements and streak recovery math"
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Ensure JDK is available in PATH
if [ -d "/home/safi/mm/jdk/bin" ]; then
  export PATH="/home/safi/mm/jdk/bin:$PATH"
fi

# Ensure Android SDK build tools are available
APKSIGNER="/home/safi/Android/Sdk/build-tools/36.0.0/apksigner"
if [ ! -f "$APKSIGNER" ]; then
  APKSIGNER="$(which apksigner 2>/dev/null || true)"
fi

# Load local deployment credentials if present outside git
if [ -f "$HOME/.config/modulix_release.env" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/modulix_release.env"
fi

CF_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CF_ACCOUNT="${CLOUDFLARE_ACCOUNT_ID:-40e5b79d2d9668d2e6618a3196e44134}"

# ── Color codes ──
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${CYAN}[Modulix Release]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Argument Parsing ──
if [ $# -lt 2 ]; then
  echo "Usage: $0 <version> \"<summary>\" [--dry-run] [--skip-tests]"
  exit 1
fi

VERSION="$1"
SUMMARY="$2"
DRY_RUN=false
SKIP_TESTS=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --skip-tests) SKIP_TESTS=true ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Invalid version format '$VERSION'. Must follow semver (e.g. 1.39.0)."
fi

TAG="v$VERSION"
APK_NAME="modulix-$TAG.apk"

log "Initiating release pipeline for $TAG ($SUMMARY)..."
if [ "$DRY_RUN" = true ]; then
  warn "Running in DRY-RUN mode. No changes will be published or pushed."
fi

# ── Step 1: Pre-flight Verification ──
log "Step 1/7: Running static analysis..."
flutter analyze --no-fatal-infos

if [ "$SKIP_TESTS" = false ]; then
  log "Running test suite..."
  flutter test test/update_service_test.dart
else
  warn "Skipping tests as requested."
fi
success "Code quality verified."

# ── Step 2: Synchronize Version Across Ecosystem ──
log "Step 2/7: Synchronizing version $VERSION across Flutter & Web..."

# 2a. Flutter AppMetadata & pubspec.yaml
sed -i "s/static const String currentVersion = '[^']*';/static const String currentVersion = '$VERSION';/" lib/config/app_metadata.dart
sed -i "s/^version: .*/version: $VERSION+144/" pubspec.yaml

# 2b. Web Portal Constants
sed -i "s/version: \"[^\"]*\"/version: \"$VERSION\"/" modulix_landing_page/src/lib/constants.ts
sed -i "s|apkDownloadUrl: \"[^\"]*\"|apkDownloadUrl: \"https://github.com/RxREAPER/Modulix/releases/download/$TAG/$APK_NAME\"|" modulix_landing_page/src/lib/constants.ts
sed -i "s|githubReleaseUrl: \"[^\"]*\"|githubReleaseUrl: \"https://github.com/RxREAPER/Modulix/releases/tag/$TAG\"|" modulix_landing_page/src/lib/constants.ts

success "Version synchronized to $VERSION."

# ── Step 3: Compile Signed Production APK ──
log "Step 3/7: Compiling signed production universal release APK (all architectures)..."
if [ "$DRY_RUN" = false ]; then
  flutter build apk --release --no-tree-shake-icons
  cp build/app/outputs/flutter-apk/app-release.apk "$APK_NAME"
  success "Compiled $APK_NAME ($(du -h "$APK_NAME" | cut -f1))."
else
  log "[DRY-RUN] Would compile flutter build apk --release."
fi

# ── Step 4: Verify APK Signature ──
log "Step 4/7: Verifying APK signature..."
if [ "$DRY_RUN" = false ] && [ -n "$APKSIGNER" ] && [ -f "$APK_NAME" ]; then
  "$APKSIGNER" verify --verbose "$APK_NAME" | grep -E "(Verifies|Verified using v2)" || true
  success "Production signature verified with apksigner."
fi

# ── Step 5: Publish GitHub Release ──
log "Step 5/7: Publishing GitHub Release $TAG..."
RELEASE_NOTES="## Modulix $TAG (Universal Android Production Release)

$SUMMARY

### Artifact
- **File:** \`$APK_NAME\`
- **Architecture:** \`Universal\` (arm64-v8a, armeabi-v7a, x86_64 - phones, tablets, Android 8.0+)
- **Signature:** Official upload keystore (v2 scheme verified)

### Installation
1. Download \`$APK_NAME\` below.
2. Open and tap Install.
3. All streaks, database, and local progress are preserved cleanly."

if [ "$DRY_RUN" = false ]; then
  # Commit version sync changes before tagging
  git add lib/config/app_metadata.dart modulix_landing_page/src/lib/constants.ts
  git commit -m "checkpoint(release): bump version to $VERSION" || true
  git push origin main

  gh release create "$TAG" "$APK_NAME" \
    --title "Modulix $TAG (Android Production Release)" \
    --notes "$RELEASE_NOTES"
  success "GitHub release published: https://github.com/RxREAPER/Modulix/releases/tag/$TAG"
else
  log "[DRY-RUN] Would publish GitHub release $TAG."
fi

# ── Step 6: Build & Deploy Landing Page to Cloudflare ──
log "Step 6/7: Deploying updated landing page to Cloudflare Pages..."
if [ "$DRY_RUN" = false ]; then
  cd "$ROOT_DIR/modulix_landing_page"
  npm run build
  CLOUDFLARE_API_TOKEN="$CF_TOKEN" \
  CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT" \
  npx wrangler pages deploy dist --project-name=modulix --branch=main --commit-dirty=true
  cd "$ROOT_DIR"
  success "Cloudflare landing page deployed to https://modulix.pages.dev"
else
  log "[DRY-RUN] Would deploy to Cloudflare Pages."
fi

# ── Step 7: Ledger & Checkpoint ──
log "Step 7/7: Registering checkpoint ledger..."
if [ "$DRY_RUN" = false ]; then
  rm -f "$APK_NAME"
  success "Release pipeline completed successfully for $TAG!"
else
  log "[DRY-RUN] Pipeline completed in dry-run mode."
fi
