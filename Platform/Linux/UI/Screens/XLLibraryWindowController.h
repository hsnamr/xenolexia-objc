//
//  XLLibraryWindowController.h
//  Xenolexia
//
//  Library screen window controller for Linux

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Book.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@protocol XLLibraryWindowDelegate <NSObject>
- (void)libraryDidSelectBook:(XLBook *)book;
- (void)libraryDidRequestImport;
- (void)libraryDidRequestDeleteBook:(XLBook *)book;
- (void)libraryDidRequestBookDetail:(XLBook *)book;
@end

@class XLStorageService;

@interface XLLibraryWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, XLStorageServiceDelegate> {
    id _delegate;
    NSArray *_books;
    NSArray *_filteredBooks;
    NSTableView *_tableView;
    NSSearchField *_searchField;
    NSButton *_importButton;
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
