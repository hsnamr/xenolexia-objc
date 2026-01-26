//
//  XLBookParserService.h
//  Xenolexia
//
//  Book parser service interface

#import <Foundation/Foundation.h>
#import "../Models/Book.h"

NS_ASSUME_NONNULL_BEGIN

/// Book parser service protocol
@protocol XLBookParserService <NSObject>

/// Parse a book file and extract its content
- (void)parseBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLParsedBook *parsedBook, NSError *error))completion;

/// Get a specific chapter by index
- (void)getChapterAtIndex:(NSInteger)chapterIndex
                 fromPath:(NSString *)filePath
           withCompletion:(void(^)(XLChapter *chapter, NSError *error))completion;

/// Get table of contents
- (void)getTableOfContentsFromPath:(NSString *)filePath
                      withCompletion:(void(^)(NSArray *toc, NSError *error))completion;

/// Get book metadata
- (void)getMetadataFromPath:(NSString *)filePath
              withCompletion:(void(^)(XLBookMetadata *metadata, NSError *error))completion;

@end

/// Book parser service implementation
@interface XLBookParserService : NSObject <XLBookParserService>

+ (instancetype)sharedService;

@end

NS_ASSUME_NONNULL_END
