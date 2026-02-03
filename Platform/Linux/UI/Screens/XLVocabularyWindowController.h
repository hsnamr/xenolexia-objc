//
//  XLVocabularyWindowController.h
//  Xenolexia
//
//  Vocabulary list window (Phase 2): list, search, edit, delete, export

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Vocabulary.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLVocabularyWindowDelegate <NSObject>
- (void)vocabularyWindowDidClose;
- (void)vocabularyDidRequestReview;
@end

@interface XLVocabularyWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, XLStorageServiceDelegate> {
    NSArray *_items;
    NSArray *_filteredItems;
    NSInteger _dueCount;
    NSTableView *_tableView;
    NSSearchField *_searchField;
    NSPopUpButton *_statusFilterPopUp;
    NSTextField *_statusLabel;
    NSButton *_editButton;
    NSButton *_deleteButton;
    NSButton *_exportButton;
    NSButton *_reviewDueButton;
    XLStorageService *_storageService;
}

@property (nonatomic, assign) id<XLVocabularyWindowDelegate> delegate;

- (void)refreshVocabulary;
- (void)refreshDueCount;

@end
