//
//  XLLibraryWindowController.m
//  Xenolexia
//

#import "XLLibraryWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"
#import "../../../../Core/Services/XLManager.h"
#import <objc/runtime.h>

static const CGFloat kCardWidth = 160;
static const CGFloat kCardHeight = 220;
static const CGFloat kCardSpacing = 16;
static const NSInteger kGridColumns = 4;

static NSString *libraryWindowStatePath(void) {
    NSString *home = NSHomeDirectory();
    NSString *dir = [home stringByAppendingPathComponent:@".xenolexia"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return [dir stringByAppendingPathComponent:@"window_state.plist"];
}

@interface XLLibraryWindowController ()
- (void)rebuildGrid;
- (void)switchToTableView;
- (void)switchToGridView;
- (void)gridCardDoubleClicked:(id)sender;
- (void)restoreWindowState;
- (void)saveWindowState;
@end

@implementation XLLibraryWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"LibraryWindow"];
    if (self) {
        _books = [[NSArray alloc] init];
        _filteredBooks = [[NSArray alloc] init];
        _storageService = [XLStorageService sharedService];
        _currentSortBy = @"lastReadAt";
        _currentSortOrder = @"DESC";
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:self.window];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup window
    [self.window setTitle:@"Xenolexia - Library"];
    [self.window setMinSize:NSMakeSize(600, 400)];
    
    // Create UI programmatically
    NSView *contentView = [self.window contentView];
    
    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(10, 550, 400, 30)];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldChanged:)];
    [contentView addSubview:_searchField];

    _viewPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(420, 550, 90, 30)];
    [_viewPopUp addItemWithTitle:@"Table"];
    [_viewPopUp addItemWithTitle:@"Grid"];
    [_viewPopUp setTarget:self];
    [_viewPopUp setAction:@selector(viewPopUpChanged:)];
    [contentView addSubview:_viewPopUp];
    _showingGrid = NO;
    
    _sortButton = [[NSButton alloc] initWithFrame:NSMakeRect(520, 550, 80, 30)];
    [_sortButton setTitle:@"Sort"];
    [_sortButton setTarget:self];
    [_sortButton setAction:@selector(sortButtonClicked:)];
    [contentView addSubview:_sortButton];
    
    // Create delete button
    _deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(610, 550, 80, 30)];
    [_deleteButton setTitle:@"Delete"];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(deleteButtonClicked:)];
    [contentView addSubview:_deleteButton];
    
    _vocabularyButton = [[NSButton alloc] initWithFrame:NSMakeRect(670, 550, 90, 30)];
    [_vocabularyButton setTitle:@"Vocabulary"];
    [_vocabularyButton setTarget:self];
    [_vocabularyButton setAction:@selector(vocabularyButtonClicked:)];
    [contentView addSubview:_vocabularyButton];

    _reviewButton = [[NSButton alloc] initWithFrame:NSMakeRect(770, 550, 80, 30)];
    [_reviewButton setTitle:@"Review"];
    [_reviewButton setTarget:self];
    [_reviewButton setAction:@selector(reviewButtonClicked:)];
    [contentView addSubview:_reviewButton];

    _settingsButton = [[NSButton alloc] initWithFrame:NSMakeRect(860, 550, 70, 30)];
    [_settingsButton setTitle:@"Settings"];
    [_settingsButton setTarget:self];
    [_settingsButton setAction:@selector(settingsButtonClicked:)];
    [contentView addSubview:_settingsButton];

    _statisticsButton = [[NSButton alloc] initWithFrame:NSMakeRect(940, 550, 80, 30)];
    [_statisticsButton setTitle:@"Statistics"];
    [_statisticsButton setTarget:self];
    [_statisticsButton setAction:@selector(statisticsButtonClicked:)];
    [contentView addSubview:_statisticsButton];

    _importButton = [[NSButton alloc] initWithFrame:NSMakeRect(1030, 550, 100, 30)];
    [_importButton setTitle:@"Import Book"];
    [_importButton setTarget:self];
    [_importButton setAction:@selector(importButtonClicked:)];
    [contentView addSubview:_importButton];
    
    // Create status label
    _statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 520, 600, 20)];
    [_statusLabel setStringValue:@"Loading..."];
    [_statusLabel setEditable:NO];
    [_statusLabel setBordered:NO];
    [_statusLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_statusLabel];
    
    // Create table view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 780, 500)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];
    
    _tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 780, 500)];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setDoubleAction:@selector(tableViewDoubleClick:)];
    [_tableView setTarget:self];
    
    // Add columns
    NSTableColumn *titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    [[titleColumn headerCell] setStringValue:@"Title"];
    [titleColumn setWidth:300];
    [_tableView addTableColumn:titleColumn];
    
    NSTableColumn *authorColumn = [[NSTableColumn alloc] initWithIdentifier:@"author"];
    [[authorColumn headerCell] setStringValue:@"Author"];
    [authorColumn setWidth:200];
    [_tableView addTableColumn:authorColumn];
    
    NSTableColumn *progressColumn = [[NSTableColumn alloc] initWithIdentifier:@"progress"];
    [[progressColumn headerCell] setStringValue:@"Progress"];
    [progressColumn setWidth:100];
    [_tableView addTableColumn:progressColumn];
    
    NSTableColumn *formatColumn = [[NSTableColumn alloc] initWithIdentifier:@"format"];
    [[formatColumn headerCell] setStringValue:@"Format"];
    [formatColumn setWidth:80];
    [_tableView addTableColumn:formatColumn];
    
    [scrollView setDocumentView:_tableView];
    _tableScrollView = [scrollView retain];
    [contentView addSubview:scrollView];

    _gridScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 780, 500)];
    [_gridScrollView setHasVerticalScroller:YES];
    [_gridScrollView setHasHorizontalScroller:NO];
    [_gridScrollView setAutohidesScrollers:YES];
    [_gridScrollView setBorderType:NSBezelBorder];
    _gridContentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 780, 500)];
    [_gridScrollView setDocumentView:_gridContentView];
    [_gridScrollView setHidden:YES];
    [contentView addSubview:_gridScrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryWindowWillClose:) name:NSWindowWillCloseNotification object:self.window];
    [self restoreWindowState];
    [self refreshBooks];
    [_storageService getLibraryViewModeWithDelegate:self];
}

- (void)libraryWindowWillClose:(NSNotification *)notification {
    (void)notification;
    [self saveWindowState];
}

- (void)restoreWindowState {
    NSString *path = libraryWindowStatePath();
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return;
    NSNumber *x = [dict objectForKey:@"x"];
    NSNumber *y = [dict objectForKey:@"y"];
    NSNumber *w = [dict objectForKey:@"width"];
    NSNumber *h = [dict objectForKey:@"height"];
    if (x && y && w && h && [w doubleValue] >= 600 && [h doubleValue] >= 400) {
        NSRect frame = NSMakeRect([x doubleValue], [y doubleValue], [w doubleValue], [h doubleValue]);
        [self.window setFrame:frame display:NO];
    }
}

- (void)saveWindowState {
    if (![self.window isVisible]) return;
    NSRect frame = [self.window frame];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:frame.origin.x], @"x",
        [NSNumber numberWithDouble:frame.origin.y], @"y",
        [NSNumber numberWithDouble:frame.size.width], @"width",
        [NSNumber numberWithDouble:frame.size.height], @"height",
        nil];
    [dict writeToFile:libraryWindowStatePath() atomically:YES];
}

- (void)refreshBooks {
    [_storageService getAllBooksWithSortBy:_currentSortBy order:_currentSortOrder delegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didGetAllBooks:(NSArray *)books withError:(NSError *)error {
    if (error) {
        NSLog(@"Error loading books: %@", error);
        if (_statusLabel) {
            [_statusLabel setStringValue:@"Error loading books"];
        }
    } else {
    _books = books ? books : [[NSArray alloc] init];
    [self filterBooks];
    [self reloadData];
    
    if (_statusLabel) {
        NSString *countText = [NSString stringWithFormat:@"%lu book%@", 
                             (unsigned long)[_filteredBooks count],
                             [_filteredBooks count] == 1 ? @"" : @"s"];
        [_statusLabel setStringValue:countText];
    }
    }
}

- (void)storageService:(id)service didDeleteBookWithId:(NSString *)bookId withSuccess:(BOOL)success error:(NSError *)error {
    if (error) {
        NSAlert *errorAlert = [[NSAlert alloc] init];
        [errorAlert setMessageText:@"Error deleting book"];
        [errorAlert setInformativeText:[error localizedDescription]];
        [errorAlert addButtonWithTitle:@"OK"];
        [errorAlert runModal];
    } else {
        [self refreshBooks];
    }
}

- (void)storageService:(id)service didGetLibraryViewMode:(BOOL)grid error:(NSError *)error {
    (void)service;
    (void)error;
    _showingGrid = grid;
    [_viewPopUp selectItemAtIndex:grid ? 1 : 0];
    if (grid) {
        [_tableScrollView setHidden:YES];
        [_gridScrollView setHidden:NO];
        [self rebuildGrid];
    } else {
        [_tableScrollView setHidden:NO];
        [_gridScrollView setHidden:YES];
    }
}

- (void)storageService:(id)service didSaveLibraryViewModeWithSuccess:(BOOL)success error:(NSError *)error {
    (void)service;
    (void)success;
    (void)error;
}

- (void)filterBooks {
    NSString *searchText = _searchField ? [_searchField stringValue] : @"";
    
    if ([searchText length] == 0) {
        _filteredBooks = _books;
    } else {
        NSMutableArray *filtered = [NSMutableArray array];
        NSString *lowerSearch = [searchText lowercaseString];
        
        for (XLBook *book in _books) {
            NSString *bookTitle = [book title] ? [[book title] lowercaseString] : @"";
            NSString *bookAuthor = [book author] ? [[book author] lowercaseString] : @"";
            NSRange titleRange = [bookTitle rangeOfString:lowerSearch];
            NSRange authorRange = [bookAuthor rangeOfString:lowerSearch];
            if (titleRange.location != NSNotFound || authorRange.location != NSNotFound) {
                [filtered addObject:book];
            }
        }
        
        _filteredBooks = filtered;
    }
}

- (void)reloadData {
    if (_tableView) {
        [_tableView reloadData];
    }
    if (_showingGrid && _gridContentView) {
        [self rebuildGrid];
    }
}

- (void)viewPopUpChanged:(id)sender {
    NSInteger idx = [_viewPopUp indexOfSelectedItem];
    if (idx == 1) {
        [self switchToGridView];
        [_storageService saveLibraryViewMode:YES delegate:self];
    } else {
        [self switchToTableView];
        [_storageService saveLibraryViewMode:NO delegate:self];
    }
}

- (void)switchToTableView {
    _showingGrid = NO;
    [_tableScrollView setHidden:NO];
    [_gridScrollView setHidden:YES];
    [self reloadData];
}

- (void)switchToGridView {
    _showingGrid = YES;
    [_tableScrollView setHidden:YES];
    [_gridScrollView setHidden:NO];
    [self rebuildGrid];
}

- (void)rebuildGrid {
    [[_gridContentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray *books = _filteredBooks;
    if (!books || [books count] == 0) {
        [_gridContentView setFrameSize:NSMakeSize(780, 500)];
        return;
    }
    NSInteger count = [books count];
    NSInteger rows = (count + kGridColumns - 1) / kGridColumns;
    CGFloat contentWidth = kGridColumns * kCardWidth + (kGridColumns + 1) * kCardSpacing;
    CGFloat contentHeight = rows * kCardHeight + (rows + 1) * kCardSpacing;
    [_gridContentView setFrameSize:NSMakeSize(contentWidth, contentHeight)];
    for (NSInteger i = 0; i < count; i++) {
        XLBook *book = [books objectAtIndex:i];
        NSInteger col = i % kGridColumns;
        NSInteger row = i / kGridColumns;
        CGFloat x = kCardSpacing + col * (kCardWidth + kCardSpacing);
        CGFloat y = contentHeight - (row + 1) * (kCardHeight + kCardSpacing) - kCardSpacing;
        NSBox *card = [[NSBox alloc] initWithFrame:NSMakeRect(x, y, kCardWidth, kCardHeight)];
        [card setBoxType:NSBoxPrimary];
        [card setBorderType:NSLineBorder];
        [card setTitlePosition:NSNoTitle];
        [card setContentViewMargins:NSMakeSize(0, 0)];
        CGFloat top = kCardHeight - 8;
        NSImageView *coverView = [[NSImageView alloc] initWithFrame:NSMakeRect(20, top - 160, 120, 160)];
        [coverView setImageScaling:NSImageScaleProportionallyDown];
        if (book.coverPath && [[NSFileManager defaultManager] fileExistsAtPath:book.coverPath]) {
            NSImage *img = [[NSImage alloc] initWithContentsOfFile:book.coverPath];
            if (img) {
                [coverView setImage:img];
                [img release];
            } else {
                [coverView setImage:nil];
            }
        }
        if (![coverView image]) {
            NSTextField *placeholder = [[NSTextField alloc] initWithFrame:NSMakeRect(30, top - 140, 100, 24)];
            [placeholder setStringValue:@"No cover"];
            [placeholder setEditable:NO];
            [placeholder setBordered:NO];
            [placeholder setBackgroundColor:[NSColor clearColor]];
            [placeholder setFont:[NSFont systemFontOfSize:11]];
            [placeholder setTextColor:[NSColor grayColor]];
            [card addSubview:placeholder];
            [placeholder release];
        }
        [card addSubview:coverView];
        [coverView release];
        top -= 168;
        NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(8, top, kCardWidth - 16, 36)];
        [titleLabel setStringValue:book.title ?: @"Untitled"];
        [titleLabel setEditable:NO];
        [titleLabel setBordered:NO];
        [titleLabel setBackgroundColor:[NSColor clearColor]];
        [titleLabel setFont:[NSFont boldSystemFontOfSize:12]];
        [titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [titleLabel setAlignment:NSCenterTextAlignment];
        [card addSubview:titleLabel];
        [titleLabel release];
        top -= 24;
        NSTextField *authorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(8, top, kCardWidth - 16, 20)];
        [authorLabel setStringValue:book.author ?: @"—"];
        [authorLabel setEditable:NO];
        [authorLabel setBordered:NO];
        [authorLabel setBackgroundColor:[NSColor clearColor]];
        [authorLabel setFont:[NSFont systemFontOfSize:10]];
        [authorLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [authorLabel setAlignment:NSCenterTextAlignment];
        [card addSubview:authorLabel];
        [authorLabel release];
        top -= 22;
        NSTextField *progressLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(8, top, kCardWidth - 16, 18)];
        [progressLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", book.progress]];
        [progressLabel setEditable:NO];
        [progressLabel setBordered:NO];
        [progressLabel setBackgroundColor:[NSColor clearColor]];
        [progressLabel setFont:[NSFont systemFontOfSize:11]];
        [progressLabel setAlignment:NSCenterTextAlignment];
        [card addSubview:progressLabel];
        [progressLabel release];
        objc_setAssociatedObject(card, "book", book, OBJC_ASSOCIATION_ASSIGN);
        NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, kCardWidth, kCardHeight)];
        [btn setTitle:@""];
        [btn setBordered:NO];
        [btn setTransparent:YES];
        [btn setTarget:self];
        [btn setAction:@selector(gridCardDoubleClicked:)];
        objc_setAssociatedObject(btn, "book", book, OBJC_ASSOCIATION_ASSIGN);
        [card addSubview:btn positioned:NSWindowAbove relativeTo:nil];
        [btn release];
        [_gridContentView addSubview:card];
        [card release];
    }
}

- (void)gridCardDoubleClicked:(id)sender {
    XLBook *book = objc_getAssociatedObject(sender, "book");
    if (book && _delegate && [_delegate respondsToSelector:@selector(libraryDidRequestBookDetail:)]) {
        [_delegate libraryDidRequestBookDetail:book];
    }
}

#pragma mark - Actions

- (IBAction)vocabularyButtonClicked:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(libraryDidRequestVocabulary)]) {
        [_delegate libraryDidRequestVocabulary];
    }
}

- (IBAction)reviewButtonClicked:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(libraryDidRequestReview)]) {
        [_delegate libraryDidRequestReview];
    }
}

- (IBAction)settingsButtonClicked:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(libraryDidRequestSettings)]) {
        [_delegate libraryDidRequestSettings];
    }
}

- (IBAction)statisticsButtonClicked:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(libraryDidRequestStatistics)]) {
        [_delegate libraryDidRequestStatistics];
    }
}

- (IBAction)importButtonClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"txt", @"epub", @"fb2", @"mobi", nil];
    [openPanel setAllowedFileTypes:fileTypes];
    
    // GNUStep doesn't support blocks, so we'll use a different approach
    // For now, just open the panel synchronously
    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSArray *urls = [openPanel URLs];
        if ([urls count] > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            if (fileURL) {
                [self importBookAtPath:[fileURL path]];
            }
        }
    }
}

- (void)importBookAtPath:(NSString *)filePath {
    if (_statusLabel) {
        [_statusLabel setStringValue:@"Importing book..."];
    }
    
    // Use delegate-based import (GNUStep compatible)
    XLManager *manager = [XLManager sharedManager];
    [manager importBookAtPath:filePath delegate:self];
}

- (void)tableViewDoubleClick:(id)sender {
    NSInteger row = [_tableView clickedRow];
    if (row >= 0 && row < [_filteredBooks count]) {
        XLBook *book = [_filteredBooks objectAtIndex:row];
        if (_delegate && [_delegate respondsToSelector:@selector(libraryDidRequestBookDetail:)]) {
            [_delegate libraryDidRequestBookDetail:book];
        }
    }
}

- (IBAction)sortButtonClicked:(id)sender {
    NSMenu *sortMenu = [[NSMenu alloc] init];
    
    NSMenuItem *recentReadItem = [[NSMenuItem alloc] initWithTitle:@"Recently Read" action:@selector(sortByRecentRead:) keyEquivalent:@""];
    [recentReadItem setTarget:self];
    [sortMenu addItem:recentReadItem];
    
    NSMenuItem *recentAddedItem = [[NSMenuItem alloc] initWithTitle:@"Recently Added" action:@selector(sortByRecentAdded:) keyEquivalent:@""];
    [recentAddedItem setTarget:self];
    [sortMenu addItem:recentAddedItem];
    
    NSMenuItem *titleItem = [[NSMenuItem alloc] initWithTitle:@"Title" action:@selector(sortByTitle:) keyEquivalent:@""];
    [titleItem setTarget:self];
    [sortMenu addItem:titleItem];
    
    NSMenuItem *authorItem = [[NSMenuItem alloc] initWithTitle:@"Author" action:@selector(sortByAuthor:) keyEquivalent:@""];
    [authorItem setTarget:self];
    [sortMenu addItem:authorItem];
    
    NSMenuItem *progressItem = [[NSMenuItem alloc] initWithTitle:@"Progress" action:@selector(sortByProgress:) keyEquivalent:@""];
    [progressItem setTarget:self];
    [sortMenu addItem:progressItem];
    
    NSPoint location = [sender convertPoint:NSMakePoint(0, 0) toView:nil];
    [sortMenu popUpMenuPositioningItem:nil atLocation:location inView:nil];
}

- (void)sortByRecentRead:(id)sender {
    _currentSortBy = @"lastReadAt";
    _currentSortOrder = @"DESC";
    [self refreshBooks];
}

- (void)sortByRecentAdded:(id)sender {
    _currentSortBy = @"addedAt";
    _currentSortOrder = @"DESC";
    [self refreshBooks];
}

- (void)sortByTitle:(id)sender {
    _currentSortBy = @"title";
    _currentSortOrder = @"ASC";
    [self refreshBooks];
}

- (void)sortByAuthor:(id)sender {
    _currentSortBy = @"author";
    _currentSortOrder = @"ASC";
    [self refreshBooks];
}

- (void)sortByProgress:(id)sender {
    _currentSortBy = @"progress";
    _currentSortOrder = @"DESC";
    [self refreshBooks];
}

- (IBAction)deleteButtonClicked:(id)sender {
    NSInteger selectedRow = [_tableView selectedRow];
    if (selectedRow < 0 || selectedRow >= [_filteredBooks count]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No book selected"];
        [alert setInformativeText:@"Please select a book to delete."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    XLBook *book = [_filteredBooks objectAtIndex:selectedRow];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Delete Book"];
    [alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", book.title]];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        [_storageService deleteBookWithId:[book bookId] delegate:self];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filteredBooks count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= [_filteredBooks count]) {
        return nil;
    }
    
    XLBook *book = [_filteredBooks objectAtIndex:row];
    NSString *columnId = [tableColumn identifier];
    
    if ([columnId isEqualToString:@"title"]) {
        return book.title;
    } else if ([columnId isEqualToString:@"author"]) {
        return book.author;
    } else if ([columnId isEqualToString:@"progress"]) {
        return [NSString stringWithFormat:@"%.0f%%", book.progress];
    } else if ([columnId isEqualToString:@"format"]) {
        switch (book.format) {
            case XLBookFormatEpub: return @"EPUB";
            case XLBookFormatTxt: return @"TXT";
            case XLBookFormatFb2: return @"FB2";
            case XLBookFormatMobi: return @"MOBI";
        }
    }
    
    return @"";
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Handle selection change if needed
}

- (IBAction)searchFieldChanged:(id)sender {
    [self filterBooks];
    [self reloadData];
}

#pragma mark - NSControlTextEditingDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self filterBooks];
    [self reloadData];
}

#pragma mark - XLManagerDelegate

- (void)manager:(id)manager didImportBook:(XLBook *)book withError:(NSError *)error {
    if (error) {
        NSLog(@"Error importing book: %@", error);
        if (_statusLabel) {
            [_statusLabel setStringValue:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]]];
        }
        
        NSAlert *errorAlert = [[NSAlert alloc] init];
        [errorAlert setMessageText:@"Error importing book"];
        [errorAlert setInformativeText:[error localizedDescription]];
        [errorAlert addButtonWithTitle:@"OK"];
        [errorAlert runModal];
    } else {
        if (_statusLabel) {
            [_statusLabel setStringValue:@"Book imported successfully"];
        }
        // Refresh the book list
        [self refreshBooks];
    }
}

@end
