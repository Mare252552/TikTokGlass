# Required physical-device acceptance — not yet run

Use iPhone 17 Pro, iOS 26+, a legally usable decrypted TikTok 47.9.0 IPA and record exact iOS/TikTok/build SHA256/signing setup. Enable Debug Mode and export diagnostics from TikTokGlass settings.

- Launch, background/foreground, relaunch and settings persistence. Confirm master off removes all added effects; entry remains usable.
- Home, Friends, Create, Inbox, Profile: test all original actions, badges, selected states, tab transitions, keyboard/safe-area overlap and video gestures. Record whether TTKTabBar or native UITabBar is actually found.
- Profile header/navigation/edit tools, top navigation, search button/bar, comment controls, share menu, dialogs/settings buttons, floating controls and player buttons: record each matched class, effect visibility and tap accuracy. Missing components must remain usable and skipped.
- Confirm Apple native glass refraction against video/background, dark/light themes and that opaque app subviews do not cover plates. Do not label a covered/missing effect as working.
- Confirm no broad overlay on video, text panels, cards, keyboard, camera, payment/login or web content. Scroll performance, memory and battery should be measured.
- Test larger text, bold text, Increase Contrast, Reduce Transparency, Reduce Motion and VoiceOver. Check contrast, 44-point settings target and dismissal. Triple-three-finger tap can conflict with accessibility gestures; VoiceOver exposes a separate entry.
- Remove dylib and reinstall/re-sign original IPA for rollback if launch fails.

Compiler success, static analysis and Mach-O inspection are not substitutes for this checklist. No simulator or device TikTok tests have been performed unless separately recorded in VERIFICATION.md.
