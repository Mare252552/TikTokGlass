# Compatibility contract

Priority target: TikTok 47.9.0, iOS 26+, iPhone 17 Pro. **No physical-device verification has been performed.**

Supported host checks: bundle identifier prefix com.zhiliaoapp.musically or com.ss.iphone.ugc.Ame (case-insensitive), or CFBundleExecutable equal to TikTok. This permits common re-signed bundle suffixes. A renamed executable and unrelated bundle identifier will safely disable automatic loading.

Deployment target 26.0: older iOS versions cannot load this dylib. Runtime API checks cover class and selector availability within the supported deployment range; they are not backwards compatibility with iOS 18.

Native UIKit bars: real UIKit API usage. Custom tab bar: only an actual TTKTabBar instance with ABI-correct buttons getter returning 2–8 descendant UIViews is eligible. App actions, delegates, selected state and control layout are never replaced. A UIGlassContainerEffect renders decorative plates behind those controls. Native press tint animation is available for recognized UIControl buttons; cross-tab glass morphing/selection effects are not guaranteed.

Profile/navigation/search/comment/menu/share/dialog/player/floating buttons: only eligible UIKit controls with matching runtime context and safe sizes are adapted. Opaque internal backgrounds can hide the effect. No claims of complete screen coverage. Broad cards/panels and text editor surfaces are deliberately skipped to avoid glass over content or keyboard input. Text entry, web, camera, authentication and payment contexts are excluded.

No unvalidated private selectors are called. The only private accessor is historical TTKTabBar.buttons, checked with NSMethodSignature before objc_msgSend. No host class is linked statically. No class-wide swizzle or exception-prone KVC. Main-thread traversal is bounded to 2500 processed views per foreground pass and pauses in the background. Objective-C exceptions restore effects and disable the master preference; this cannot protect against all native process faults.

Disable restores saved backgrounds/appearances and removes added effects/targets. Saved values are the ones at first adaptation; concurrent app appearance changes require device testing. Dynamic UIColor and regular glass use native light/dark adaptation. Reduce Transparency disables additions. Reduce Motion prevents added transitions. Existing accessibility metadata is unchanged; readability/contrast must be audited on-device.
