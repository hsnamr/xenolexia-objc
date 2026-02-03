//
//  XLStorageService.h
//  Xenolexia
//
//  Storage service for books and vocabulary (SQLite-based)

#import <Foundation/Foundation.h>
#import "../Models/Book.h"
#import "../Models/Vocabulary.h"
#import "../Models/Reader.h"
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
/// Spec: items due for review (status != learned and last_reviewed_at + interval*86400000 <= now), limit default 20
- (void)getVocabularyDueForReviewWithLimit:(NSInteger)limit delegate:(id<XLStorageServiceDelegate>)delegate;
/// Spec: record one SM-2 review step (quality 0-5); formula matches xenolexia-shared-c/sm2.c
- (void)recordReviewForItemId:(NSString *)itemId quality:(NSInteger)quality delegate:(id<XLStorageServiceDelegate>)delegate;

// Preferences (Phase 0)
- (void)getPreferencesWithDelegate:(id<XLStorageServiceDelegate>)delegate;
- (void)savePreferences:(XLUserPreferences *)prefs delegate:(id<XLStorageServiceDelegate>)delegate;

// Reading sessions (Phase 0)
- (void)startReadingSessionForBookId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)endReadingSessionWithId:(NSString *)sessionId wordsRevealed:(NSInteger)wordsRevealed wordsSaved:(NSInteger)wordsSaved delegate:(id<XLStorageServiceDelegate>)delegate;
- (void)getActiveSessionForBookId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate;

// Statistics (Phase 0)
- (void)getReadingStatsWithDelegate:(id<XLStorageServiceDelegate>)delegate;

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
