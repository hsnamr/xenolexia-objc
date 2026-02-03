//
//  XLStatisticsWindowController.m
//  Xenolexia
//
//  Statistics window implementation (Phase 6)

#import "XLStatisticsWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"

#define ROW(y) (380 - (y) * 36)
#define LABEL_X 24
#define VALUE_X 280
#define W 200

@interface XLStatisticsWindowController ()
- (void)updateDisplay;
- (NSTextField *)labelWithTitle:(NSString *)title atY:(CGFloat)y;
- (NSTextField *)valueLabelAtY:(CGFloat)y;
@end

@implementation XLStatisticsWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _storageService = [XLStorageService sharedService];
        _stats = nil;
    }
    return self;
}

- (void)dealloc {
    [_stats release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSView *contentView = [self.window contentView];
    [self.window setTitle:@"Xenolexia - Statistics"];
    [self.window setContentSize:NSMakeSize(520, 420)];
    [self.window setMinSize:NSMakeSize(400, 380)];

    _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(220, 180, 80, 80)];
    [_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [_progressIndicator setIndeterminate:YES];
    [_progressIndicator setDisplayedWhenStopped:NO];
    [contentView addSubview:_progressIndicator];

    NSInteger y = 0;
    _totalBooksReadLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Total books read" atY:ROW(y)]];
    [contentView addSubview:_totalBooksReadLabel];
    y++;

    _totalReadingTimeLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Total reading time (minutes)" atY:ROW(y)]];
    [contentView addSubview:_totalReadingTimeLabel];
    y++;

    _totalWordsLearnedLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Total words learned" atY:ROW(y)]];
    [contentView addSubview:_totalWordsLearnedLabel];
    y++;

    _currentStreakLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Current streak (days)" atY:ROW(y)]];
    [contentView addSubview:_currentStreakLabel];
    y++;

    _longestStreakLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Longest streak (days)" atY:ROW(y)]];
    [contentView addSubview:_longestStreakLabel];
    y++;

    _wordsRevealedTodayLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Words revealed today" atY:ROW(y)]];
    [contentView addSubview:_wordsRevealedTodayLabel];
    y++;

    _wordsSavedTodayLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Words saved today" atY:ROW(y)]];
    [contentView addSubview:_wordsSavedTodayLabel];
    y++;

    _averageSessionLabel = [self valueLabelAtY:ROW(y)];
    [contentView addSubview:[self labelWithTitle:@"Average session (minutes)" atY:ROW(y)]];
    [contentView addSubview:_averageSessionLabel];
    y++;

    _refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 24, 120, 32)];
    [_refreshButton setTitle:@"Refresh"];
    [_refreshButton setTarget:self];
    [_refreshButton setAction:@selector(refreshClicked:)];
    [contentView addSubview:_refreshButton];

    [self updateDisplay];
    [self loadStats];
}

- (NSTextField *)labelWithTitle:(NSString *)title atY:(CGFloat)y {
    NSTextField *l = [[NSTextField alloc] initWithFrame:NSMakeRect(LABEL_X, y, 240, 24)];
    [l setStringValue:title];
    [l setEditable:NO];
    [l setBordered:NO];
    [l setBackgroundColor:[NSColor controlBackgroundColor]];
    [l setFont:[NSFont systemFontOfSize:14]];
    return [l autorelease];
}

- (NSTextField *)valueLabelAtY:(CGFloat)y {
    NSTextField *l = [[NSTextField alloc] initWithFrame:NSMakeRect(VALUE_X, y, W, 24)];
    [l setStringValue:@"—"];
    [l setEditable:NO];
    [l setBordered:NO];
    [l setBackgroundColor:[NSColor controlBackgroundColor]];
    [l setFont:[NSFont boldSystemFontOfSize:14]];
    [l setAlignment:NSRightTextAlignment];
    return [l autorelease];
}

- (void)loadStats {
    [_progressIndicator startAnimation:nil];
    [_storageService getReadingStatsWithDelegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didGetReadingStats:(XLReadingStats *)stats withError:(NSError *)error {
    [_progressIndicator stopAnimation:nil];
    if (error || !stats) {
        [_totalBooksReadLabel setStringValue:@"Error"];
        return;
    }
    [_stats release];
    _stats = [stats retain];
    [self updateDisplay];
}

- (void)updateDisplay {
    if (!_stats) {
        [_totalBooksReadLabel setStringValue:@"—"];
        [_totalReadingTimeLabel setStringValue:@"—"];
        [_totalWordsLearnedLabel setStringValue:@"—"];
        [_currentStreakLabel setStringValue:@"—"];
        [_longestStreakLabel setStringValue:@"—"];
        [_wordsRevealedTodayLabel setStringValue:@"—"];
        [_wordsSavedTodayLabel setStringValue:@"—"];
        [_averageSessionLabel setStringValue:@"—"];
        return;
    }
    [_totalBooksReadLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.totalBooksRead]];
    NSInteger totalMinutes = (NSInteger)(_stats.totalReadingTime / 60.0);
    [_totalReadingTimeLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)totalMinutes]];
    [_totalWordsLearnedLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.totalWordsLearned]];
    [_currentStreakLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.currentStreak]];
    [_longestStreakLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.longestStreak]];
    [_wordsRevealedTodayLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.wordsRevealedToday]];
    [_wordsSavedTodayLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)_stats.wordsSavedToday]];
    NSInteger avgMinutes = (NSInteger)(_stats.averageSessionDuration / 60.0);
    [_averageSessionLabel setStringValue:[NSString stringWithFormat:@"%ld", (long)avgMinutes]];
}

- (IBAction)refreshClicked:(id)sender {
    (void)sender;
    [self loadStats];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(statisticsWindowDidClose)]) {
        [_delegate statisticsWindowDidClose];
    }
}

@end
