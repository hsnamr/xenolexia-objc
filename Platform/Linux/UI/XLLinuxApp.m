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
}

- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData {
    if (!wordData || !wordData.wordEntry) {
        return;
    }
    
    // Create vocabulary item from word data
    XLVocabularyItem *item = [[XLVocabularyItem alloc] init];
    item.itemId = [[NSUUID UUID] UUIDString];
    item.sourceWord = wordData.originalWord;
    item.targetWord = wordData.wordEntry.targetWord;
    item.sourceLanguage = wordData.wordEntry.sourceLanguage;
    item.targetLanguage = wordData.wordEntry.targetLanguage;
    item.contextSentence = wordData.wordEntry.contextSentence;
    item.bookId = _readerController ? [_readerController book].bookId : nil;
    item.addedAt = [NSDate date];
    item.status = XLVocabularyStatusNew;
    
    // Save to vocabulary
    XLManager *manager = [XLManager sharedManager];
    [manager saveWordToVocabulary:item delegate:self];
    
    [item release];
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
