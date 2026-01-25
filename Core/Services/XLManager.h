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

/// Main manager for Xenolexia operations
@interface XLManager : NSObject

+ (instancetype)sharedManager;

// Book operations
- (void)importBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLBook * _Nullable book, NSError * _Nullable error))completion;

- (void)processBook:(XLBook *)book
     withCompletion:(void(^)(XLProcessedChapter * _Nullable processedChapter, NSError * _Nullable error))completion;

// Translation operations
- (void)translateWord:(NSString *)word
       withCompletion:(void(^)(NSString * _Nullable translatedWord, NSError * _Nullable error))completion;

- (void)pronounceWord:(NSString *)word;

// Vocabulary operations
- (void)saveWordToVocabulary:(XLVocabularyItem *)item
               withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion;

// Legacy methods (for backward compatibility)
- (void)downloadFile:(NSURL *)fileURL;
- (void)listFiles;
- (NSString *)replaceWordsInDocument:(NSString *)htmlString;

@end

NS_ASSUME_NONNULL_END
