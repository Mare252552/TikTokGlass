#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface TGGlass : NSObject
+ (instancetype)shared;
- (void)beginPass;
- (void)applyToView:(UIView *)view category:(NSString *)category;
- (void)applyToTabBar:(UIView *)bar buttons:(NSArray<UIView *> *)buttons;
- (void)applyToNativeBar:(UIView *)bar;
- (void)endPass;
- (void)restoreAll;
@end
NS_ASSUME_NONNULL_END
