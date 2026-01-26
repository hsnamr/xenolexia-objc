//
//  XLReaderWindowController.m
//  Xenolexia
//
//  Reader window controller implementation

#import "XLReaderWindowController.h"
#import "../../../../Core/Services/XLManager.h"
#import "../../../../Core/Services/XLBookParserService.h"

// Custom text view for foreign word click detection
@interface XLReaderTextView : NSTextView {
    id _readerController;
}
- (void)setReaderController:(id)controller;
@end

@implementation XLReaderTextView

- (void)setReaderController:(id)controller {
    _readerController = controller;
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint location = [event locationInWindow];
    NSPoint textViewLocation = [[self superview] convertPoint:location fromView:nil];
    
    // Get character index at click location
    NSUInteger charIndex = [self characterIndexForPoint:textViewLocation];
    
    if (charIndex != NSNotFound && _readerController) {
        // Call handler on controller
        if ([_readerController respondsToSelector:@selector(handleClickAtCharacterIndex:)]) {
            [_readerController handleClickAtCharacterIndex:charIndex];
        }
    }
    
    [super mouseDown:event];
}

@end

@implementation XLReaderWindowController

- (instancetype)initWithBook:(XLBook *)book {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _book = [book retain];
        _currentChapterIndex = book.currentChapter >= 0 ? book.currentChapter : 0;
        _chapters = nil;
        _currentChapter = nil;
        _foreignWordRanges = [[NSMutableArray alloc] init];
        _foreignWordDataMap = [[NSMutableDictionary alloc] init];
        _settings = [[XLReaderSettings defaultSettings] retain];
    }
    return self;
}

- (XLBook *)book {
    return _book;
}

- (void)dealloc {
    [_book release];
    [_currentChapter release];
    [_chapters release];
    [_foreignWordRanges release];
    [_foreignWordDataMap release];
    [_settings release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup window
    [self.window setTitle:[NSString stringWithFormat:@"Xenolexia - %@", _book.title ? _book.title : @"Reading"]];
    [self.window setMinSize:NSMakeSize(800, 600)];
    [self.window setContentSize:NSMakeSize(1000, 700)];
    
    // Create UI programmatically
    NSView *contentView = [self.window contentView];
    
    // Create toolbar area at top
    NSView *toolbarView = [[NSView alloc] initWithFrame:NSMakeRect(0, 650, 1000, 50)];
    [toolbarView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    
    // Previous chapter button
    _prevChapterButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 100, 30)];
    [_prevChapterButton setTitle:@"Previous"];
    [_prevChapterButton setTarget:self];
    [_prevChapterButton setAction:@selector(prevChapterClicked:)];
    [_prevChapterButton setEnabled:NO];
    [toolbarView addSubview:_prevChapterButton];
    
    // Next chapter button
    _nextChapterButton = [[NSButton alloc] initWithFrame:NSMakeRect(120, 10, 100, 30)];
    [_nextChapterButton setTitle:@"Next"];
    [_nextChapterButton setTarget:self];
    [_nextChapterButton setAction:@selector(nextChapterClicked:)];
    [toolbarView addSubview:_nextChapterButton];
    
    // Chapter menu
    _chapterMenu = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(230, 10, 200, 30)];
    [_chapterMenu setTarget:self];
    [_chapterMenu setAction:@selector(chapterMenuChanged:)];
    [toolbarView addSubview:_chapterMenu];
    
    // Progress indicator
    _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(450, 15, 200, 20)];
    [_progressIndicator setStyle:NSProgressIndicatorBarStyle];
    [_progressIndicator setMinValue:0.0];
    [_progressIndicator setMaxValue:100.0];
    [_progressIndicator setDoubleValue:_book.progress];
    [_progressIndicator setIndeterminate:NO];
    [toolbarView addSubview:_progressIndicator];
    
    // Progress label
    _progressLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(660, 10, 150, 30)];
    [_progressLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", _book.progress]];
    [_progressLabel setEditable:NO];
    [_progressLabel setBordered:NO];
    [_progressLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [toolbarView addSubview:_progressLabel];
    
    // Settings button
    _settingsButton = [[NSButton alloc] initWithFrame:NSMakeRect(820, 10, 80, 30)];
    [_settingsButton setTitle:@"Settings"];
    [_settingsButton setTarget:self];
    [_settingsButton setAction:@selector(settingsClicked:)];
    [toolbarView addSubview:_settingsButton];
    
    [contentView addSubview:toolbarView];
    [toolbarView release];
    
    // Create scrollable text view for content
    _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 650)];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:NO];
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setBorderType:NSBezelBorder];
    [_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    _textView = [[XLReaderTextView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 650)];
    [_textView setEditable:NO];
    [_textView setSelectable:YES];
    [_textView setDelegate:self];
    [_textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [(XLReaderTextView *)_textView setReaderController:self];
    
    // Set up text view with default settings
    [self applyReaderSettings];
    
    [_scrollView setDocumentView:_textView];
    [contentView addSubview:_scrollView];
    
    // Load book chapters and current chapter
    [self loadBookChapters];
}

- (void)loadBookChapters {
    // Get all chapters from the book
    XLBookParserService *parser = [XLBookParserService sharedService];
    
    // Use block-based method internally (will be bridged to delegate)
    [parser parseBookAtPath:_book.filePath withCompletion:^(XLParsedBook *parsedBook, NSError *error) {
        if (error) {
            NSLog(@"Error loading book chapters: %@", error);
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Error loading book"];
            [alert setInformativeText:[error localizedDescription]];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            return;
        }
        
        _chapters = [parsedBook.chapters retain];
        [self updateChapterMenu];
        [self loadCurrentChapter];
    }];
}

- (void)updateChapterMenu {
    [_chapterMenu removeAllItems];
    
    if (!_chapters || [_chapters count] == 0) {
        return;
    }
    
    for (NSInteger i = 0; i < [_chapters count]; i++) {
        XLChapter *chapter = [_chapters objectAtIndex:i];
        NSString *title = chapter.title ? chapter.title : [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
        [_chapterMenu addItemWithTitle:title];
    }
    
    if (_currentChapterIndex >= 0 && _currentChapterIndex < [_chapters count]) {
        [_chapterMenu selectItemAtIndex:_currentChapterIndex];
    }
    
    // Update navigation buttons
    [_prevChapterButton setEnabled:_currentChapterIndex > 0];
    [_nextChapterButton setEnabled:_currentChapterIndex < ([_chapters count] - 1)];
}

- (void)loadCurrentChapter {
    if (!_chapters || _currentChapterIndex < 0 || _currentChapterIndex >= [_chapters count]) {
        return;
    }
    
    // Update book's current chapter index
    _book.currentChapter = _currentChapterIndex;
    
    // Process the chapter with translation engine
    XLManager *manager = [XLManager sharedManager];
    [manager processBook:_book delegate:self];
}

- (void)displayChapter:(XLProcessedChapter *)chapter {
    if (!chapter) {
        return;
    }
    
    _currentChapter = [chapter retain];
    
    // Clear previous foreign word tracking
    [_foreignWordRanges removeAllObjects];
    [_foreignWordDataMap removeAllObjects];
    
    // Create attributed string from processed content
    NSString *content = chapter.processedContent ? chapter.processedContent : chapter.content;
    NSMutableAttributedString *attributedContent = [[NSMutableAttributedString alloc] initWithString:content];
    
    // Apply base font and styling
    NSFont *baseFont = [NSFont fontWithName:_settings.fontFamily size:_settings.fontSize];
    if (!baseFont) {
        baseFont = [NSFont systemFontOfSize:_settings.fontSize];
    }
    
    NSDictionary *baseAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    baseFont, NSFontAttributeName,
                                    [self textColorForTheme], NSForegroundColorAttributeName,
                                    nil];
    [attributedContent addAttributes:baseAttributes range:NSMakeRange(0, [attributedContent length])];
    
    // Style foreign words
    if (chapter.foreignWords && [chapter.foreignWords count] > 0) {
        for (XLForeignWordData *wordData in chapter.foreignWords) {
            NSRange wordRange = NSMakeRange(wordData.startIndex, wordData.endIndex - wordData.startIndex);
            if (wordRange.location + wordRange.length <= [attributedContent length]) {
                // Style foreign word with underline and color
                NSColor *foreignWordColor = [NSColor colorWithCalibratedRed:0.2 green:0.4 blue:0.8 alpha:1.0];
                [attributedContent addAttribute:NSForegroundColorAttributeName value:foreignWordColor range:wordRange];
                [attributedContent addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:wordRange];
                
                // Store range and data for click detection
                NSValue *rangeValue = [NSValue valueWithRange:wordRange];
                [_foreignWordRanges addObject:rangeValue];
                [_foreignWordDataMap setObject:wordData forKey:rangeValue];
            }
        }
    }
    
    // Set paragraph style for line spacing
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:(_settings.lineHeight - 1.0) * _settings.fontSize];
    if (_settings.textAlign == XLTextAlignJustify) {
        [paragraphStyle setAlignment:NSJustifiedTextAlignment];
    } else {
        [paragraphStyle setAlignment:NSLeftTextAlignment];
    }
    [paragraphStyle setHeadIndent:20.0];
    [paragraphStyle setFirstLineHeadIndent:20.0];
    [paragraphStyle setTailIndent:-20.0];
    
    [attributedContent addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedContent length])];
    [paragraphStyle release];
    
    // Set text in text view
    [[_textView textStorage] setAttributedString:attributedContent];
    [attributedContent release];
    
    // Scroll to top
    [_textView scrollToBeginningOfDocument:nil];
    
    // Update progress
    [self updateProgress];
}

- (NSColor *)textColorForTheme {
    switch (_settings.theme) {
        case XLReaderThemeDark:
            return [NSColor whiteColor];
        case XLReaderThemeSepia:
            return [NSColor colorWithCalibratedRed:0.4 green:0.3 blue:0.2 alpha:1.0];
        case XLReaderThemeLight:
        default:
            return [NSColor blackColor];
    }
}

- (void)applyReaderSettings {
    // Apply background color based on theme
    NSColor *backgroundColor = nil;
    switch (_settings.theme) {
        case XLReaderThemeDark:
            backgroundColor = [NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0];
            break;
        case XLReaderThemeSepia:
            backgroundColor = [NSColor colorWithCalibratedRed:0.95 green:0.9 blue:0.8 alpha:1.0];
            break;
        case XLReaderThemeLight:
        default:
            backgroundColor = [NSColor whiteColor];
            break;
    }
    [_textView setBackgroundColor:backgroundColor];
}

- (void)updateProgress {
    if (!_chapters || [_chapters count] == 0) {
        return;
    }
    
    double progress = ((double)_currentChapterIndex / (double)[_chapters count]) * 100.0;
    [_progressIndicator setDoubleValue:progress];
    [_progressLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", progress]];
    
    // Update book progress
    _book.progress = progress;
    _book.currentChapter = _currentChapterIndex;
    
    // Save progress (async, don't wait)
    // TODO: Save to storage service
}

#pragma mark - Actions

- (IBAction)prevChapterClicked:(id)sender {
    if (_currentChapterIndex > 0) {
        _currentChapterIndex--;
        [self loadCurrentChapter];
    }
}

- (IBAction)nextChapterClicked:(id)sender {
    if (_chapters && _currentChapterIndex < ([_chapters count] - 1)) {
        _currentChapterIndex++;
        [self loadCurrentChapter];
    }
}

- (IBAction)chapterMenuChanged:(id)sender {
    NSInteger selectedIndex = [_chapterMenu indexOfSelectedItem];
    if (selectedIndex >= 0 && selectedIndex < [_chapters count]) {
        _currentChapterIndex = selectedIndex;
        [self loadCurrentChapter];
    }
}

- (IBAction)settingsClicked:(id)sender {
    // TODO: Open settings panel
    NSLog(@"Settings clicked - to be implemented");
}

#pragma mark - NSTextViewDelegate

// Handle clicks on foreign words (called from custom text view)
- (void)handleClickAtCharacterIndex:(NSUInteger)charIndex {
    // Check if click is on a foreign word
    for (NSValue *rangeValue in _foreignWordRanges) {
        NSRange wordRange = [rangeValue rangeValue];
        if (NSLocationInRange(charIndex, wordRange)) {
            XLForeignWordData *wordData = [_foreignWordDataMap objectForKey:rangeValue];
            if (wordData) {
                [self showTranslationPopupForWord:wordData atLocation:charIndex];
                return;
            }
        }
    }
}

- (void)showTranslationPopupForWord:(XLForeignWordData *)wordData atLocation:(NSUInteger)location {
    // TODO: Implement translation popup
    // For now, just show an alert
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:wordData.originalWord ? wordData.originalWord : @"Word"];
    NSString *translation = @"Translation not available";
    if (wordData.wordEntry && wordData.wordEntry.targetWord) {
        translation = wordData.wordEntry.targetWord;
    }
    [alert setInformativeText:translation];
    [alert addButtonWithTitle:@"Save to Vocabulary"];
    [alert addButtonWithTitle:@"I Knew This"];
    [alert addButtonWithTitle:@"Close"];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        // Save to vocabulary
        if ([_delegate respondsToSelector:@selector(readerDidRequestSaveWord:)]) {
            [_delegate readerDidRequestSaveWord:wordData];
        }
    } else if (result == NSAlertSecondButtonReturn) {
        // Mark as known - could update word entry status
        NSLog(@"Word marked as known");
    }
}

#pragma mark - XLManagerDelegate

- (void)manager:(id)manager didProcessChapter:(XLProcessedChapter *)chapter withError:(NSError *)error {
    if (error) {
        NSLog(@"Error processing chapter: %@", error);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error processing chapter"];
        [alert setInformativeText:[error localizedDescription]];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    } else {
        [self displayChapter:chapter];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    // Save reading progress
    [self updateProgress];
    
    if ([_delegate respondsToSelector:@selector(readerDidClose)]) {
        [_delegate readerDidClose];
    }
}

@end
