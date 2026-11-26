#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
VERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
if [[ "${VERSION%%.*}" -lt 26 ]]; then echo 'ERROR: Xcode 26+ and iOS 26+ SDK required' >&2; exit 1; fi
xcodebuild -version | tee build/toolchain.txt
printf 'iPhoneOS SDK: %s\n' "$VERSION" >> build/toolchain.txt
FLAGS=(-isysroot "$SDK" -target arm64-apple-ios26.0 -fobjc-arc -fmodules -O2 -g -Wall -Wextra -Wno-unused-parameter -Werror=implicit-function-declaration -Werror=incompatible-pointer-types -I Sources)
xcrun --sdk iphoneos clang "${FLAGS[@]}" -dynamiclib Sources/*.m -framework UIKit -framework Foundation -install_name @rpath/TikTokGlass.dylib -Wl,-dead_strip -o build/TikTokGlass.dylib
# Check real Mach-O structure, platform, signature and dependency list. Not a device test.
file build/TikTokGlass.dylib | tee build/binary-info.txt
lipo -info build/TikTokGlass.dylib | tee -a build/binary-info.txt
otool -L build/TikTokGlass.dylib | tee -a build/binary-info.txt
otool -l build/TikTokGlass.dylib > build/load-commands.txt
grep -q 'LC_BUILD_VERSION' build/load-commands.txt
grep -q 'minos 26.0' build/load-commands.txt
test "$(lipo -archs build/TikTokGlass.dylib)" = arm64
if otool -L build/TikTokGlass.dylib | grep -Eiq 'substrate|substitute|ellekit|/var/jb'; then echo 'Unexpected jailbreak dependency' >&2; exit 1; fi
codesign --force --sign - build/TikTokGlass.dylib
codesign --verify --strict build/TikTokGlass.dylib
shasum -a 256 build/TikTokGlass.dylib > build/SHA256SUMS
test -s build/TikTokGlass.dylib
echo 'Device arm64 dylib build and binary checks passed.'
