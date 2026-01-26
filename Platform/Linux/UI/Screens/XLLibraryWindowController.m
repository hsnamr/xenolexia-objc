//
//  XLLibraryWindowController.m
//  Xenolexia
//

#import "XLLibraryWindowController.h"
#import "../../../../Core/Services/XLManager.h"
#import "../../../../Core/Services/XLStorageService.h"

@interface XLLibraryWindowController ()

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) IBOutlet NSButton *importButton;
@property (nonatomic, strong) IBOutlet NSTextField *statusLabel;
@property (nonatomic, strong) XLStorageService *storageService;

@end

@implementation XLLibraryWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"LibraryWindow"];
    if (self) {
        _books = [[NSArray alloc] init];
        _filteredBooks = [[NSArray alloc] init];
        _storageService = [XLStorageService sharedService];
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
    self.searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(10, 550, 500, 30)];
    [contentView addSubview:self.searchField];
    
    // Create import button
    self.importButton = [[NSButton alloc] initWithFrame:NSMakeRect(520, 550, 100, 30)];
    [self.importButton setTitle:@"Import Book"];
    [self.importButton setTarget:self];
    [self.importButton setAction:@selector(importButtonClicked:)];
    [contentView addSubview:self.importButton];
    
    // Create status label
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 520, 600, 20)];
    [self.statusLabel setStringValue:@"Loading..."];
    [self.statusLabel setEditable:NO];
    [self.statusLabel setBordered:NO];
    [self.statusLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:self.statusLabel];
    
    // Create table view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 780, 500)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];
    
    self.tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 780, 500)];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView setDoubleAction:@selector(tableViewDoubleClick:)];
    [self.tableView setTarget:self];
    
    // Add columns
    NSTableColumn *titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    [[titleColumn headerCell] setStringValue:@"Title"];
    [titleColumn setWidth:300];
    [self.tableView addTableColumn:titleColumn];
    
    NSTableColumn *authorColumn = [[NSTableColumn alloc] initWithIdentifier:@"author"];
    [[authorColumn headerCell] setStringValue:@"Author"];
    [authorColumn setWidth:200];
    [self.tableView addTableColumn:authorColumn];
    
    NSTableColumn *progressColumn = [[NSTableColumn alloc] initWithIdentifier:@"progress"];
    [[progressColumn headerCell] setStringValue:@"Progress"];
    [progressColumn setWidth:100];
    [self.tableView addTableColumn:progressColumn];
    
    NSTableColumn *formatColumn = [[NSTableColumn alloc] initWithIdentifier:@"format"];
    [[formatColumn headerCell] setStringValue:@"Format"];
    [formatColumn setWidth:80];
    [self.tableView addTableColumn:formatColumn];
    
    [scrollView setDocumentView:self.tableView];
    [contentView addSubview:scrollView];
    
    // Load books
    [self refreshBooks];
}

- (void)refreshBooks {
    [self.storageService getAllBooksWithCompletion:^(NSArray *books, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error loading books: %@", error);
                if (self.statusLabel) {
                    [self.statusLabel setStringValue:@"Error loading books"];
                }
            } else {
                self.books = books ? books : [[NSArray alloc] init];
                [self filterBooks];
                [self reloadData];
                
                if (self.statusLabel) {
                    NSString *countText = [NSString stringWithFormat:@"%lu book%@", 
                                         (unsigned long)self.filteredBooks.count,
                                         self.filteredBooks.count == 1 ? @"" : @"s"];
                    [self.statusLabel setStringValue:countText];
                }
            }
        });
    }];
}

- (void)filterBooks {
    NSString *searchText = self.searchField ? [self.searchField stringValue] : @"";
    
    if (searchText.length == 0) {
        self.filteredBooks = self.books;
    } else {
        NSMutableArray<XLBook *> *filtered = [NSMutableArray array];
        NSString *lowerSearch = [searchText lowercaseString];
        
        for (XLBook *book in self.books) {
            if ([[book.title lowercaseString] containsString:lowerSearch] ||
                [[book.author lowercaseString] containsString:lowerSearch]) {
                [filtered addObject:book];
            }
        }
        
        self.filteredBooks = filtered;
    }
}

- (void)reloadData {
    if (self.tableView) {
        [self.tableView reloadData];
    }
}

#pragma mark - Actions

- (IBAction)importButtonClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:@[@"txt", @"epub", @"fb2", @"mobi"]];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *fileURL = [[openPanel URLs] firstObject];
            if (fileURL) {
                [self importBookAtPath:[fileURL path]];
            }
        }
    }];
}

- (void)importBookAtPath:(NSString *)filePath {
    if (self.statusLabel) {
        [self.statusLabel setStringValue:@"Importing book..."];
    }
    
    XLManager *manager = [XLManager sharedManager];
    [manager importBookAtPath:filePath withCompletion:^(XLBook *book, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error importing book: %@", error);
                if (self.statusLabel) {
                    [self.statusLabel setStringValue:@"Error importing book"];
                }
            } else {
                [self refreshBooks];
                if (self.statusLabel) {
                    [self.statusLabel setStringValue:@"Book imported successfully"];
                }
            }
        });
    }];
}

- (void)tableViewDoubleClick:(id)sender {
    NSInteger row = [self.tableView clickedRow];
    if (row >= 0 && row < [self.filteredBooks count]) {
        XLBook *book = [self.filteredBooks objectAtIndex:row];
        if ([self.delegate respondsToSelector:@selector(libraryDidSelectBook:)]) {
            [self.delegate libraryDidSelectBook:book];
        }
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.filteredBooks.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= self.filteredBooks.count) {
        return nil;
    }
    
    XLBook *book = self.filteredBooks[row];
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

#pragma mark - NSControlTextEditingDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self filterBooks];
    [self reloadData];
}

@end
