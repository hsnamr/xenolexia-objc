//
//  XLStatisticsWindowController.h
//  Xenolexia
//
//  Statistics window (Phase 6): reading and vocabulary stats from getReadingStatsWithDelegate

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLStatisticsWindowDelegate <NSObject>
- (void)statisticsWindowDidClose;
@end

@interface XLStatisticsWindowController : NSWindowController <XLStorageServiceDelegate> {
    XLStorageService *_storageService;
    XLReadingStats *_stats;
    NSTextField *_totalBooksReadLabel;
    NSTextField *_totalReadingTimeLabel;
    NSTextField *_totalWordsLearnedLabel;
    NSTextField *_currentStreakLabel;
    NSTextField *_longestStreakLabel;
    NSTextField *_wordsRevealedTodayLabel;
    NSTextField *_wordsSavedTodayLabel;
    NSTextField *_averageSessionLabel;
    NSButton *_refreshButton;
    NSProgressIndicator *_progressIndicator;
}

@property (nonatomic, assign) id<XLStatisticsWindowDelegate> delegate;

- (void)loadStats;

@end
