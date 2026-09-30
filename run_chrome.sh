#!/bin/bash
export CHROME_EXECUTABLE=/home/safi/.gemini/antigravity/bin/google-chrome
cd "$(dirname "$0")"
flutter run -d chrome "$@"
