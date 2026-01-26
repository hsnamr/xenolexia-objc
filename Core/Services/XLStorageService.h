//
//  XLStorageService.h
//  Xenolexia
//
//  Storage service for books and vocabulary (SQLite-based)

#import <Foundation/Foundation.h>
#import "../Models/Book.h"
#import "../Models/Vocabulary.h"

NS_ASSUME_NONNULL_BEGIN

/// Storage service protocol
@protocol XLStorageService <NSObject>

// Book operations
- (void)saveBook:(XLBook *)book withCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)getBookWithId:(NSString *)bookId withCompletion:(void(^)(XLBook *book, NSError *error))completion;
- (void)getAllBooksWithCompletion:(void(^)(NSArray *books, NSError *error))completion;
- (void)deleteBookWithId:(NSString *)bookId withCompletion:(void(^)(BOOL success, NSError *error))completion;

// Vocabulary operations
- (void)saveVocabularyItem:(XLVocabularyItem *)item withCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)getVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(XLVocabularyItem *item, NSError *error))completion;
- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray *items, NSError *error))completion;
- (void)deleteVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)searchVocabularyWithQuery:(NSString *)query withCompletion:(void(^)(NSArray *items, NSError *error))completion;

@end

/// Storage service implementation
@interface XLStorageService : NSObject <XLStorageService>

+ (instancetype)sharedService;

/// Initialize the database (creates tables if needed)
- (void)initializeDatabaseWithCompletion:(void(^)(BOOL success, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
