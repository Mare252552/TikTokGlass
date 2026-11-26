#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP=build/TGSmoke.app
mkdir -p "$APP"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>dev.tiktokglass.smoke</string><key>CFBundleExecutable</key><string>TGSmoke</string><key>CFBundleName</key><string>TGSmoke</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>1.0</string><key>MinimumOSVersion</key><string>26.0</string><key>UILaunchScreen</key><dict/></dict></plist>
PLIST
ARCH=$(uname -m)
xcrun --sdk iphonesimulator clang -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -target "$ARCH-apple-ios26.0-simulator" -fobjc-arc -fmodules -DTG_TESTING=1 -I Sources Sources/*.m Tests/Smoke.m -framework UIKit -framework Foundation -o "$APP/TGSmoke"
codesign --force --sign - "$APP"
xcrun simctl list devices available -j > build/simulator-devices.json
DEVICE=$(python3 - <<'PY'
import json
d=json.load(open('build/simulator-devices.json'))
items=[v for k,vs in d['devices'].items() if 'iOS-26' in k for v in vs if v.get('isAvailable') and 'iPhone' in v['name']]
items.sort(key=lambda v:('iPhone 17 Pro' not in v['name'],v['name']))
if not items: raise SystemExit('No installed iOS 26 iPhone simulator')
print(items[0]['udid'])
PY
)
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" dev.tiktokglass.smoke
CONTAINER=$(xcrun simctl get_app_container "$DEVICE" dev.tiktokglass.smoke data)
for attempt in $(seq 1 30); do
  if [[ -s "$CONTAINER/Documents/smoke-results.json" ]]; then break; fi
  sleep 1
done
cp "$CONTAINER/Documents/smoke-results.json" build/smoke-results.json
cat build/smoke-results.json
python3 - <<'PY'
import json
r=json.load(open('build/smoke-results.json'))
assert r['failure'] is None,r['failure']
assert len(r['passed'])>=7,r
PY
