#import "TGCompatibility.h"
#import "TGSettings.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <string.h>

BOOL TGSupportedHost(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString ?: @"";
    NSString *exe=[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
    return [bundle hasPrefix:@"com.zhiliaoapp.musically"] || [bundle hasPrefix:@"com.ss.iphone.ugc.ame"] || [exe.lowercaseString isEqualToString:@"tiktok"];
}
BOOL TGHasGlassAPI(void) {
    if (@available(iOS 26.0, *)) {
        Class glass=NSClassFromString(@"UIGlassEffect");
        return glass && [glass respondsToSelector:@selector(effectWithStyle:)] &&
          [glass instancesRespondToSelector:@selector(setInteractive:)] &&
          NSClassFromString(@"UIGlassContainerEffect")!=Nil;
    } return NO;
}
BOOL TGIsOwnedView(UIView *view) {
    return [view.accessibilityIdentifier hasPrefix:@"TikTokGlass."] || [NSStringFromClass(view.class) hasPrefix:@"TG"];
}
// Historical evidence: TTKTabBar.buttons in TikTok 46.9.0 (see docs/RESEARCH.md).
// Never call an unknown private selector without validating its ABI first.
NSArray<UIView *> *TGTabButtons(UIView *view) {
    Class known=NSClassFromString(@"TTKTabBar");
    if (!known || ![view isKindOfClass:known]) return nil;
    SEL selector=NSSelectorFromString(@"buttons");
    if (![view respondsToSelector:selector]) return nil;
    NSMethodSignature *sig=[view methodSignatureForSelector:selector];
    if (!sig || sig.numberOfArguments!=2 || strcmp(sig.methodReturnType,@encode(id))!=0) return nil;
    id result=((id(*)(id,SEL))objc_msgSend)(view,selector);
    if (![result isKindOfClass:NSArray.class] || [result count]<2 || [result count]>8) return nil;
    NSMutableArray *buttons=[NSMutableArray new];
    for (id item in result) {
        if (![item isKindOfClass:UIView.class] || ![item isDescendantOfView:view] || item==view) return nil;
        if (![(UIView *)item isHidden]) [buttons addObject:item];
    }
    return buttons.count>=2 ? buttons : nil;
}
static BOOL ContainsAny(NSString *s, NSArray<NSString *> *tokens) {
    for (NSString *token in tokens) if ([s containsString:token]) return YES; return NO;
}
NSString *TGCategory(UIView *view) {
    if (TGIsOwnedView(view) || [view isKindOfClass:UIVisualEffectView.class]) return nil;
    // Runtime semantic discovery: these are tokens, NOT asserted TikTok class names.
    NSMutableString *context=[NSMutableString new]; UIView *ancestor=view;
    for (NSUInteger i=0; ancestor && i<7; i++,ancestor=ancestor.superview) {
        if (TGIsOwnedView(ancestor)) return nil;
        if ([ancestor isKindOfClass:UIVisualEffectView.class]) return nil; // no glass-on-glass
        if (ancestor!=view && ([ancestor isKindOfClass:UINavigationBar.class] || [ancestor isKindOfClass:UITabBar.class])) return nil;
        if (NSClassFromString(@"TTKTabBar") && [ancestor isKindOfClass:NSClassFromString(@"TTKTabBar")]) return nil;
        [context appendFormat:@" %@",NSStringFromClass(ancestor.class).lowercaseString];
    }
    UIResponder *responder=view;
    for (NSUInteger i=0; responder && i<14; i++,responder=responder.nextResponder) {
        if ([responder isKindOfClass:UIViewController.class]) [context appendFormat:@" %@",NSStringFromClass(responder.class).lowercaseString];
    }
    if (ContainsAny(context,@[@"keyboard",@"textfield",@"textview",@"webview",@"camera",@"capture",@"payment",@"login"])) return nil;
    BOOL button=[view isKindOfClass:UIButton.class];
    BOOL search=[view isKindOfClass:UISearchBar.class];
    if (!button && !search) return nil; // never glass over arbitrary content/card/video views
    CGSize size=view.bounds.size;
    if (size.width<24 || size.height<24 || size.width>600 || size.height>100) return nil;
    NSString *name=[NSString stringWithFormat:@"%@ %@",view.accessibilityIdentifier ?: @"",view.accessibilityLabel ?: @""].lowercaseString;
    if (search || ContainsAny(name,@[@"search",@"pretraga"])) return @"search";
    if (ContainsAny(context,@[@"comment"])) return @"comments";
    if (ContainsAny(context,@[@"profile"])) return @"profile";
    if (ContainsAny(context,@[@"settings",@"menu",@"actionsheet",@"alert",@"share",@"inbox",@"message"])) return @"menus";
    if (ContainsAny(context,@[@"player",@"feed",@"playvideo"])) {
        // Only individually identified controls, not every button on the video canvas.
        if (ContainsAny(name,@[@"share",@"comment",@"pause",@"play",@"mute",@"speed",@"like",@"save",@"favorite",@"bookmark"]) ||
            [view isKindOfClass:NSClassFromString(@"AWEFeedVideoButton")]) return @"videoControls";
        return nil;
    }
    if (ContainsAny(context,@[@"navigation",@"navbar",@"tabcontrol"])) return @"navigation";
    if (ContainsAny(name,@[@"share",@"menu",@"settings",@"edit profile"])) return @"buttons";
    return nil;
}
static NSMutableDictionary<NSString *,NSNumber *> *observed;
void TGRecord(UIView *view, NSString *category) {
    if (![[TGSettings shared] enabled:@"debug"]) return;
    if (!observed) observed=[NSMutableDictionary new];
    NSString *key=[NSString stringWithFormat:@"%@: %@",category,NSStringFromClass(view.class)];
    if (!observed[key] && observed.count<100) { observed[key]=@1; NSLog(@"[TikTokGlass] matched %@",key); }
}
NSString *TGDiagnosticReport(void) {
    NSMutableString *s=[NSMutableString stringWithFormat:@"TikTokGlass 2.0.0\nTikTok: %@\niOS: %@\nNative glass API: %@\nTTKTabBar class: %@\nReduce Transparency: %@\nReduce Motion: %@\n47.9.0 device validation: NOT PERFORMED\nObserved class/category matches (Debug Mode only):\n",
      [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
      UIDevice.currentDevice.systemVersion,TGHasGlassAPI()?@"available":@"unavailable",
      NSClassFromString(@"TTKTabBar")?@"present":@"absent",UIAccessibilityIsReduceTransparencyEnabled()?@"yes":@"no",UIAccessibilityIsReduceMotionEnabled()?@"yes":@"no"];
    for (NSString *key in [[observed allKeys] sortedArrayUsingSelector:@selector(compare:)]) [s appendFormat:@"%@\n",key];
    return s;
}
