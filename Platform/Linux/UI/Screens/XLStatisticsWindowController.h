//
//  XLStatisticsWindowController.h
//  Xenolexia
//
//  Statistics window (Phase 5): reading stats and "reading over time" 7-day chart

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLStatisticsWindowDelegate <NSObject>
- (void)statisticsWindowDidClose;
@end

/// Simple view that draws a 7-day bar chart (words revealed per day)
@interface XLWordsRevealedChartView : NSView
@property (nonatomic, copy) NSArray *wordsRevealedByDay; // NSDictionary with @"dayLabel", @"wordsRevealed"
@end

@interface XLStatisticsWindowController : NSWindowController <XLStorageServiceDelegate> {
    XLStorageService *_storageService;
    XLReadingStats *_stats;
    NSArray *_wordsRevealedByDay;
    NSTextField *_totalBooksReadLabel;
    NSTextField *_totalReadingTimeLabel;
    NSTextField *_totalWordsLearnedLabel;
    NSTextField *_currentStreakLabel;
    NSTextField *_longestStreakLabel;
    NSTextField *_wordsRevealedTodayLabel;
    NSTextField *_wordsSavedTodayLabel;
    NSTextField *_averageSessionLabel;
    NSTextField *_chartTitleLabel;
    XLWordsRevealedChartView *_chartView;
    NSButton *_refreshButton;
    NSProgressIndicator *_progressIndicator;
}

@property (nonatomic, assign) id<XLStatisticsWindowDelegate> delegate;

- (void)loadStats;

@end
