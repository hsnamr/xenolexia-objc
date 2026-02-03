//
//  XLReviewWindowController.m
//  Xenolexia
//
//  Review window implementation (Phase 3): due count, card front/back, SM-2 grade buttons

#import "XLReviewWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"

static const NSInteger kReviewBatchSize = 20;

@interface XLReviewWindowController ()
- (void)showCurrentCard;
- (void)showFront;
- (void)showBack;
- (void)gradeAndAdvance:(NSInteger)quality;
- (void)setGradeButtonsHidden:(BOOL)hidden;
- (void)setCardAreaHidden:(BOOL)hidden;
@end

@implementation XLReviewWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _dueItems = [[NSMutableArray alloc] init];
        _dueCount = 0;
        _reviewedCount = 0;
        _currentIndex = 0;
        _showingBack = NO;
        _storageService = [XLStorageService sharedService];
    }
    return self;
}

- (void)dealloc {
    [_dueItems release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSView *contentView = [self.window contentView];
    [self.window setTitle:@"Xenolexia - Review"];
    [self.window setMinSize:NSMakeSize(500, 400)];

    _dueLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 380, 200, 24)];
    [_dueLabel setStringValue:@"Due today: 0"];
    [_dueLabel setEditable:NO];
    [_dueLabel setBordered:NO];
    [_dueLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_dueLabel setFont:[NSFont systemFontOfSize:14]];
    [contentView addSubview:_dueLabel];

    _reviewedLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(240, 380, 150, 24)];
    [_reviewedLabel setStringValue:@"Reviewed: 0"];
    [_reviewedLabel setEditable:NO];
    [_reviewedLabel setBordered:NO];
    [_reviewedLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_reviewedLabel setFont:[NSFont systemFontOfSize:14]];
    [contentView addSubview:_reviewedLabel];

    _noCardsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(80, 200, 340, 60)];
    [_noCardsLabel setStringValue:@"No cards due right now."];
    [_noCardsLabel setEditable:NO];
    [_noCardsLabel setBordered:NO];
    [_noCardsLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_noCardsLabel setFont:[NSFont systemFontOfSize:18]];
    [_noCardsLabel setAlignment:NSCenterTextAlignment];
    [contentView addSubview:_noCardsLabel];

    _cardLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 280, 420, 60)];
    [_cardLabel setEditable:NO];
    [_cardLabel setBordered:NO];
    [_cardLabel setBackgroundColor:[NSColor textBackgroundColor]];
    [_cardLabel setFont:[NSFont systemFontOfSize:24]];
    [_cardLabel setAlignment:NSCenterTextAlignment];
    [_cardLabel setSelectable:YES];
    [contentView addSubview:_cardLabel];

    _contextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 220, 420, 50)];
    [_contextLabel setEditable:NO];
    [_contextLabel setBordered:NO];
    [_contextLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_contextLabel setFont:[NSFont systemFontOfSize:14]];
    [_contextLabel setAlignment:NSCenterTextAlignment];
    [_contextLabel setSelectable:YES];
    [contentView addSubview:_contextLabel];

    _showAnswerButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 170, 100, 32)];
    [_showAnswerButton setTitle:@"Show answer"];
    [_showAnswerButton setTarget:self];
    [_showAnswerButton setAction:@selector(showAnswerClicked:)];
    [contentView addSubview:_showAnswerButton];

    _gradeButtonsBox = [[NSBox alloc] initWithFrame:NSMakeRect(40, 30, 420, 120)];
    [_gradeButtonsBox setTitle:@""];
    [contentView addSubview:_gradeButtonsBox];
    NSView *boxContent = [_gradeButtonsBox contentView];
    CGFloat btnW = 70;
    CGFloat x0 = 20;
    _againButton = [[NSButton alloc] initWithFrame:NSMakeRect(x0, 40, btnW, 28)];
    [_againButton setTitle:@"Again"];
    [_againButton setTarget:self];
    [_againButton setAction:@selector(gradeAgain:)];
    [boxContent addSubview:_againButton];
    _hardButton = [[NSButton alloc] initWithFrame:NSMakeRect(x0 + 80, 40, btnW, 28)];
    [_hardButton setTitle:@"Hard"];
    [_hardButton setTarget:self];
    [_hardButton setAction:@selector(gradeHard:)];
    [boxContent addSubview:_hardButton];
    _goodButton = [[NSButton alloc] initWithFrame:NSMakeRect(x0 + 160, 40, btnW, 28)];
    [_goodButton setTitle:@"Good"];
    [_goodButton setTarget:self];
    [_goodButton setAction:@selector(gradeGood:)];
    [boxContent addSubview:_goodButton];
    _easyButton = [[NSButton alloc] initWithFrame:NSMakeRect(x0 + 240, 40, btnW, 28)];
    [_easyButton setTitle:@"Easy"];
    [_easyButton setTarget:self];
    [_easyButton setAction:@selector(gradeEasy:)];
    [boxContent addSubview:_easyButton];
    _alreadyKnewButton = [[NSButton alloc] initWithFrame:NSMakeRect(x0 + 320, 40, 80, 28)];
    [_alreadyKnewButton setTitle:@"Already knew"];
    [_alreadyKnewButton setTarget:self];
    [_alreadyKnewButton setAction:@selector(gradeAlreadyKnew:)];
    [boxContent addSubview:_alreadyKnewButton];

    [self setCardAreaHidden:YES];
    [self setGradeButtonsHidden:YES];
    [_noCardsLabel setHidden:YES];
    [self loadDueItems];
}

- (void)loadDueItems {
    [_dueLabel setStringValue:@"Loading..."];
    [_storageService getVocabularyDueForReviewWithLimit:kReviewBatchSize delegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didGetVocabularyDueForReview:(NSArray *)items withError:(NSError *)error {
    if (error) {
        [_dueLabel setStringValue:@"Error loading"];
        [_noCardsLabel setHidden:NO];
        [self setCardAreaHidden:YES];
        return;
    }
    [_dueItems removeAllObjects];
    if (items && [items count] > 0) {
        [_dueItems addObjectsFromArray:items];
        _dueCount = [_dueItems count];
        _reviewedCount = 0;
        _currentIndex = 0;
        _showingBack = NO;
        [_dueLabel setStringValue:[NSString stringWithFormat:@"Due today: %ld", (long)_dueCount]];
        [_noCardsLabel setHidden:YES];
        [self setCardAreaHidden:NO];
        [self showCurrentCard];
    } else {
        _dueCount = 0;
        [_dueLabel setStringValue:@"Due today: 0"];
        [_reviewedLabel setStringValue:@"Reviewed: 0"];
        [_noCardsLabel setHidden:NO];
        [self setCardAreaHidden:YES];
    }
}

- (void)storageService:(id)service didRecordReviewForItemId:(NSString *)itemId withSuccess:(BOOL)success error:(NSError *)error {
    if (!success) return;
    _reviewedCount++;
    [_reviewedLabel setStringValue:[NSString stringWithFormat:@"Reviewed: %ld", (long)_reviewedCount]];
    if (_currentIndex < [_dueItems count]) {
        [_dueItems removeObjectAtIndex:_currentIndex];
    }
    if ([_dueItems count] == 0) {
        [_storageService getVocabularyDueForReviewWithLimit:kReviewBatchSize delegate:self];
        return;
    }
    if (_currentIndex >= [_dueItems count]) {
        _currentIndex = [_dueItems count] - 1;
    }
    _showingBack = NO;
    [self showCurrentCard];
}

#pragma mark - Card display

- (void)showCurrentCard {
    if (_currentIndex < 0 || _currentIndex >= [_dueItems count]) {
        [self setCardAreaHidden:YES];
        [_noCardsLabel setHidden:NO];
        [_noCardsLabel setStringValue:@"No more cards in this batch."];
        return;
    }
    _showingBack = NO;
    [self showFront];
    [self setGradeButtonsHidden:YES];
    [_showAnswerButton setHidden:NO];
}

- (void)showFront {
    XLVocabularyItem *item = [_dueItems objectAtIndex:_currentIndex];
    [_cardLabel setStringValue:item.targetWord ?: @""];
    [_contextLabel setStringValue:@""];
    [_contextLabel setHidden:YES];
}

- (void)showBack {
    XLVocabularyItem *item = [_dueItems objectAtIndex:_currentIndex];
    [_cardLabel setStringValue:item.sourceWord ?: @""];
    [_contextLabel setStringValue:item.contextSentence ?: @""];
    [_contextLabel setHidden:NO];
}

- (void)setGradeButtonsHidden:(BOOL)hidden {
    [_againButton setHidden:hidden];
    [_hardButton setHidden:hidden];
    [_goodButton setHidden:hidden];
    [_easyButton setHidden:hidden];
    [_alreadyKnewButton setHidden:hidden];
}

- (void)setCardAreaHidden:(BOOL)hidden {
    [_cardLabel setHidden:hidden];
    [_contextLabel setHidden:hidden];
    [_showAnswerButton setHidden:hidden];
    [_gradeButtonsBox setHidden:hidden];
}

- (void)showAnswerClicked:(id)sender {
    _showingBack = YES;
    [self showBack];
    [_showAnswerButton setHidden:YES];
    [self setGradeButtonsHidden:NO];
}

- (void)gradeAndAdvance:(NSInteger)quality {
    if (_currentIndex < 0 || _currentIndex >= [_dueItems count]) return;
    XLVocabularyItem *item = [_dueItems objectAtIndex:_currentIndex];
    [_storageService recordReviewForItemId:item.vocabularyId quality:quality delegate:self];
}

- (void)gradeAgain:(id)sender { [self gradeAndAdvance:0]; }
- (void)gradeHard:(id)sender { [self gradeAndAdvance:1]; }
- (void)gradeGood:(id)sender { [self gradeAndAdvance:3]; }
- (void)gradeEasy:(id)sender { [self gradeAndAdvance:4]; }
- (void)gradeAlreadyKnew:(id)sender { [self gradeAndAdvance:5]; }

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(reviewWindowDidClose)]) {
        [_delegate reviewWindowDidClose];
    }
}

@end
