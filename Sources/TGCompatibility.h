#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT BOOL TGSupportedHost(void);
FOUNDATION_EXPORT BOOL TGHasGlassAPI(void);
FOUNDATION_EXPORT BOOL TGIsOwnedView(UIView *view);
FOUNDATION_EXPORT NSArray<UIView *> * _Nullable TGTabButtons(UIView *view);
FOUNDATION_EXPORT NSString * _Nullable TGCategory(UIView *view);
FOUNDATION_EXPORT void TGRecord(UIView *view, NSString *category);
FOUNDATION_EXPORT NSString *TGDiagnosticReport(void);
NS_ASSUME_NONNULL_END
