//
//  XLStatisticsWindowController.m
//  Xenolexia
//
//  Statistics window implementation (Phase 5): stats + 7-day reading over time chart

#import "XLStatisticsWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"

#define ROW(y) (520 - (y) * 36)
#define LABEL_X 24
#define VALUE_X 280
#define W 200
static const NSInteger kChartLastDays = 7;

@implementation XLWordsRevealedChartView {
    NSArray *_wordsRevealedByDay;
}

- (NSArray *)wordsRevealedByDay {
    return _wordsRevealedByDay;
}

- (void)setWordsRevealedByDay:(NSArray *)wordsRevealedByDay {
    if (_wordsRevealedByDay != wordsRevealedByDay) {
        [_wordsRevealedByDay release];
        _wordsRevealedByDay = [wordsRevealedByDay copy];
    }
    [self setNeedsDisplay:YES];
}

- (void)dealloc {
    [_wordsRevealedByDay release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    NSArray *items = _wordsRevealedByDay;
    if (!items || [items count] == 0) return;
    NSUInteger n = [items count];
    NSInteger maxVal = 1;
    for (NSUInteger i = 0; i < n; i++) {
        NSDictionary *d = [items objectAtIndex:i];
        NSNumber *wr = [d objectForKey:@"wordsRevealed"];
        if (wr && [wr integerValue] > maxVal) maxVal = [wr integerValue];
    }
    CGFloat barGap = 4.0;
    CGFloat labelH = 20.0;
    CGFloat chartTop = [self bounds].size.height - labelH - 4.0;
    CGFloat chartH = chartTop - 8.0;
    CGFloat totalGaps = barGap * (n + 1);
    CGFloat barW = ([self bounds].size.width - totalGaps) / (CGFloat)n;
    NSFont *labelFont = [NSFont systemFontOfSize:10];
    NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys:labelFont, NSFontAttributeName, [NSColor controlTextColor], NSForegroundColorAttributeName, nil];
    for (NSUInteger i = 0; i < n; i++) {
        NSDictionary *d = [items objectAtIndex:i];
        NSNumber *wr = [d objectForKey:@"wordsRevealed"];
        NSString *dayLabel = [d objectForKey:@"dayLabel"];
        NSInteger val = wr ? [wr integerValue] : 0;
        CGFloat barHeight = (maxVal > 0) ? (CGFloat)val / (CGFloat)maxVal * chartH : 0;
        CGFloat x = 8.0 + (CGFloat)i * (barW + barGap) + barGap;
        NSRect barRect = NSMakeRect(x, 8.0, barW, barHeight);
        [[NSColor colorWithCalibratedRed:0.3 green:0.5 blue:0.9 alpha:1.0] set];
        NSRectFill(barRect);
        if (dayLabel && [dayLabel length] > 0) {
            CGFloat labelY = [self bounds].size.height - labelH;
            [dayLabel drawAtPoint:NSMakePoint(x, labelY) withAttributes:labelAttrs];
        }
    }
}

@end

@interface XLStatisticsWindowController ()
- (void)updateDisplay;
- (void)updateChart;
- (NSTextField *)labelWithTitle:(NSString *)title atY:(CGFloat)y;
- (NSTextField *)valueLabelAtY:(CGFloat)y;
@end

@implementation XLStatisticsWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _storageService = [XLStorageService sharedService];
        _stats = nil;
        _wordsRevealedByDay = nil;
    }
    return self;
}

- (void)dealloc {
    [_stats release];
    [_wordsRevealedByDay release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSView *contentView = [self.window contentView];
    [self.window setTitle:@"Xenolexia - Statistics"];
    [self.window setContentSize:NSMakeSize(520, 560)];
    [self.window setMinSize:NSMakeSize(400, 480)];

    _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(220, 260, 80, 80)];
    [_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [_progressIndicator setIndeterminate:YES];
    [_progressIndicator setDisplayedWhenStopped:NO];
    [contentView addSubview:_progressIndicator];

    _chartTitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(LABEL_X, 218, 400, 20)];
    [_chartTitleLabel setStringValue:@"Reading over time (last 7 days)"];
    [_chartTitleLabel setEditable:NO];
    [_chartTitleLabel setBordered:NO];
    [_chartTitleLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_chartTitleLabel setFont:[NSFont systemFontOfSize:13]];
    [contentView addSubview:_chartTitleLabel];

    _chartView = [[XLWordsRevealedChartView alloc] initWithFrame:NSMakeRect(LABEL_X, 24, 472, 190)];
    [_chartView setAutoresizingMask:NSViewMinYMargin];
    [contentView addSubview:_chartView];

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

    _refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 4, 120, 24)];
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
    [_storageService getWordsRevealedByDayWithLastDays:kChartLastDays delegate:self];
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

- (void)storageService:(id)service didGetWordsRevealedByDay:(NSArray *)items withError:(NSError *)error {
    if (error || !items) {
        [_chartView setWordsRevealedByDay:[NSArray array]];
        return;
    }
    [_wordsRevealedByDay release];
    _wordsRevealedByDay = [items retain];
    [self updateChart];
}

- (void)updateChart {
    [_chartView setWordsRevealedByDay:_wordsRevealedByDay ?: [NSArray array]];
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
    [_progressIndicator startAnimation:nil];
    [_storageService getReadingStatsWithDelegate:self];
    [_storageService getWordsRevealedByDayWithLastDays:kChartLastDays delegate:self];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(statisticsWindowDidClose)]) {
        [_delegate statisticsWindowDidClose];
    }
}

@end
