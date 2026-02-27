//
//  XLiOSAppDelegate.m
//  Xenolexia (iOS)
//
//  Uses SmallStep SSHostApplication to forward lifecycle to shared app logic.
//

#import "XLiOSAppDelegate.h"
#import "XLAboutViewController.h"
#import "XLiOSProfileViewController.h"
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
    // Tab bar aligned with xenolexia-typescript: Library, Vocabulary, Statistics, Profile
    UITabBarController *tabBar = [[[UITabBarController alloc] init] autorelease];

    UIViewController *libraryVC = [[[UIViewController alloc] init] autorelease];
    libraryVC.title = @"Library";
    libraryVC.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Library" image:nil tag:0] autorelease];
    libraryVC.view.backgroundColor = [UIColor systemBackgroundColor];
    UINavigationController *libraryNav = [[[UINavigationController alloc] initWithRootViewController:libraryVC] autorelease];

    UIViewController *vocabVC = [[[UIViewController alloc] init] autorelease];
    vocabVC.title = @"Vocabulary";
    vocabVC.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Words" image:nil tag:1] autorelease];
    vocabVC.view.backgroundColor = [UIColor systemBackgroundColor];
    UINavigationController *vocabNav = [[[UINavigationController alloc] initWithRootViewController:vocabVC] autorelease];

    UIViewController *statsVC = [[[UIViewController alloc] init] autorelease];
    statsVC.title = @"Statistics";
    statsVC.tabBarItem = [[[UITabBarItem alloc] initWithTitle:@"Stats" image:nil tag:2] autorelease];
    statsVC.view.backgroundColor = [UIColor systemBackgroundColor];
    UINavigationController *statsNav = [[[UINavigationController alloc] initWithRootViewController:statsVC] autorelease];

    XLiOSProfileViewController *profileVC = [[[XLiOSProfileViewController alloc] init] autorelease];
    UINavigationController *profileNav = [[[UINavigationController alloc] initWithRootViewController:profileVC] autorelease];

    tabBar.viewControllers = @[libraryNav, vocabNav, statsNav, profileNav];
    return tabBar;
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
