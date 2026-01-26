//
//  XLManager.h
//  Xenolexia
//
//  Main manager class (refactored from Manager)

#import <Foundation/Foundation.h>
#import "../Models/Book.h"
#import "../Models/Vocabulary.h"
#import "../Models/Reader.h"

NS_ASSUME_NONNULL_BEGIN

/// Delegate protocol for XLManager (GNUStep compatible - no blocks)
@protocol XLManagerDelegate <NSObject>

@optional

// Book operations
- (void)manager:(id)manager didImportBook:(XLBook *)book withError:(NSError *)error;
- (void)manager:(id)manager didProcessChapter:(XLProcessedChapter *)chapter withError:(NSError *)error;

// Translation operations
- (void)manager:(id)manager didTranslateWord:(NSString *)word toTranslation:(NSString *)translation withError:(NSError *)error;

// Vocabulary operations
- (void)manager:(id)manager didSaveWordToVocabulary:(XLVocabularyItem *)item withSuccess:(BOOL)success error:(NSError *)error;
- (void)manager:(id)manager didGetAllVocabularyItems:(NSArray *)items withError:(NSError *)error;

@end

/// Main manager for Xenolexia operations
@interface XLManager : NSObject

+ (instancetype)sharedManager;

// Book operations (block-based - for platforms with block support)
- (void)importBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLBook * _Nullable book, NSError * _Nullable error))completion;

- (void)processBook:(XLBook *)book
     withCompletion:(void(^)(XLProcessedChapter * _Nullable processedChapter, NSError * _Nullable error))completion;

// Book operations (delegate-based - GNUStep compatible)
- (void)importBookAtPath:(NSString *)filePath delegate:(id<XLManagerDelegate>)delegate;
- (void)processBook:(XLBook *)book delegate:(id<XLManagerDelegate>)delegate;

// Translation operations (block-based)
- (void)translateWord:(NSString *)word
       withCompletion:(void(^)(NSString * _Nullable translatedWord, NSError * _Nullable error))completion;

// Translation operations (delegate-based - GNUStep compatible)
- (void)translateWord:(NSString *)word delegate:(id<XLManagerDelegate>)delegate;

- (void)pronounceWord:(NSString *)word;

// Vocabulary operations (block-based)
- (void)saveWordToVocabulary:(XLVocabularyItem *)item
               withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion;

// Vocabulary operations (delegate-based - GNUStep compatible)
- (void)saveWordToVocabulary:(XLVocabularyItem *)item delegate:(id<XLManagerDelegate>)delegate;
- (void)getAllVocabularyItemsWithDelegate:(id<XLManagerDelegate>)delegate;

// Legacy methods (for backward compatibility)
- (void)downloadFile:(NSURL *)fileURL;
- (void)listFiles;
- (NSString *)replaceWordsInDocument:(NSString *)htmlString;

@end

NS_ASSUME_NONNULL_END
