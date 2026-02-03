//
//  XLReaderWindowController.h
//  Xenolexia
//
//  Reader window controller for Linux (GNUStep)

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Book.h"
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Models/Language.h"
#import "../../../Core/Services/XLManager.h"

@protocol XLReaderWindowDelegate <NSObject>
- (void)readerDidClose;
- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData;
- (void)readerDidRequestSettings;
@optional
- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData contextSentence:(NSString *)contextSentence;
@end

@interface XLReaderWindowController : NSWindowController <XLManagerDelegate, NSTextViewDelegate, XLStorageServiceDelegate> {
    XLBook *_book;
    XLProcessedChapter *_currentChapter;
    NSInteger _currentChapterIndex;
    NSArray *_chapters;
    
    // UI Elements
    NSScrollView *_scrollView;
    NSTextView *_textView;
    NSButton *_prevChapterButton;
    NSButton *_nextChapterButton;
    NSPopUpButton *_chapterMenu;
    NSProgressIndicator *_progressIndicator;
    NSTextField *_progressLabel;
    NSButton *_settingsButton;
    
    // Reader settings
    XLReaderSettings *_settings;
    
    // Foreign word tracking
    NSMutableArray *_foreignWordRanges;
    NSMutableDictionary *_foreignWordDataMap;
    
    // Reading session (Phase 1)
    NSString *_sessionId;
    NSInteger _wordsRevealed;
    NSInteger _wordsSaved;
    // User preferences (Phase 4): applied when processing chapters
    XLUserPreferences *_userPrefs;
    BOOL _isInitialPrefsLoad;
}

@property (nonatomic, assign) id<XLReaderWindowDelegate> delegate;

- (instancetype)initWithBook:(XLBook *)book;
- (XLBook *)book;
- (void)reloadPreferences;

@end
