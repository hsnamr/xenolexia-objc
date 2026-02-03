//
//  XLReaderWindowController.h
//  Xenolexia
//
//  Reader window controller for Linux (GNUStep)

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Book.h"
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Services/XLManager.h"

@protocol XLReaderWindowDelegate <NSObject>
- (void)readerDidClose;
- (void)readerDidRequestSaveWord:(XLForeignWordData *)wordData;
@end

@interface XLReaderWindowController : NSWindowController <XLManagerDelegate, NSTextViewDelegate> {
    id _delegate;
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
}

- (instancetype)initWithBook:(XLBook *)book;
- (XLBook *)book;

@end
