//
//  XLiOSAppDelegate.m
//  Xenolexia (iOS)
//
//  Uses SmallStep SSHostApplication to forward lifecycle to shared app logic.
//

#import "XLiOSAppDelegate.h"
#import "SSHostApplication.h"
#import "SSAppDelegate.h"
#import "SSPlatform.h"

#if TARGET_OS_IPHONE

@interface XLiOSAppDelegate ()
@end

@implementation XLiOSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    // Forward to shared app delegate (set from main.m before UIApplicationMain)
    id<SSAppDelegate> appDelegate = [SSHostApplication appDelegate];
    if ([appDelegate respondsToSelector:@selector(applicationDidFinishLaunching)]) {
        [appDelegate applicationDidFinishLaunching];
    }

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor systemBackgroundColor];
    self.window.rootViewController = [self createRootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (UIViewController *)createRootViewController {
    // Placeholder: tab bar or navigation with Library, Vocabulary, Review, Settings, Statistics.
    UIViewController *root = [[UIViewController alloc] init];
    root.title = @"Xenolexia";
    root.view.backgroundColor = [UIColor systemBackgroundColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    [root release];
    return [nav autorelease];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    (void)application;
    id<SSAppDelegate> appDelegate = [SSHostApplication appDelegate];
    if ([appDelegate respondsToSelector:@selector(applicationWillTerminate)]) {
        [appDelegate applicationWillTerminate];
    }
}

- (void)dealloc {
    [_window release];
    [super dealloc];
}

@end

#endif
