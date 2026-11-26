# Verified results — 2026-11-26

## Published binary

- [Repository](https://github.com/Mare252552/TikTokGlass)
- [Successful exact release build](https://github.com/Mare252552/TikTokGlass/actions/runs/45878735637)
- [Actions artifact](https://github.com/Mare252552/TikTokGlass/actions/runs/45878735637/artifacts/15146531816)
- [Experimental release](https://github.com/Mare252552/TikTokGlass/releases/tag/0.1.0-experimental)
- [TikTokGlass.dylib](https://github.com/Mare252552/TikTokGlass/releases/download/0.1.0-experimental/TikTokGlass.dylib)

Release source commit: `f3062e8261b683afd132335f452f1287390a8aa3`. Xcode 26.3 (17C529), iPhoneOS SDK 26.2, minimum iOS 26.0, device arm64. Binary size: 153,776 bytes. Downloaded artifact bytes were checked independently: Mach-O 64-bit ARM64 MH_DYLIB, SHA-256 `8ddb04863695bd0e330e44e6841ed0556907624793387e14ca251ea05083cba5`, matching SHA256SUMS and GitHub release asset digest. Only Apple system dependencies; no Substrate, Substitute, ElleKit or /var/jb dependency. Ad-hoc signature verification passed; final IPA still requires signing.

## Build correction

[First attempt](https://github.com/Mare252552/TikTokGlass/actions/runs/45878548008) failed: UIBarAppearance.backgroundEffect accepts UIBlurEffect rather than UIGlassEffect. Fixed by inserting a real UIGlassEffect-backed UIVisualEffectView and clearing copied bar backgrounds. No invalid casting or blur substitution. Rebuilt successfully and passed Clang static analysis.

## Runtime-library smoke tests

[Successful iOS 26 simulator run](https://github.com/Mare252552/TikTokGlass/actions/runs/45878989146), test source commit `f5fc512f4d5018eebe0f1e9b64366467199629db`. Sources/*.m and *.h are unchanged from the release source; this commit adds tests, test runner, CI and README updates. Its rebuilt device artifact has its own checksum and is not substituted for the tagged release asset.

Seven groups passed using synthetic UIKit fixtures:

1. Native glass API availability.
2. Rejection of non-array accessor values and foreign tab-button hierarchy; acceptance of valid descendant views.
3. Search semantic discovery and text-entry exclusion.
4. Actual UIGlassEffect object, no duplicate overlays, noninteractive decorative overlay and restoration of original background.
5. Actual UIGlassContainerEffect with two child plates and unchanged original control ownership.
6. UINavigationBar appearance restoration.
7. Preference-suite storage and intensity bounds.

[Machine-readable result](https://github.com/Mare252552/TikTokGlass/releases/download/0.1.0-experimental/smoke-results.json). These checks execute the library on iOS Simulator and are not a TikTok mockup or acceptance test. The harness emitted a UIWindow.initWithFrame deprecation warning; tests completed successfully. Persisted preference storage was checked within the process using a fresh NSUserDefaults instance; restart persistence still needs the physical-device checklist.

## Not verified

No TikTok 47.9.0 binary or physical iPhone 17 Pro was available. Sideloadly installation, TikTok startup/integrity checks, real 47.9.0 class hierarchy, all requested UI surfaces, visual refraction quality, actual touch behavior, text contrast, app relaunch persistence, tab animations, performance and battery have not been physically tested. Broad cards/panels/video content are not covered. Read docs/COMPATIBILITY.md and run docs/DEVICE-TESTING.md before treating any target screen as supported.
