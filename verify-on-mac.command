#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Xcode is required. Install Xcode 15 or newer, then run this file again."
  exit 1
fi

echo "1/3 Checking static project resources..."
if command -v node >/dev/null 2>&1; then
  node scripts/verify-project.mjs
else
  echo "Node.js not found; skipping supplemental static checks."
fi

echo "2/3 Testing the timer state machine..."
swift test

echo "3/3 Building and testing the iOS app in Simulator..."
SIMULATOR_ID="$(
  xcrun simctl list devices available |
    awk -F '[()]' '/iPhone/ {print $2; exit}'
)"

if [[ -z "${SIMULATOR_ID}" ]]; then
  echo "No available iPhone Simulator was found. Install an iOS Simulator runtime in Xcode."
  exit 1
fi

xcodebuild test \
  -project EyeCare2020.xcodeproj \
  -scheme EyeCare2020 \
  -destination "platform=iOS Simulator,id=${SIMULATOR_ID}" \
  CODE_SIGNING_ALLOWED=NO

echo "All available Mac checks passed."
echo "Next: open EyeCare2020.xcodeproj, choose your Team, and run on a physical iPhone."
