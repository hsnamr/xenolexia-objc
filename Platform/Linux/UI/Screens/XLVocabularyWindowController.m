//
//  XLVocabularyWindowController.m
//  Xenolexia
//
//  Vocabulary list window implementation (Phase 2)

#import "XLVocabularyWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"
#import "../../../../Core/Services/XLExportService.h"
#import "../../../../Core/Models/Language.h"

@interface XLVocabularyWindowController ()
- (void)filterItems;
- (void)reloadTable;
- (void)showEditSheetForItem:(XLVocabularyItem *)item;
- (void)performExportWithFormat:(XLExportFormat)format;
@end

@implementation XLVocabularyWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _items = [[NSArray alloc] init];
        _filteredItems = [[NSArray alloc] init];
        _dueCount = 0;
        _storageService = [XLStorageService sharedService];
    }
    return self;
}

- (void)dealloc {
    [_items release];
    [_filteredItems release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSView *contentView = [self.window contentView];
    [self.window setTitle:@"Xenolexia - Vocabulary"];
    [self.window setMinSize:NSMakeSize(700, 450)];

    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(10, 520, 300, 28)];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldChanged:)];
    [contentView addSubview:_searchField];

    _statusFilterPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(320, 520, 120, 28)];
    [_statusFilterPopUp addItemWithTitle:@"All"];
    [_statusFilterPopUp addItemWithTitle:@"New"];
    [_statusFilterPopUp addItemWithTitle:@"Learning"];
    [_statusFilterPopUp addItemWithTitle:@"Review"];
    [_statusFilterPopUp addItemWithTitle:@"Learned"];
    [_statusFilterPopUp setTarget:self];
    [_statusFilterPopUp setAction:@selector(filterPopUpChanged:)];
    [contentView addSubview:_statusFilterPopUp];

    _editButton = [[NSButton alloc] initWithFrame:NSMakeRect(450, 520, 60, 28)];
    [_editButton setTitle:@"Edit"];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(editButtonClicked:)];
    [contentView addSubview:_editButton];

    _deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(520, 520, 60, 28)];
    [_deleteButton setTitle:@"Delete"];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(deleteButtonClicked:)];
    [contentView addSubview:_deleteButton];

    _exportButton = [[NSButton alloc] initWithFrame:NSMakeRect(590, 520, 70, 28)];
    [_exportButton setTitle:@"Export"];
    [_exportButton setTarget:self];
    [_exportButton setAction:@selector(exportButtonClicked:)];
    [contentView addSubview:_exportButton];

    _statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 492, 500, 20)];
    [_statusLabel setStringValue:@"Loading..."];
    [_statusLabel setEditable:NO];
    [_statusLabel setBordered:NO];
    [_statusLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_statusLabel];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 680, 470)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setBorderType:NSBezelBorder];

    _tableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 680, 470)];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setDoubleAction:@selector(tableViewDoubleClick:)];
    [_tableView setTarget:self];

    NSArray *cols = @[
        @[ @"source", @"Source", @120 ],
        @[ @"target", @"Target", @120 ],
        @[ @"sourceLang", @"Source Lang", @70 ],
        @[ @"targetLang", @"Target Lang", @70 ],
        @[ @"status", @"Status", @70 ],
        @[ @"bookTitle", @"Book", @120 ],
        @[ @"addedAt", @"Added", @90 ]
    ];
    for (NSArray *c in cols) {
        NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:[c objectAtIndex:0]];
        [[col headerCell] setStringValue:[c objectAtIndex:1]];
        [col setWidth:[[c objectAtIndex:2] intValue]];
        [_tableView addTableColumn:col];
    }
    [scrollView setDocumentView:_tableView];
    [contentView addSubview:scrollView];
    [scrollView release];

    [self refreshVocabulary];
    [self refreshDueCount];
}

- (void)refreshVocabulary {
    NSString *query = [_searchField stringValue];
    if (query && [query length] > 0) {
        [_storageService searchVocabularyWithQuery:query delegate:self];
    } else {
        [_storageService getAllVocabularyItemsWithDelegate:self];
    }
}

- (void)refreshDueCount {
    [_storageService getVocabularyDueForReviewWithLimit:1000 delegate:self];
}

#pragma mark - Filter / Reload

- (void)filterItems {
    NSInteger idx = [_statusFilterPopUp indexOfSelectedItem];
    if (idx <= 0) {
        _filteredItems = _items;
    } else {
        XLVocabularyStatus want = XLVocabularyStatusNew;
        switch (idx) {
            case 1: want = XLVocabularyStatusNew; break;
            case 2: want = XLVocabularyStatusLearning; break;
            case 3: want = XLVocabularyStatusReview; break;
            case 4: want = XLVocabularyStatusLearned; break;
            default: want = XLVocabularyStatusNew; break;
        }
        NSMutableArray *a = [NSMutableArray array];
        for (XLVocabularyItem *item in _items) {
            if (item.status == want) [a addObject:item];
        }
        _filteredItems = a;
    }
    [self reloadTable];
}

- (void)reloadTable {
    [_tableView reloadData];
    NSUInteger n = [_filteredItems count];
    [_statusLabel setStringValue:[NSString stringWithFormat:@"%lu word%@", (unsigned long)n, n == 1 ? @"" : @"s"]];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didGetAllVocabularyItems:(NSArray *)items withError:(NSError *)error {
    if (error) {
        [_statusLabel setStringValue:@"Error loading vocabulary"];
        return;
    }
    _items = items ? [items copy] : [[NSArray alloc] init];
    [self filterItems];
}

- (void)storageService:(id)service didSearchVocabulary:(NSArray *)items withError:(NSError *)error {
    if (error) {
        [_statusLabel setStringValue:@"Error searching"];
        return;
    }
    _items = items ? [items copy] : [[NSArray alloc] init];
    [self filterItems];
}

- (void)storageService:(id)service didGetVocabularyDueForReview:(NSArray *)items withError:(NSError *)error {
    if (!error && items) {
        _dueCount = [items count];
        NSString *title = _dueCount > 0
            ? [NSString stringWithFormat:@"Xenolexia - Vocabulary (Due: %ld)", (long)_dueCount]
            : @"Xenolexia - Vocabulary";
        [self.window setTitle:title];
    }
}

- (void)storageService:(id)service didSaveVocabularyItem:(XLVocabularyItem *)item withSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [self refreshVocabulary];
    }
}

- (void)storageService:(id)service didDeleteVocabularyItemWithId:(NSString *)itemId withSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [self refreshVocabulary];
        [self refreshDueCount];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filteredItems count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= [_filteredItems count]) return nil;
    XLVocabularyItem *item = [_filteredItems objectAtIndex:row];
    NSString *colId = [tableColumn identifier];
    if ([colId isEqualToString:@"source"]) return item.sourceWord ?: @"";
    if ([colId isEqualToString:@"target"]) return item.targetWord ?: @"";
    if ([colId isEqualToString:@"sourceLang"]) return [XLLanguageInfo codeStringForLanguage:item.sourceLanguage];
    if ([colId isEqualToString:@"targetLang"]) return [XLLanguageInfo codeStringForLanguage:item.targetLanguage];
    if ([colId isEqualToString:@"status"]) return [XLVocabularyItem codeStringForStatus:item.status];
    if ([colId isEqualToString:@"bookTitle"]) return item.bookTitle ?: @"";
    if ([colId isEqualToString:@"addedAt"]) {
        if (!item.addedAt) return @"";
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"yyyy-MM-dd"];
        NSString *s = [f stringFromDate:item.addedAt];
        [f release];
        return s;
    }
    return @"";
}

#pragma mark - Actions

- (IBAction)searchFieldChanged:(id)sender {
    [self refreshVocabulary];
}

- (IBAction)filterPopUpChanged:(id)sender {
    [self filterItems];
}

- (void)tableViewDoubleClick:(id)sender {
    NSInteger row = [_tableView clickedRow];
    if (row >= 0 && row < [_filteredItems count]) {
        XLVocabularyItem *item = [_filteredItems objectAtIndex:row];
        [self showEditSheetForItem:item];
    }
}

- (IBAction)editButtonClicked:(id)sender {
    NSInteger row = [_tableView selectedRow];
    if (row < 0 || row >= [_filteredItems count]) {
        NSAlert *a = [[NSAlert alloc] init];
        [a setMessageText:@"Select a word to edit."];
        [a addButtonWithTitle:@"OK"];
        [a runModal];
        return;
    }
    XLVocabularyItem *item = [_filteredItems objectAtIndex:row];
    [self showEditSheetForItem:item];
}

- (void)showEditSheetForItem:(XLVocabularyItem *)item {
    NSWindow *sheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 180)
                                                    styleMask:NSTitledWindowMask | NSClosableWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [sheet setTitle:@"Edit word"];
    NSTextField *srcLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 140, 80, 20)];
    [srcLabel setStringValue:@"Source:"];
    [srcLabel setEditable:NO];
    [srcLabel setBordered:NO];
    [srcLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [[sheet contentView] addSubview:srcLabel];
    NSTextField *srcField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 138, 270, 24)];
    [srcField setStringValue:item.sourceWord ?: @""];
    [[sheet contentView] addSubview:srcField];
    NSTextField *tgtLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 108, 80, 20)];
    [tgtLabel setStringValue:@"Target:"];
    [tgtLabel setEditable:NO];
    [tgtLabel setBordered:NO];
    [tgtLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [[sheet contentView] addSubview:tgtLabel];
    NSTextField *tgtField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 106, 270, 24)];
    [tgtField setStringValue:item.targetWord ?: @""];
    [[sheet contentView] addSubview:tgtField];
    NSTextField *ctxLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 76, 80, 20)];
    [ctxLabel setStringValue:@"Context:"];
    [ctxLabel setEditable:NO];
    [ctxLabel setBordered:NO];
    [ctxLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [[sheet contentView] addSubview:ctxLabel];
    NSTextField *ctxField = [[NSTextField alloc] initWithFrame:NSMakeRect(110, 74, 270, 24)];
    [ctxField setStringValue:item.contextSentence ?: @""];
    [[sheet contentView] addSubview:ctxField];
    NSButton *saveBtn = [[NSButton alloc] initWithFrame:NSMakeRect(220, 20, 80, 32)];
    [saveBtn setTitle:@"Save"];
    [saveBtn setKeyEquivalent:@"\r"];
    NSButton *cancelBtn = [[NSButton alloc] initWithFrame:NSMakeRect(310, 20, 80, 32)];
    [cancelBtn setTitle:@"Cancel"];
    [cancelBtn setKeyEquivalent:@"\033"];
    [[sheet contentView] addSubview:saveBtn];
    [[sheet contentView] addSubview:cancelBtn];
    [saveBtn setTarget:self];
    [saveBtn setAction:@selector(editSheetSave:)];
    [cancelBtn setTarget:self];
    [cancelBtn setAction:@selector(editSheetCancel:)];
    objc_setAssociatedObject(saveBtn, "sheet", sheet, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(saveBtn, "srcField", srcField, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(saveBtn, "tgtField", tgtField, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(saveBtn, "ctxField", ctxField, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(saveBtn, "item", item, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(cancelBtn, "sheet", sheet, OBJC_ASSOCIATION_RETAIN);
    [NSApp runModalForWindow:sheet];
    [sheet orderOut:nil];
}

- (void)editSheetSave:(id)sender {
    NSWindow *sheet = objc_getAssociatedObject(sender, "sheet");
    NSTextField *srcField = objc_getAssociatedObject(sender, "srcField");
    NSTextField *tgtField = objc_getAssociatedObject(sender, "tgtField");
    NSTextField *ctxField = objc_getAssociatedObject(sender, "ctxField");
    XLVocabularyItem *item = objc_getAssociatedObject(sender, "item");
    if (item && sheet) {
        item.sourceWord = [srcField stringValue];
        item.targetWord = [tgtField stringValue];
        item.contextSentence = [[ctxField stringValue] length] > 0 ? [ctxField stringValue] : nil;
        [_storageService saveVocabularyItem:item delegate:self];
    }
    [NSApp stopModal];
}

- (void)editSheetCancel:(id)sender {
    [NSApp stopModal];
}

- (IBAction)deleteButtonClicked:(id)sender {
    NSInteger row = [_tableView selectedRow];
    if (row < 0 || row >= [_filteredItems count]) {
        NSAlert *a = [[NSAlert alloc] init];
        [a setMessageText:@"Select a word to delete."];
        [a addButtonWithTitle:@"OK"];
        [a runModal];
        return;
    }
    XLVocabularyItem *item = [_filteredItems objectAtIndex:row];
    NSAlert *a = [[NSAlert alloc] init];
    [a setMessageText:@"Delete word"];
    [a setInformativeText:[NSString stringWithFormat:@"Delete \"%@\" from vocabulary?", item.sourceWord ?: @"this word"]];
    [a addButtonWithTitle:@"Delete"];
    [a addButtonWithTitle:@"Cancel"];
    [a setAlertStyle:NSWarningAlertStyle];
    if ([a runModal] == NSAlertFirstButtonReturn) {
        [_storageService deleteVocabularyItemWithId:item.vocabularyId delegate:self];
    }
}

- (IBAction)exportButtonClicked:(id)sender {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *csvItem = [[NSMenuItem alloc] initWithTitle:@"Export as CSV" action:@selector(exportCSV:) keyEquivalent:@""];
    [csvItem setTarget:self];
    [menu addItem:csvItem];
    NSMenuItem *jsonItem = [[NSMenuItem alloc] initWithTitle:@"Export as JSON" action:@selector(exportJSON:) keyEquivalent:@""];
    [jsonItem setTarget:self];
    [menu addItem:jsonItem];
    NSMenuItem *ankiItem = [[NSMenuItem alloc] initWithTitle:@"Export as Anki" action:@selector(exportAnki:) keyEquivalent:@""];
    [ankiItem setTarget:self];
    [menu addItem:ankiItem];
    NSPoint loc = [_exportButton convertPoint:NSMakePoint(0, 0) toView:nil];
    [menu popUpMenuPositioningItem:nil atLocation:loc inView:nil];
}

- (void)exportCSV:(id)sender { [self performExportWithFormat:XLExportFormatCSV]; }
- (void)exportJSON:(id)sender { [self performExportWithFormat:XLExportFormatJSON]; }
- (void)exportAnki:(id)sender { [self performExportWithFormat:XLExportFormatAnki]; }

- (void)performExportWithFormat:(XLExportFormat)format {
    NSString *ext = (format == XLExportFormatCSV) ? @"csv" : (format == XLExportFormatJSON) ? @"json" : @"txt";
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:ext]];
    [panel setCanCreateDirectories:YES];
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        NSURL *url = [panel URL];
        NSString *path = url ? [url path] : nil;
        if (path && [_filteredItems count] > 0) {
            XLExportService *ex = [[XLExportService alloc] init];
            [ex exportVocabularyItems:_filteredItems format:format toFilePath:path withCompletion:^(BOOL success, NSError *err) {
                if (success) {
                    [_statusLabel setStringValue:[NSString stringWithFormat:@"Exported to %@", path]];
                } else {
                    [_statusLabel setStringValue:[NSString stringWithFormat:@"Export failed: %@", err ? [err localizedDescription] : @"unknown"]];
                }
            }];
            [ex release];
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(vocabularyWindowDidClose)]) {
        [_delegate vocabularyWindowDidClose];
    }
}
</think>
Adding `#import <objc/runtime.h>` and fixing the edit sheet (avoid `beginSheet` completionHandler capturing; use associated objects or a modal).
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
StrReplace