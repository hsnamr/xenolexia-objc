//
//  XLStorageService.h
//  Xenolexia
//
//  Storage service for books and vocabulary (SQLite-based)

#import <Foundation/Foundation.h>
#import "../Models/Book.h"
#import "../Models/Vocabulary.h"
#import "XLStorageServiceDelegate.h"

/// Storage service protocol
@protocol XLStorageService <NSObject>

// Book operations
- (void)saveBook:(XLBook *)book delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getBookWithId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getAllBooksWithDelegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getAllBooksWithSortBy:(NSString *)sortBy order:(NSString *)order delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)deleteBookWithId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate;

// Vocabulary operations
- (void)saveVocabularyItem:(XLVocabularyItem *)item delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getAllVocabularyItemsWithDelegate:(id<XLStorageServiceDelegate>)delegate;
- (void)deleteVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)searchVocabularyWithQuery:(NSString *)query delegate:(id<XLStorageServiceDelegate>)delegate;

@end

@class SSFileSystem;
struct sqlite3;

/// Storage service implementation
@interface XLStorageService : NSObject <XLStorageService> {
    NSString *_databasePath;
    struct sqlite3 *_database;
    SSFileSystem *_fileSystem;
    id<XLStorageServiceDelegate> _currentDelegate;
}

+ (instancetype)sharedService;

/// Initialize the database (creates tables if needed)
- (void)initializeDatabaseWithDelegate:(id<XLStorageServiceDelegate>)delegate;

@end
