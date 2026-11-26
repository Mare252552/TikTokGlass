#import "TGNavigation.h"
#import "TGCompatibility.h"
#ifndef TG_TESTING
__attribute__((constructor)) static void TikTokGlassStart(void) {
    @autoreleasepool {
        if (!TGSupportedHost() || !TGHasGlassAPI()) return;
        dispatch_async(dispatch_get_main_queue(),^{[TGNavigation.shared start];});
    }
}
#endif
