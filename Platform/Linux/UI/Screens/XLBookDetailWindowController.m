//
//  XLBookDetailWindowController.m
//  Xenolexia
//

#import "XLBookDetailWindowController.h"
#import "../../../Core/Models/Language.h"

@implementation XLBookDetailWindowController

- (instancetype)initWithBook:(XLBook *)book {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _book = [book retain];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Setup window
    [self.window setTitle:@"Book Details"];
    [self.window setMinSize:NSMakeSize(500, 600)];
    [self.window setContentSize:NSMakeSize(500, 600)];
    
    // Create UI programmatically
    NSView *contentView = [self.window contentView];
    
    // Title
    _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 550, 460, 30)];
    [_titleLabel setStringValue:_book.title ? _book.title : @"Unknown Title"];
    [_titleLabel setFont:[NSFont boldSystemFontOfSize:18]];
    [_titleLabel setEditable:NO];
    [_titleLabel setBordered:NO];
    [_titleLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_titleLabel];
    
    // Author
    _authorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 520, 460, 20)];
    [_authorLabel setStringValue:_book.author ? _book.author : @"Unknown Author"];
    [_authorLabel setFont:[NSFont systemFontOfSize:14]];
    [_authorLabel setEditable:NO];
    [_authorLabel setBordered:NO];
    [_authorLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_authorLabel];
    
    // Progress
    NSTextField *progressTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 480, 100, 20)];
    [progressTitle setStringValue:@"Progress:"];
    [progressTitle setEditable:NO];
    [progressTitle setBordered:NO];
    [progressTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:progressTitle];
    
    _progressLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 480, 100, 20)];
    [_progressLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", _book.progress]];
    [_progressLabel setEditable:NO];
    [_progressLabel setBordered:NO];
    [_progressLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_progressLabel];
    
    _progressBar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 450, 460, 20)];
    [_progressBar setStyle:NSProgressIndicatorBarStyle];
    [_progressBar setMinValue:0.0];
    [_progressBar setMaxValue:100.0];
    [_progressBar setDoubleValue:_book.progress];
    [_progressBar setIndeterminate:NO];
    [contentView addSubview:_progressBar];
    
    // Format
    NSTextField *formatTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 410, 100, 20)];
    [formatTitle setStringValue:@"Format:"];
    [formatTitle setEditable:NO];
    [formatTitle setBordered:NO];
    [formatTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:formatTitle];
    
    _formatLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 410, 100, 20)];
    NSString *formatStr = @"TXT";
    switch (_book.format) {
        case XLBookFormatEpub: formatStr = @"EPUB"; break;
        case XLBookFormatFb2: formatStr = @"FB2"; break;
        case XLBookFormatMobi: formatStr = @"MOBI"; break;
        case XLBookFormatTxt: formatStr = @"TXT"; break;
    }
    [_formatLabel setStringValue:formatStr];
    [_formatLabel setEditable:NO];
    [_formatLabel setBordered:NO];
    [_formatLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_formatLabel];
    
    // Language
    NSTextField *languageTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 380, 100, 20)];
    [languageTitle setStringValue:@"Language:"];
    [languageTitle setEditable:NO];
    [languageTitle setBordered:NO];
    [languageTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:languageTitle];
    
    _languageLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 380, 200, 20)];
    if (_book.languagePair) {
        XLLanguageInfo *targetInfo = [XLLanguageInfo infoForCode:_book.languagePair.targetLanguage];
        [_languageLabel setStringValue:targetInfo ? targetInfo.name : @"Unknown"];
    } else {
        [_languageLabel setStringValue:@"Unknown"];
    }
    [_languageLabel setEditable:NO];
    [_languageLabel setBordered:NO];
    [_languageLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_languageLabel];
    
    // Proficiency
    NSTextField *proficiencyTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 350, 100, 20)];
    [proficiencyTitle setStringValue:@"Proficiency:"];
    [proficiencyTitle setEditable:NO];
    [proficiencyTitle setBordered:NO];
    [proficiencyTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:proficiencyTitle];
    
    _proficiencyLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 350, 200, 20)];
    NSString *proficiencyStr = @"Beginner";
    switch (_book.proficiencyLevel) {
        case XLProficiencyLevelBeginner: proficiencyStr = @"Beginner"; break;
        case XLProficiencyLevelIntermediate: proficiencyStr = @"Intermediate"; break;
        case XLProficiencyLevelAdvanced: proficiencyStr = @"Advanced"; break;
    }
    [_proficiencyLabel setStringValue:proficiencyStr];
    [_proficiencyLabel setEditable:NO];
    [_proficiencyLabel setBordered:NO];
    [_proficiencyLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_proficiencyLabel];
    
    // Word Density
    NSTextField *wordDensityTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 320, 100, 20)];
    [wordDensityTitle setStringValue:@"Word Density:"];
    [wordDensityTitle setEditable:NO];
    [wordDensityTitle setBordered:NO];
    [wordDensityTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:wordDensityTitle];
    
    _wordDensityLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 320, 100, 20)];
    [_wordDensityLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", _book.wordDensity * 100.0]];
    [_wordDensityLabel setEditable:NO];
    [_wordDensityLabel setBordered:NO];
    [_wordDensityLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_wordDensityLabel];
    
    // File Size
    NSTextField *fileSizeTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 290, 100, 20)];
    [fileSizeTitle setStringValue:@"File Size:"];
    [fileSizeTitle setEditable:NO];
    [fileSizeTitle setBordered:NO];
    [fileSizeTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:fileSizeTitle];
    
    _fileSizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 290, 200, 20)];
    NSString *fileSizeStr = [self formatFileSize:_book.fileSize];
    [_fileSizeLabel setStringValue:fileSizeStr];
    [_fileSizeLabel setEditable:NO];
    [_fileSizeLabel setBordered:NO];
    [_fileSizeLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_fileSizeLabel];
    
    // Added At
    NSTextField *addedAtTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 260, 100, 20)];
    [addedAtTitle setStringValue:@"Added:"];
    [addedAtTitle setEditable:NO];
    [addedAtTitle setBordered:NO];
    [addedAtTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:addedAtTitle];
    
    _addedAtLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 260, 200, 20)];
    if (_book.addedAt) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        [_addedAtLabel setStringValue:[formatter stringFromDate:_book.addedAt]];
    } else {
        [_addedAtLabel setStringValue:@"Unknown"];
    }
    [_addedAtLabel setEditable:NO];
    [_addedAtLabel setBordered:NO];
    [_addedAtLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:_addedAtLabel];
    
    // Start Reading Button
    _startReadingButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 200, 200, 40)];
    [_startReadingButton setTitle:_book.progress > 0 ? @"Continue Reading" : @"Start Reading"];
    [_startReadingButton setTarget:self];
    [_startReadingButton setAction:@selector(startReadingClicked:)];
    [_startReadingButton setBezelStyle:NSRoundedBezelStyle];
    [contentView addSubview:_startReadingButton];
    
    // Delete Button
    _deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(280, 200, 200, 40)];
    [_deleteButton setTitle:@"Delete Book"];
    [_deleteButton setTarget:self];
    [_deleteButton setAction:@selector(deleteClicked:)];
    [_deleteButton setBezelStyle:NSRoundedBezelStyle];
    [contentView addSubview:_deleteButton];
}

- (NSString *)formatFileSize:(long long)bytes {
    if (bytes == 0) return @"0 B";
    double k = 1024.0;
    NSArray *sizes = [NSArray arrayWithObjects:@"B", @"KB", @"MB", @"GB", nil];
    int i = (int)(log(bytes) / log(k));
    double size = bytes / pow(k, i);
    return [NSString stringWithFormat:@"%.1f %@", size, [sizes objectAtIndex:i]];
}

- (IBAction)startReadingClicked:(id)sender {
    if ([_delegate respondsToSelector:@selector(bookDetailDidRequestStartReading:)]) {
        [_delegate bookDetailDidRequestStartReading:_book];
    }
    [self.window close];
}

- (IBAction)deleteClicked:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Delete Book"];
    [alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", _book.title]];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        if ([_delegate respondsToSelector:@selector(bookDetailDidRequestDelete:)]) {
            [_delegate bookDetailDidRequestDelete:_book];
        }
        [self.window close];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([_delegate respondsToSelector:@selector(bookDetailDidClose)]) {
        [_delegate bookDetailDidClose];
    }
}

@end
