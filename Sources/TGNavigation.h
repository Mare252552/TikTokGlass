#import <UIKit/UIKit.h>
@interface TGNavigation : NSObject
+ (instancetype)shared;
- (void)start;
- (void)refresh;
@end
