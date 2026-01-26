//
//  XLLibraryWindowController.m
//  Xenolexia
//

#import "XLLibraryWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"
#import "../../../../Core/Services/XLManager.h"


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

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup window
    [self.window setTitle:@"Xenolexia - Library"];
    [self.window setMinSize:NSMakeSize(600, 400)];
    
    // Create UI programmatically
    NSView *contentView = [self.window contentView];
    
    // Create search field
    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(10, 550, 500, 30)];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldChanged:)];
    [contentView addSubview:_searchField];
    
    // Create sort button
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
    
    // Create import button
    _importButton = [[NSButton alloc] initWithFrame:NSMakeRect(700, 550, 100, 30)];
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
    [contentView addSubview:scrollView];
    
    // Load books
    [self refreshBooks];
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
}

#pragma mark - Actions

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
