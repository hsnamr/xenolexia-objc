//
//  main.m
//  Xenolexia (iOS)
//
//  iOS entry point. Sets shared SSAppDelegate (app logic) then runs UIKit.
//

#import <UIKit/UIKit.h>
#import "XLiOSAppDelegate.h"
#import "SSHostApplication.h"
#import "../../../Core/Services/XLStorageService.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

#if TARGET_OS_IPHONE

/// Minimal app delegate that conforms to SSAppDelegate and starts storage + shows UI.
/// Full Xenolexia logic (library, reader, vocabulary, etc.) can be shared with desktop when abstracted.
@interface XLiOSAppLogic : NSObject <SSAppDelegate, XLStorageServiceDelegate>
@end

@implementation XLiOSAppLogic

- (void)applicationDidFinishLaunching {
    [[XLStorageService sharedService] initializeDatabaseWithDelegate:self];
}

- (void)applicationWillTerminate {
}

- (void)storageService:(id)service didInitializeDatabaseWithSuccess:(BOOL)success error:(NSError *)error {
    (void)service;
    if (!success && error) {
        NSLog(@"Xenolexia iOS: database init failed: %@", error);
    }
}

- (void)storageService:(id)service didGetPreferences:(id)prefs withError:(NSError *)error {
    (void)service;
    (void)prefs;
    (void)error;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        static XLiOSAppLogic *s_logic = nil;
        s_logic = [[XLiOSAppLogic alloc] init];
        [SSHostApplication setAppDelegate:s_logic];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([XLiOSAppDelegate class]));
    }
}

#endif
