//
//  XLStorageServiceBlockHelper.h
//  Xenolexia
//
//  Helper class to bridge block-based API to delegate-based API
//  This is used internally by services that still use blocks

#import <Foundation/Foundation.h>
#import "XLStorageServiceDelegate.h"

@interface XLStorageServiceBlockHelper : NSObject <XLStorageServiceDelegate>

@property (nonatomic, copy) void (^saveBookCompletion)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^getBookCompletion)(XLBook *book, NSError *error);
@property (nonatomic, copy) void (^getAllBooksCompletion)(NSArray *books, NSError *error);
@property (nonatomic, copy) void (^deleteBookCompletion)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^initDatabaseCompletion)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^saveVocabularyItemCompletion)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^getAllVocabularyItemsCompletion)(NSArray *items, NSError *error);

@end
