//
//  XLReviewWindowController.h
//  Xenolexia
//
//  Review window (Phase 3): SRS flashcards, grade buttons

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Vocabulary.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLReviewWindowDelegate <NSObject>
- (void)reviewWindowDidClose;
@end

@interface XLReviewWindowController : NSWindowController <XLStorageServiceDelegate> {
    NSMutableArray *_dueItems;
    NSInteger _dueCount;
    NSInteger _reviewedCount;
    NSInteger _currentIndex;
    BOOL _showingBack;
    NSTextField *_dueLabel;
    NSTextField *_reviewedLabel;
    NSTextField *_cardLabel;
    NSTextField *_contextLabel;
    NSButton *_showAnswerButton;
    NSBox *_gradeButtonsBox;
    NSButton *_againButton;
    NSButton *_hardButton;
    NSButton *_goodButton;
    NSButton *_easyButton;
    NSButton *_alreadyKnewButton;
    NSTextField *_noCardsLabel;
    XLStorageService *_storageService;
}

@property (nonatomic, assign) id<XLReviewWindowDelegate> delegate;

- (void)loadDueItems;

@end
