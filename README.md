# TikTokGlass

Native Apple Liquid Glass injection library for TikTok on **iOS 26+**, compiled as an **arm64 device dylib**. Priority target: **TikTok 47.9.0 / iPhone 17 Pro**. Experimental: neither this TikTok version nor a physical device has been validated. A successful build is not proof of compatibility or complete visual coverage.

## Implementation

- Real `UIGlassEffect` (regular style, interactive enabled) inside `UIVisualEffectView`; no `UIBlurEffect` fallback or simulated glass.
- Custom `TTKTabBar`: ABI-checked `buttons` accessor, existing control frames, one `UIGlassContainerEffect` with individual rounded glass backplates. Home/Friends/Create/Inbox/Profile keep their original controls, labels, badges and actions. No remapping or hardcoded tab indexes.
- Native `UITabBar` / `UINavigationBar`: copy appearances and set their backgroundEffect to real glass; restore when disabled.
- Runtime discovery of small UIKit buttons in profile, comment, menu/share/dialog, navigation and player contexts, plus search bars/search buttons. Unrecognized components are skipped. This is conditional coverage, not a claim that every TikTok screen has been adapted.
- Native effect-property animations and control press tint changes; original app navigation and transitions remain in charge. No custom guaranteed glass morph during TikTok tab changes.
- Persistent switches: Enable TikTokGlass, Glass Tab Bar, Glass Navigation, Glass Buttons, Glass Comments, Glass Search, Glass Menus, Glass Video Controls, Glass Profile, Debug Mode; Glass Intensity slider adjusts **tint alpha only**, not Apple's refraction strength.
- Main-thread, bounded foreground discovery every 0.8 seconds; no universal UIView hooks, no Substrate/ElleKit dependency, no private navigation calls or KVC.
- Reduce Transparency disables added effects. Reduce Motion skips added animations. Existing text, accessibility labels, touch targets and actions are preserved. VoiceOver gets a labeled 44-point settings button.

Settings: **triple-tap with three fingers** anywhere in the main app window. With VoiceOver active, use the **TikTokGlass settings** button at the top right. Settings remain reachable with the master switch off. Preferences use `dev.tiktokglass.preferences` within the host application's sandbox; reinstalling/deleting the app can remove them.

## Download and verification

See [Actions](https://github.com/Mare252552/TikTokGlass/actions) for build logs/artifacts and [Releases](https://github.com/Mare252552/TikTokGlass/releases) for experimental tagged binaries. GitHub Actions artifact downloads normally require GitHub sign-in. Release dylibs are direct public downloads.

Each build includes SHA256SUMS, toolchain details, dependency listing and Mach-O load commands. Ad-hoc signature is a build integrity check; Sideloadly must sign the final injected app with your identity.

## Build

Requires macOS and full **Xcode 26+ with iPhoneOS SDK 26+**. No Theos or extra libraries needed.

```sh
export DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer # adjust to installed Xcode 26
bash scripts/build.sh
bash scripts/analyze.sh
```

Output: `build/TikTokGlass.dylib`. Deployment target iOS 26.0; architecture arm64 (supported on iPhone 17 Pro; arm64e-only build is unnecessary). GitHub Actions selects an installed Xcode 26, builds and checks the device Mach-O, runs static analysis, uploads the artifact, and publishes a prerelease for `v*` tags. No signing credentials are stored in the repository.

## Sideloadly installation (no jailbreak dependency)

1. Obtain your own legally usable, **decrypted TikTok IPA**, preferably 47.9.0. This repository contains no TikTok binary and does not decrypt apps.
2. Download `TikTokGlass.dylib` and verify its SHA-256 against the same release/build's SHA256SUMS.
3. Open [Sideloadly](https://sideloadly.io/), connect/trust your iPhone, select the device and load the IPA.
4. Open **Advanced Options → Inject dylibs/frameworks**, add `TikTokGlass.dylib`, and enable injection if your Sideloadly version requires a separate checkbox. This module needs no Cydia Substrate dependency. Interface wording can vary by Sideloadly version.
5. Sign/install using your Apple ID or developer identity. Enable Developer Mode if iOS asks; trust your developer identity in Settings → General → VPN & Device Management if needed.
6. Launch TikTok, open TikTokGlass settings with the gesture, enable Debug Mode, navigate through the target screens, and inspect/export compatibility diagnostics. Test taps, video gestures, light/dark mode, rotation, text sizes and accessibility before relying on it.

Sideloadly officially supports dylib injection, but successful signing/injection does not ensure that a modified TikTok build will run. TikTok integrity checks, entitlements, encrypted IPAs and provisioning restrictions may prevent launch or features such as push notifications/login. Free provisioning may require periodic re-signing. This library does not bypass DRM, application integrity checks, or entitlement requirements. Back up application data before changing signing identity or replacing an installation.

To undo: disable Enable TikTokGlass for live restoration, or re-sign/install your original IPA without the library. If an incompatible injected app fails before settings can open, reinstall/re-sign the original IPA; avoid deleting app data as a first step.

## Scope and limitations

See [compatibility](docs/COMPATIBILITY.md), [research](docs/RESEARCH.md), and [device checklist](docs/DEVICE-TESTING.md).

Opaque images, button configurations, custom renderers, web content and app-owned background subviews can cover added backplates. Such views are deliberately not dismantled. Broad content cards, full comment panels, arbitrary dialogs and video surfaces are not covered wholesale; only recognized controls and native bars are eligible. Generic discovery uses runtime class-name tokens and accessible semantic labels and may miss localized or redesigned controls. Glass visuals, hit behavior, text contrast, performance and tab selection transitions need device testing.

Public APIs are used for the **glass effect**; injecting and inspecting a third-party application is not an Apple-supported application extension mechanism. No App Store distribution claim is made.

MIT license. Independently written source; third-party projects are research references only.
