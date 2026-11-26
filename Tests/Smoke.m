// Synthetic UIKit fixtures verify library behavior, NOT TikTok's actual hierarchy.
#import <UIKit/UIKit.h>
#import "TGCompatibility.h"
#import "TGGlass.h"
#import "TGSettings.h"
#import <stdlib.h>
@interface TTKTabBar : UIView
@property(nonatomic,strong) id testButtons;
- (id)buttons;
@end
@implementation TTKTabBar
- (id)buttons {return self.testButtons;}
@end
static void Check(BOOL condition,NSString *message) {if(!condition) [NSException raise:@"TestFailure" format:@"%@",message];}
@interface TGSmokeDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation TGSmokeDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:CGRectMake(0,0,393,852)];
    self.window.rootViewController=[UIViewController new];[self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(),^{[self runTests];});return YES;
}
- (void)runTests {
    NSMutableArray *passed=[NSMutableArray new];NSString *failure=nil;
    @try {
        Check(TGHasGlassAPI(),@"native iOS 26 glass APIs available");[passed addObject:@"native API availability"];
        TTKTabBar *tab=[[TTKTabBar alloc] initWithFrame:CGRectMake(0,0,350,64)];
        UIButton *first=[UIButton buttonWithType:UIButtonTypeSystem],*second=[UIButton buttonWithType:UIButtonTypeSystem];
        first.frame=CGRectMake(0,0,160,60);second.frame=CGRectMake(175,0,160,60);[tab addSubview:first];[tab addSubview:second];
        tab.testButtons=@42;Check(TGTabButtons(tab)==nil,@"reject nonarray accessor value");
        tab.testButtons=@[first,[UIView new]];Check(TGTabButtons(tab)==nil,@"reject foreign hierarchy");
        tab.testButtons=@[first,second];Check(TGTabButtons(tab).count==2,@"accept valid descendant controls");[passed addObject:@"tab accessor/hierarchy guards"];
        UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];button.frame=CGRectMake(0,0,80,44);button.backgroundColor=UIColor.redColor;button.accessibilityLabel=@"Search";
        [self.window.rootViewController.view addSubview:button];
        Check([TGCategory(button) isEqualToString:@"search"],@"semantic search match");
        UITextField *field=[[UITextField alloc] initWithFrame:CGRectMake(0,0,180,44)];[field addSubview:button];
        Check(TGCategory(button)==nil,@"exclude text-entry hierarchy");[button removeFromSuperview];[self.window.rootViewController.view addSubview:button];
        [passed addObject:@"semantic discovery and input exclusion"];
        TGGlass *glass=TGGlass.shared;[glass beginPass];[glass applyToView:button category:@"search"];[glass endPass];
        NSUInteger count=button.subviews.count;[glass beginPass];[glass applyToView:button category:@"search"];[glass endPass];
        Check(count==button.subviews.count,@"repeated discovery must not duplicate overlays");
        UIVisualEffectView *effect=nil;for(UIView *v in button.subviews) if([v isKindOfClass:UIVisualEffectView.class]) effect=(id)v;
        Check([effect.effect isKindOfClass:UIGlassEffect.class],@"actual glass effect object, not blur");
        Check(!effect.userInteractionEnabled,@"decorative plate preserves hit testing");
        [glass restoreAll];Check(effect.superview==nil,@"overlay removed");Check([button.backgroundColor isEqual:UIColor.redColor],@"original background restored");
        [passed addObject:@"real glass, idempotence, touch and background restoration"];
        [glass beginPass];[glass applyToTabBar:tab buttons:@[first,second]];[glass endPass];
        UIVisualEffectView *container=nil;for(UIView *v in tab.subviews) if([v isKindOfClass:UIVisualEffectView.class]) container=(id)v;
        Check([container.effect isKindOfClass:UIGlassContainerEffect.class],@"real container effect");Check(container.contentView.subviews.count==2,@"two child plates");
        Check(first.superview==tab && second.superview==tab,@"host navigation controls not reparented");[glass restoreAll];[passed addObject:@"native container and original tab ownership"];
        UINavigationBar *nav=[[UINavigationBar alloc] initWithFrame:CGRectMake(0,0,350,64)];
        UINavigationBarAppearance *original=[nav.standardAppearance copy];original.backgroundColor=UIColor.greenColor;nav.standardAppearance=original;
        [glass beginPass];[glass applyToNativeBar:nav];[glass endPass];[glass restoreAll];
        Check([nav.standardAppearance.backgroundColor isEqual:UIColor.greenColor],@"native appearance restored");[passed addObject:@"navigation appearance restoration"];
        TGSettings.shared.intensity=2;Check(TGSettings.shared.intensity==1,@"clamp upper intensity");TGSettings.shared.intensity=-1;Check(TGSettings.shared.intensity==0,@"clamp lower intensity");
        [TGSettings.shared setEnabled:NO key:@"enabled"];
        NSUserDefaults *fresh=[[NSUserDefaults alloc] initWithSuiteName:@"dev.tiktokglass.preferences"];
        Check([fresh objectForKey:@"enabled"]!=nil && ![fresh boolForKey:@"enabled"],@"preferences retained in same suite");
        [TGSettings.shared setEnabled:YES key:@"enabled"];TGSettings.shared.intensity=0.5;[passed addObject:@"preferences storage and intensity bounds"];
    } @catch(NSException *e) {failure=[NSString stringWithFormat:@"%@: %@",e.name,e.reason];}
    NSDictionary *report=@{@"passed":passed,@"failure":failure ?: NSNull.null,@"scope":@"Synthetic UIKit library tests; no TikTok or physical device tested"};
    NSData *data=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/smoke-results.json"];
    [data writeToFile:path atomically:YES];NSLog(@"TikTokGlass smoke report: %@",report);exit(failure?1:0);
}
@end
int main(int argc,char **argv) {@autoreleasepool {return UIApplicationMain(argc,argv,nil,NSStringFromClass(TGSmokeDelegate.class));}}
