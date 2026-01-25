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
- (void)saveBook:(XLBook *)book withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;
- (void)getBookWithId:(NSString *)bookId withCompletion:(void(^)(XLBook * _Nullable book, NSError * _Nullable error))completion;
- (void)getAllBooksWithCompletion:(void(^)(NSArray<XLBook *> * _Nullable books, NSError * _Nullable error))completion;
- (void)deleteBookWithId:(NSString *)bookId withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// Vocabulary operations
- (void)saveVocabularyItem:(XLVocabularyItem *)item withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;
- (void)getVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(XLVocabularyItem * _Nullable item, NSError * _Nullable error))completion;
- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion;
- (void)deleteVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;
- (void)searchVocabularyWithQuery:(NSString *)query withCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion;

@end

/// Storage service implementation
@interface XLStorageService : NSObject <XLStorageService>

+ (instancetype)sharedService;

/// Initialize the database (creates tables if needed)
- (void)initializeDatabaseWithCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
