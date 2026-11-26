#import "TGGlass.h"
#import "TGSettings.h"
#import "TGCompatibility.h"
#import <objc/runtime.h>

@interface TGGlassState : NSObject
@property(nonatomic,weak) UIView *host;
@property(nonatomic,strong) UIVisualEffectView *effectView;
@property(nonatomic,strong) UIColor *background;
@property(nonatomic,strong) id standardAppearance;
@property(nonatomic,strong) id scrollAppearance;
@property(nonatomic,strong) id compactAppearance;
@property(nonatomic,strong) id compactScrollAppearance;
@property(nonatomic) BOOL visited;
@property(nonatomic) double intensity;
@property(nonatomic) NSUInteger plateCount;
@property(nonatomic) NSInteger kind;
@end
@implementation TGGlassState
@end
static char stateKey;
@interface TGGlass ()
@property(nonatomic,strong) NSHashTable<TGGlassState *> *states;
@end
@implementation TGGlass
+ (instancetype)shared { static TGGlass *s; static dispatch_once_t once; dispatch_once(&once,^{s=[self new];s.states=[NSHashTable weakObjectsHashTable];}); return s; }
- (UIGlassEffect *)effect API_AVAILABLE(ios(26.0)) {
    UIGlassEffect *effect=[UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
    effect.interactive=YES;
    // Tint strength only. There is no public Liquid Glass intensity API.
    effect.tintColor=[UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:0.02+0.18*[TGSettings shared].intensity];
    return effect;
}
- (void)animate:(void (^)(void))changes {
    if (UIAccessibilityIsReduceMotionEnabled()) changes();
    else [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:changes completion:nil];
}
- (void)beginPass { for (TGGlassState *s in self.states) s.visited=NO; }
- (TGGlassState *)state:(UIView *)view kind:(NSInteger)kind {
    TGGlassState *s=objc_getAssociatedObject(view,&stateKey);
    if (!s) {
        s=[TGGlassState new]; s.host=view;s.background=view.backgroundColor;s.kind=kind;s.intensity=-1;
        objc_setAssociatedObject(view,&stateKey,s,OBJC_ASSOCIATION_RETAIN_NONATOMIC);[self.states addObject:s];
    } s.visited=YES; return s;
}
- (UIVisualEffectView *)newEffectView {
    UIVisualEffectView *v=[[UIVisualEffectView alloc] initWithEffect:nil];
    v.accessibilityIdentifier=@"TikTokGlass.Effect";v.userInteractionEnabled=NO;v.accessibilityElementsHidden=YES;
    return v;
}
- (void)applyToView:(UIView *)view category:(NSString *)category {
    if (@available(iOS 26.0,*)) {
        TGGlassState *s=[self state:view kind:0];
        if (!s.effectView) {s.effectView=[self newEffectView];[view insertSubview:s.effectView atIndex:0];}
        if (s.effectView.superview!=view) [view insertSubview:s.effectView atIndex:0];
        s.effectView.frame=view.bounds;
        s.effectView.layer.cornerRadius=fmin(22,view.bounds.size.height/2);s.effectView.clipsToBounds=YES;
        view.backgroundColor=UIColor.clearColor;
        if (s.intensity!=[TGSettings shared].intensity) {s.intensity=[TGSettings shared].intensity; [self animate:^{s.effectView.effect=[self effect];}];}
        if ([view isKindOfClass:UIControl.class]) {
            UIControl *control=(UIControl *)view;
            [control removeTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
            [control addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
            [control removeTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
            [control addTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        }
        TGRecord(view,category);
    }
}
- (void)pressed:(UIControl *)sender {
    if (@available(iOS 26.0,*)) {
        TGGlassState *s=objc_getAssociatedObject(sender,&stateKey); if (!s) return;
        UIGlassEffect *effect=[self effect];effect.tintColor=[UIColor.systemBlueColor colorWithAlphaComponent:0.2];
        [self animate:^{s.effectView.effect=effect;}];
    }
}
- (void)released:(UIControl *)sender {
    if (@available(iOS 26.0,*)) { TGGlassState *s=objc_getAssociatedObject(sender,&stateKey); if(s) [self animate:^{s.effectView.effect=[self effect];}]; }
}
- (void)applyToTabBar:(UIView *)bar buttons:(NSArray<UIView *> *)buttons {
    if (@available(iOS 26.0,*)) {
        TGGlassState *s=[self state:bar kind:1];
        if (!s.effectView) {
            UIGlassContainerEffect *container=[UIGlassContainerEffect new];container.spacing=12;
            s.effectView=[self newEffectView];s.effectView.effect=container;
            [bar insertSubview:s.effectView atIndex:0];
        }
        s.effectView.frame=bar.bounds;bar.backgroundColor=UIColor.clearColor;
        if (s.effectView.superview!=bar) [bar insertSubview:s.effectView atIndex:0];
        if (s.plateCount!=buttons.count) {
            for (UIView *v in [s.effectView.contentView.subviews copy]) [v removeFromSuperview];
            for (NSUInteger i=0;i<buttons.count;i++) [s.effectView.contentView addSubview:[self newEffectView]];
            s.plateCount=buttons.count;s.intensity=-1;
        }
        BOOL update=s.intensity!=[TGSettings shared].intensity;s.intensity=[TGSettings shared].intensity;
        [buttons enumerateObjectsUsingBlock:^(UIView *button,NSUInteger i,BOOL *stop){
            UIVisualEffectView *plate=(id)s.effectView.contentView.subviews[i];
            CGRect rect=[button convertRect:button.bounds toView:bar];
            rect=CGRectIntersection(bar.bounds,CGRectInset(rect,3,2));
            if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {plate.hidden=YES;return;}
            plate.hidden=NO;plate.frame=rect;plate.layer.cornerRadius=fmin(26,rect.size.height/2);plate.clipsToBounds=YES;
            if(update) [self animate:^{plate.effect=[self effect];}];
        }];
        TGRecord(bar,@"tabBar");
    }
}
- (void)applyToNativeBar:(UIView *)bar {
    if (@available(iOS 26.0,*)) {
        TGGlassState *s=[self state:bar kind:2];
        if (!s.effectView) {s.effectView=[self newEffectView];[bar insertSubview:s.effectView atIndex:0];}
        if (s.effectView.superview!=bar) [bar insertSubview:s.effectView atIndex:0];
        s.effectView.frame=bar.bounds;
        s.effectView.layer.cornerRadius=fmin(28,bar.bounds.size.height/2);s.effectView.clipsToBounds=YES;
        if ([bar isKindOfClass:UITabBar.class]) {
            UITabBar *tab=(id)bar;
            if (!s.standardAppearance) {s.standardAppearance=[tab.standardAppearance copy];s.scrollAppearance=[tab.scrollEdgeAppearance copy];}
            if (s.intensity==[TGSettings shared].intensity) return;
            // UIBarAppearance.backgroundEffect is UIBlurEffect-typed even in iOS 26.
            // Use a real glass effect VIEW instead; never cast glass to blur.
            UITabBarAppearance *a=[tab.standardAppearance copy];a.backgroundColor=UIColor.clearColor;a.backgroundImage=nil;a.backgroundEffect=nil;a.shadowColor=UIColor.clearColor;
            tab.standardAppearance=a;tab.scrollEdgeAppearance=a;
        } else if ([bar isKindOfClass:UINavigationBar.class]) {
            UINavigationBar *nav=(id)bar;
            if (!s.standardAppearance) {s.standardAppearance=[nav.standardAppearance copy];s.scrollAppearance=[nav.scrollEdgeAppearance copy];s.compactAppearance=[nav.compactAppearance copy];s.compactScrollAppearance=[nav.compactScrollEdgeAppearance copy];}
            if (s.intensity==[TGSettings shared].intensity) return;
            UINavigationBarAppearance *a=[nav.standardAppearance copy];a.backgroundColor=UIColor.clearColor;a.backgroundImage=nil;a.backgroundEffect=nil;
            nav.standardAppearance=a;nav.scrollEdgeAppearance=a;nav.compactAppearance=a;nav.compactScrollEdgeAppearance=a;
        }
        [self animate:^{s.effectView.effect=[self effect];}];
        s.intensity=[TGSettings shared].intensity;TGRecord(bar,@"nativeBar");
    }
}
- (void)restore:(TGGlassState *)s {
    UIView *view=s.host;if (!view) return;
    [s.effectView removeFromSuperview];
    if (s.kind<2) view.backgroundColor=s.background;
    if ([view isKindOfClass:UIControl.class]) {
        [(UIControl *)view removeTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
        [(UIControl *)view removeTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    }
    if ([view isKindOfClass:UITabBar.class] && s.standardAppearance) {UITabBar *bar=(id)view;bar.standardAppearance=s.standardAppearance;bar.scrollEdgeAppearance=s.scrollAppearance;}
    if ([view isKindOfClass:UINavigationBar.class] && s.standardAppearance) {UINavigationBar *bar=(id)view;bar.standardAppearance=s.standardAppearance;bar.scrollEdgeAppearance=s.scrollAppearance;bar.compactAppearance=s.compactAppearance;bar.compactScrollEdgeAppearance=s.compactScrollAppearance;}
    objc_setAssociatedObject(view,&stateKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)endPass { for (TGGlassState *s in self.states.allObjects) if (!s.visited) [self restore:s]; }
- (void)restoreAll { for (TGGlassState *s in self.states.allObjects) [self restore:s]; }
@end
