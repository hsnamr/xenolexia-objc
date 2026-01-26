//
//  XLLibraryWindowController.h
//  Xenolexia
//
//  Library screen window controller for Linux

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Book.h"

@protocol XLLibraryWindowDelegate <NSObject>
- (void)libraryDidSelectBook:(XLBook *)book;
- (void)libraryDidRequestImport;
- (void)libraryDidRequestDeleteBook:(XLBook *)book;
@end

@interface XLLibraryWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic, retain) NSArray *filteredBooks;

- (void)refreshBooks;
- (void)reloadData;

@end
