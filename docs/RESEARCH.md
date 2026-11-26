# Research evidence — 2026-11-26

## Apple primary sources

- [UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect): iOS 26+, effectWithStyle:, interactive, tintColor. These are compiled against the real Xcode SDK, not locally fabricated interface declarations.
- [UIGlassContainerEffect](https://developer.apple.com/documentation/uikit/uiglasscontainereffect): nested UIVisualEffectViews combine child glass elements; spacing controls merging distance.
- [Build a UIKit app with the new design, WWDC25](https://developer.apple.com/videos/play/wwdc2025/284/): use native controls, animate effect rather than view alpha, put glass in the control layer, keep effects sparse and respect accessibility.
- [Runner image toolchains](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md): select installed Xcode 26 rather than assuming the default SDK supports glass.

## TikTok public source research

- [gehbfarr5/tiktok-independent-plugins, TabBar.m at 1fbe07e](https://github.com/gehbfarr5/tiktok-independent-plugins/blob/1fbe07ef9c99c330563be7b6f66e1a34d1ec1d1f/src/TabBar.m): targets 46.9.0, hooks TTKTabBar.layoutSubviews and reads buttons. Its button type accessor is NSInteger. Its documented numeric tab mapping is version-specific; TikTokGlass does NOT call type or reuse the mapping. It validates object-return ABI for buttons, returned array members and actual ancestry/geometry instead. TikTok's own controls remain responsible for navigation.
- [BandarHL/BHTikTok headers](https://github.com/BandarHL/BHTikTok/blob/main/TikTokHeaders.h) and [Tweak.x](https://github.com/BandarHL/BHTikTok/blob/main/Tweak.x): evidence for TikTokFeedTabControl, AWEFeedVideoButton, TIKTOKProfileHeaderView, AWEProfileEditTextViewController, AWECommentPanelCell, TTKSettingsBaseCellPlugin and AWESettingsNormalSectionViewModel. These are historical references, not confirmation for 47.9.0. TikTokGlass only tests the known view class AWEFeedVideoButton when present; settings use an independent native controller instead of invoking unstable private settings methods.
- [Selandros/TikTokClean](https://github.com/Selandros/TikTokClean): illustrates version-sensitive class/selector health checks and distinguishes official/jailbroken environments from modified sideload builds. No code copied.

No TikTok 47.9.0 binary, headers, live view hierarchy or phone was supplied. There is no claim that TTKTabBar still exists in 47.9.0. Missing/invalid components are skipped. The generic semantic classifier observes actual runtime UIKit views, ancestry and controller class-name tokens; tokens are heuristics and are not invented exact class/selector declarations. No private TikTok navigation action is invoked.

## Installation primary sources

[Sideloadly](https://sideloadly.io/) advertises dylib injection. Its [FAQ](https://sideloadly.io/faq) explains that injected libraries can still crash and that encrypted IPAs can fail. A jailbreak-free build therefore removes jailbreak dependencies but cannot guarantee TikTok's compatibility with re-signing.
