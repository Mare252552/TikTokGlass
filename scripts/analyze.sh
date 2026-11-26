#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/analysis
for source in Sources/*.m; do
  xcrun --sdk iphoneos clang --analyze -isysroot "$(xcrun --sdk iphoneos --show-sdk-path)" -target arm64-apple-ios26.0 -fobjc-arc -fmodules -I Sources -Xanalyzer -analyzer-output=text "$source" 2> "build/analysis/$(basename "$source").log"
  cat "build/analysis/$(basename "$source").log"
  if grep -q 'warning:' "build/analysis/$(basename "$source").log"; then exit 1; fi
done
