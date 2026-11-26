#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSNotificationName const TGPreferencesChanged;
@interface TGSettings : NSObject
+ (instancetype)shared;
@property(nonatomic, readonly) NSUserDefaults *defaults;
- (BOOL)enabled:(NSString *)key;
- (void)setEnabled:(BOOL)value key:(NSString *)key;
@property(nonatomic) double intensity;
@property(nonatomic) double barHeight;
@property(nonatomic) double barInset;
@property(nonatomic) double glassOpacity;
@end
@interface TGSettingsController : UITableViewController
@end
NS_ASSUME_NONNULL_END
