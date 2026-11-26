#import <UIKit/UIKit.h>
@interface TGFloatingBar : NSObject
- (instancetype)initWithHost:(UIView *)host buttons:(NSArray<UIView *> *)buttons;
- (void)update;
- (void)restore;
@end
