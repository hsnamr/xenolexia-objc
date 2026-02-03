//
//  XLLibraryWindowController.h
//  Xenolexia
//
//  Library screen window controller for Linux

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Book.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"
#import "../../../Core/Services/XLManager.h"

@protocol XLLibraryWindowDelegate <NSObject>
- (void)libraryDidSelectBook:(XLBook *)book;
- (void)libraryDidRequestImport;
- (void)libraryDidRequestDeleteBook:(XLBook *)book;
- (void)libraryDidRequestBookDetail:(XLBook *)book;
- (void)libraryDidRequestVocabulary;
- (void)libraryDidRequestReview;
- (void)libraryDidRequestSettings;
- (void)libraryDidRequestStatistics;
@end

@class XLStorageService;

@interface XLLibraryWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, XLStorageServiceDelegate, XLManagerDelegate> {
    id _delegate;
    NSArray *_books;
    NSArray *_filteredBooks;
    NSTableView *_tableView;
    NSScrollView *_tableScrollView;
    NSScrollView *_gridScrollView;
    NSView *_gridContentView;
    NSPopUpButton *_viewPopUp;
    BOOL _showingGrid;
    NSSearchField *_searchField;
    NSButton *_importButton;
    NSButton *_vocabularyButton;
    NSButton *_reviewButton;
    NSButton *_settingsButton;
    NSButton *_statisticsButton;
    NSButton *_sortButton;
    NSButton *_deleteButton;
    NSTextField *_statusLabel;
    XLStorageService *_storageService;
    NSString *_currentSortBy;
    NSString *_currentSortOrder;
}

- (void)refreshBooks;
- (void)reloadData;

@end
