#import "TGNavigation.h"
#import "TGGlass.h"
#import "TGSettings.h"
#import "TGCompatibility.h"
#import <objc/runtime.h>

static char gestureKey, launcherKey;
@interface TGNavigation () <UIGestureRecognizerDelegate>
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic) BOOL refreshing;
@end
@implementation TGNavigation
+ (instancetype)shared {static TGNavigation *n;static dispatch_once_t once;dispatch_once(&once,^{n=[self new];});return n;}
- (void)start {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:TGPreferencesChanged object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:UIAccessibilityReduceTransparencyStatusDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:UIAccessibilityVoiceOverStatusDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:UIApplicationDidBecomeActiveNotification object:nil];
    // No global UIView swizzle, Substrate, jailbreak loader, private navigation invocation or polling video models.
    self.timer=[NSTimer timerWithTimeInterval:0.8 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    self.timer.tolerance=0.2;[NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];[self refresh];
}
- (NSArray<UIWindow *> *)windows {
    NSMutableArray *windows=[NSMutableArray new];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState!=UISceneActivationStateForegroundActive || ![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) if (!window.hidden && window.alpha>0 && window.windowLevel==UIWindowLevelNormal && window.rootViewController) [windows addObject:window];
    }return windows;
}
- (void)installSettingsEntry:(UIWindow *)window {
    if (!objc_getAssociatedObject(window,&gestureKey)) {
        UITapGestureRecognizer *gesture=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSettings:)];
        gesture.numberOfTouchesRequired=3;gesture.numberOfTapsRequired=3;gesture.cancelsTouchesInView=NO;gesture.delegate=self;
        [window addGestureRecognizer:gesture];objc_setAssociatedObject(window,&gestureKey,gesture,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIButton *launcher=objc_getAssociatedObject(window,&launcherKey);
    if (UIAccessibilityIsVoiceOverRunning()) {
        if (!launcher) {
            launcher=[UIButton buttonWithType:UIButtonTypeSystem];launcher.accessibilityIdentifier=@"TikTokGlass.SettingsLauncher";
            [launcher setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];launcher.accessibilityLabel=@"TikTokGlass settings";
            launcher.backgroundColor=UIColor.secondarySystemBackgroundColor;launcher.layer.cornerRadius=22;
            [launcher addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:launcher];objc_setAssociatedObject(window,&launcherKey,launcher,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        launcher.frame=CGRectMake(window.bounds.size.width-window.safeAreaInsets.right-52,window.safeAreaInsets.top+8,44,44);[window bringSubviewToFront:launcher];
    } else if (launcher) {[launcher removeFromSuperview];objc_setAssociatedObject(window,&launcherKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {return YES;}
- (void)openSettings:(id)sender {
    UIWindow *window=[sender isKindOfClass:UIGestureRecognizer.class]?[(UIGestureRecognizer *)sender view].window:([sender isKindOfClass:UIView.class]?[(UIView *)sender window]:nil);
    if (!window) window=self.windows.firstObject; UIViewController *top=window.rootViewController;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top=top.presentedViewController;
    if (!top || [top isKindOfClass:UINavigationController.class] && [((UINavigationController *)top).topViewController isKindOfClass:TGSettingsController.class]) return;
    UINavigationController *nav=[[UINavigationController alloc] initWithRootViewController:[TGSettingsController new]];
    nav.modalPresentationStyle=UIModalPresentationPageSheet;[top presentViewController:nav animated:!UIAccessibilityIsReduceMotionEnabled() completion:nil];
}
- (void)refresh {
    if (!NSThread.isMainThread) {dispatch_async(dispatch_get_main_queue(),^{[self refresh];});return;}
    if (self.refreshing || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive) return;
    self.refreshing=YES;
    @try {
        TGSettings *settings=TGSettings.shared;TGGlass *glass=TGGlass.shared;
        [glass beginPass];
        BOOL enabled=[settings enabled:@"enabled"] && TGHasGlassAPI() && !UIAccessibilityIsReduceTransparencyEnabled();
        for (UIWindow *window in self.windows) {
            [self installSettingsEntry:window]; if (!enabled) continue;
            NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:window];NSUInteger cursor=0;
            // Bounded, breadth-first traversal. Existing overlays get restored if no longer matched.
            while (cursor<queue.count && cursor<2500) {
                UIView *view=queue[cursor++];
                if (view.hidden || view.alpha<0.05 || TGIsOwnedView(view) || [view isKindOfClass:UIVisualEffectView.class]) continue;
                if ([view isKindOfClass:NSClassFromString(@"WKWebView")]) continue;
                if ([view isKindOfClass:UITabBar.class]) {if([settings enabled:@"tabBar"]) [glass applyToNativeBar:view];continue;}
                if ([view isKindOfClass:UINavigationBar.class]) {if([settings enabled:@"navigation"]) [glass applyToNativeBar:view];continue;}
                NSArray *buttons=TGTabButtons(view);
                if (buttons) {if([settings enabled:@"tabBar"]) [glass applyToTabBar:view buttons:buttons];continue;}
                NSString *category=TGCategory(view);
                if (category && [settings enabled:category]) {[glass applyToView:view category:category];continue;}
                // Copy before appending because effect insertion mutates subviews.
                if (queue.count<3000) [queue addObjectsFromArray:[view.subviews copy]];
            }
        }[glass endPass];
    } @catch (NSException *exception) {
        [TGGlass.shared restoreAll];
        // Fail closed for this session; do not repeatedly crash on an incompatible runtime tree.
        [TGSettings.shared.defaults setBool:NO forKey:@"enabled"];
        NSLog(@"[TikTokGlass] disabled after incompatible UI operation (%@)",exception.name);
    } @finally {self.refreshing=NO;}
}
@end
