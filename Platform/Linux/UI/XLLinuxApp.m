//
//  XLLinuxApp.m
//  Xenolexia
//

#import "XLLinuxApp.h"
#import "Screens/XLLibraryWindowController.h"
#import "Screens/XLBookDetailWindowController.h"
#import "../../../Core/Services/XLStorageService.h"

@implementation XLLinuxApp

+ (instancetype)sharedApp {
    static XLLinuxApp *sharedApp = nil;
    if (sharedApp == nil) {
        sharedApp = [[self alloc] init];
    }
    return sharedApp;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _libraryController = nil;
        _bookDetailController = nil;
    }
    return self;
}

- (void)run {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:self];
    
    // Initialize database
    XLStorageService *storage = [XLStorageService sharedService];
    [storage initializeDatabaseWithDelegate:self];
    
    // Create and show main window
    _libraryController = [[XLLibraryWindowController alloc] init];
    [_libraryController setDelegate:self];
    [_libraryController showWindow:nil];
    
    [app run];
    
    [pool drain];
}

#pragma mark - XLLibraryWindowDelegate

- (void)libraryDidSelectBook:(XLBook *)book {
    // Open reader (to be implemented)
}

- (void)libraryDidRequestImport {
    // Import is handled by library controller
}

- (void)libraryDidRequestDeleteBook:(XLBook *)book {
    XLStorageService *storage = [XLStorageService sharedService];
    [storage deleteBookWithId:book.bookId delegate:self];
}

- (void)libraryDidRequestBookDetail:(XLBook *)book {
    _bookDetailController = [[XLBookDetailWindowController alloc] initWithBook:book];
    [_bookDetailController setDelegate:self];
    [_bookDetailController showWindow:nil];
}

#pragma mark - XLBookDetailWindowDelegate

- (void)bookDetailDidRequestStartReading:(XLBook *)book {
    // Open reader (to be implemented)
}

- (void)bookDetailDidRequestDelete:(XLBook *)book {
    XLStorageService *storage = [XLStorageService sharedService];
    [storage deleteBookWithId:book.bookId delegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didInitializeDatabaseWithSuccess:(BOOL)success error:(NSError *)error {
    if (!success) {
        NSLog(@"Failed to initialize database: %@", error);
    }
}

- (void)storageService:(id)service didDeleteBookWithId:(NSString *)bookId withSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [_libraryController refreshBooks];
    }
}

- (void)bookDetailDidClose {
    _bookDetailController = nil;
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
