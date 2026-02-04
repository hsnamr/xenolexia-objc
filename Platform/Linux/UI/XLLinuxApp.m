//
//  XLLinuxApp.m
//  Xenolexia
//

#import "XLLinuxApp.h"
#import "Screens/XLLibraryWindowController.h"
#import "Screens/XLBookDetailWindowController.h"
#import "Screens/XLReaderWindowController.h"
#import "../../../Core/Services/XLStorageService.h"
#import "../../../Core/Services/XLManager.h"
#import "../../../Core/Models/Vocabulary.h"
#import "SSHostApplication.h"
#import "SSMainMenu.h"

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
        _readerController = nil;
        _vocabularyController = nil;
        _reviewController = nil;
        _settingsController = nil;
        _onboardingController = nil;
        _statisticsController = nil;
    }
    return self;
}

- (void)run {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    XLStorageService *storage = [XLStorageService sharedService];
    [storage initializeDatabaseWithDelegate:self];

    [SSHostApplication runWithDelegate:self];

    [pool drain];
}

#pragma mark - XLLibraryWindowDelegate

- (void)libraryDidSelectBook:(XLBook *)book {
    [self openReaderForBook:book];
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

- (void)libraryDidRequestVocabulary {
    if (!_vocabularyController) {
        _vocabularyController = [[XLVocabularyWindowController alloc] init];
        [_vocabularyController setDelegate:self];
    }
    [_vocabularyController showWindow:nil];
}

- (void)libraryDidRequestReview {
    if (!_reviewController) {
        _reviewController = [[XLReviewWindowController alloc] init];
        [_reviewController setDelegate:self];
    }
    [_reviewController showWindow:nil];
}

- (void)vocabularyWindowDidClose {
    [_vocabularyController release];
    _vocabularyController = nil;
}

- (void)vocabularyDidRequestReview {
    [self libraryDidRequestReview];
}

- (void)reviewWindowDidClose {
    [_reviewController release];
    _reviewController = nil;
}

- (void)libraryDidRequestSettings {
    if (!_settingsController) {
        _settingsController = [[XLSettingsWindowController alloc] init];
        [_settingsController setDelegate:self];
    }
    [_settingsController showWindow:nil];
}

- (void)settingsWindowDidClose {
    if (_readerController && [_readerController respondsToSelector:@selector(reloadPreferences)]) {
        [_readerController reloadPreferences];
    }
    [_settingsController release];
    _settingsController = nil;
}

- (void)libraryDidRequestStatistics {
    if (!_statisticsController) {
        _statisticsController = [[XLStatisticsWindowController alloc] init];
        [_statisticsController setDelegate:self];
    }
    [_statisticsController showWindow:nil];
}

- (void)statisticsWindowDidClose {
    [_statisticsController release];
    _statisticsController = nil;
}

- (void)onboardingDidComplete {
    [_onboardingController release];
    _onboardingController = nil;
    if (!_libraryController) {
        _libraryController = [[XLLibraryWindowController alloc] init];
        [_libraryController setDelegate:self];
        [_libraryController showWindow:nil];
    }
}

#pragma mark - XLBookDetailWindowDelegate

- (void)bookDetailDidRequestStartReading:(XLBook *)book {
    [self openReaderForBook:book];
}

- (void)openReaderForBook:(XLBook *)book {
    if (!book) {
        return;
    }
    
    // Close existing reader if open
    if (_readerController) {
        [[_readerController window] close];
        _readerController = nil;
    }
    
    // Create and show reader
    _readerController = [[XLReaderWindowController alloc] initWithBook:book];
    [_readerController setDelegate:self];
    [_readerController showWindow:nil];
}

- (void)bookDetailDidRequestDelete:(XLBook *)book {
    XLStorageService *storage = [XLStorageService sharedService];
    [storage deleteBookWithId:book.bookId delegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didInitializeDatabaseWithSuccess:(BOOL)success error:(NSError *)error {
    if (!success) {
        NSLog(@"Failed to initialize database: %@", error);
        return;
    }
    [service getPreferencesWithDelegate:self];
}

- (void)storageService:(id)service didGetPreferences:(XLUserPreferences *)prefs withError:(NSError *)error {
    if (error || !prefs) {
        _libraryController = [[XLLibraryWindowController alloc] init];
        [_libraryController setDelegate:self];
        [_libraryController showWindow:nil];
        return;
    }
    if (prefs.hasCompletedOnboarding) {
        _libraryController = [[XLLibraryWindowController alloc] init];
        [_libraryController setDelegate:self];
        [_libraryController showWindow:nil];
    } else {
        _onboardingController = [[XLOnboardingWindowController alloc] init];
        [_onboardingController setDelegate:self];
        [_onboardingController showWindow:nil];
    }
}

- (void)storageService:(id)service didDeleteBookWithId:(NSString *)bookId withSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [_libraryController refreshBooks];
    }
}

#pragma mark - XLManagerDelegate

- (void)manager:(id)manager didSaveWordToVocabulary:(XLVocabularyItem *)item withSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        NSLog(@"Word saved to vocabulary: %@", item.sourceWord);
    } else {
        NSLog(@"Error saving word to vocabulary: %@", error);
    }
}

- (void)bookDetailDidClose {
    _bookDetailController = nil;
}

#pragma mark - XLReaderWindowDelegate

- (void)readerDidClose {
    _readerController = nil;
    [_libraryController refreshBooks];
}

- (void)readerDidRequestSettings {
    [self libraryDidRequestSettings];
}

- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData {
    [self readerDidRequestSaveWord:wordData contextSentence:nil];
}

- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData contextSentence:(NSString *)contextSentence {
    if (!wordData || !wordData.wordEntry) {
        return;
    }
    
    /* Create vocabulary item from word data */
    XLVocabularyItem *item = [[XLVocabularyItem alloc] init];
    item.vocabularyId = [[NSUUID UUID] UUIDString];
    item.sourceWord = wordData.originalWord;
    item.targetWord = wordData.wordEntry.targetWord;
    item.sourceLanguage = wordData.wordEntry.sourceLanguage;
    item.targetLanguage = wordData.wordEntry.targetLanguage;
    item.contextSentence = contextSentence ? [contextSentence copy] : nil;
    item.bookId = _readerController ? [_readerController book].bookId : nil;
    item.addedAt = [NSDate date];
    item.status = XLVocabularyStatusNew;
    
    XLManager *manager = [XLManager sharedManager];
    [manager saveWordToVocabulary:item delegate:self];
    
    [item release];
}

- (void)applicationWillFinishLaunching {
    // Initialize app
}

- (void)applicationDidFinishLaunching {
    [self setupMainMenu];
    [self setupTrayIcon];
}

- (void)setupMainMenu {
    SSMainMenu *mainMenu = [[[SSMainMenu alloc] init] autorelease];
    [mainMenu setAppName:@"Xenolexia"];
    NSArray *items = @[
        [SSMainMenuItem itemWithTitle:@"Library" action:@selector(showLibrary:) keyEquivalent:@"1" modifierMask:NSControlKeyMask target:self],
        [SSMainMenuItem itemWithTitle:@"Vocabulary" action:@selector(showVocabulary:) keyEquivalent:@"2" modifierMask:NSControlKeyMask target:self],
        [SSMainMenuItem itemWithTitle:@"Review" action:@selector(showReview:) keyEquivalent:@"3" modifierMask:NSControlKeyMask target:self],
        [SSMainMenuItem itemWithTitle:@"Settings" action:@selector(showSettings:) keyEquivalent:@"4" modifierMask:NSControlKeyMask target:self],
        [SSMainMenuItem itemWithTitle:@"Statistics" action:@selector(showStatistics:) keyEquivalent:@"5" modifierMask:NSControlKeyMask target:self],
    ];
    [mainMenu buildMenuWithItems:items quitTitle:@"Quit Xenolexia" quitKeyEquivalent:@"q"];
}

- (void)showLibrary:(id)sender {
    (void)sender;
    if (_libraryController) {
        [[_libraryController window] makeKeyAndOrderFront:nil];
    }
}

- (void)showVocabulary:(id)sender {
    (void)sender;
    [self libraryDidRequestVocabulary];
}

- (void)showReview:(id)sender {
    (void)sender;
    [self libraryDidRequestReview];
}

- (void)showSettings:(id)sender {
    (void)sender;
    [self libraryDidRequestSettings];
}

- (void)showStatistics:(id)sender {
    (void)sender;
    [self libraryDidRequestStatistics];
}

- (void)setupTrayIcon {
#if defined(__APPLE__) && !defined(GNUSTEP_BASE_VERSION)
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    if (!bar) return;
    _statusItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
    if (!_statusItem) return;
    [_statusItem setTitle:@"X"];
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *showHideItem = [[NSMenuItem alloc] initWithTitle:@"Show/Hide" action:@selector(trayShowHide:) keyEquivalent:@""];
    [showHideItem setTarget:self];
    [menu addItem:showHideItem];
    [showHideItem release];
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(trayQuit:) keyEquivalent:@""];
    [quitItem setTarget:self];
    [menu addItem:quitItem];
    [quitItem release];
    [_statusItem setMenu:menu];
    [menu release];
#else
    /* System tray (NSStatusBar) N/A on GNUStep/Linux */
#endif
}

- (void)trayShowHide:(id)sender {
    (void)sender;
    if (_libraryController && [_libraryController window]) {
        NSWindow *w = [_libraryController window];
        if ([w isVisible]) {
            [w orderOut:nil];
        } else {
            [w makeKeyAndOrderFront:nil];
        }
    }
}

- (void)trayQuit:(id)sender {
    (void)sender;
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate {
    if (_libraryController && [_libraryController respondsToSelector:@selector(saveWindowState)]) {
        [_libraryController performSelector:@selector(saveWindowState)];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender {
    (void)sender;
    return YES;
}

@end
