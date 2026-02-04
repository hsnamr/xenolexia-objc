//
//  SSAppDelegate.h
//  SmallStep
//
//  Cross-platform app lifecycle delegate (GNUStep/Linux, AppKit/macOS, UIKit/iOS).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Cross-platform application lifecycle delegate.
/// Implement this in your app logic; host platforms (SSHostApplication, NSApplicationDelegate, or UIApplicationDelegate) forward to it.
@protocol SSAppDelegate <NSObject>

@optional
/// Called when the application has finished launching (after UI is ready on iOS).
- (void)applicationDidFinishLaunching;

/// Called when the application is about to terminate.
- (void)applicationWillTerminate;

/// Called when the application will finish launching (before windows/UI on desktop).
- (void)applicationWillFinishLaunching;

/// Called to ask whether the app should terminate when the last window is closed (desktop). Return YES/NO.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender;

@end

NS_ASSUME_NONNULL_END
