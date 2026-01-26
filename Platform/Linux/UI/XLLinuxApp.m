//
//  XLLinuxApp.m
//  Xenolexia
//

#import "XLLinuxApp.h"
#import "Screens/XLLibraryWindowController.h"

@implementation XLLinuxApp

+ (instancetype)sharedApp {
    static XLLinuxApp *sharedApp = nil;
    if (sharedApp == nil) {
        sharedApp = [[self alloc] init];
    }
    return sharedApp;
}

- (void)run {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:self];
    
    // Create and show main window
    XLLibraryWindowController *libraryController = [[XLLibraryWindowController alloc] init];
    [libraryController showWindow:nil];
    
    [app run];
    
    [pool drain];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // Initialize app
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // App finished launching
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender {
    return YES;
}

@end
