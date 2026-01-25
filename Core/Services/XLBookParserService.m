//
//  XLBookParserService.m
//  Xenolexia
//

#import "XLBookParserService.h"

@implementation XLBookParserService

+ (instancetype)sharedService {
    static XLBookParserService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc] init];
    });
    return sharedService;
}

- (void)parseBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    if (!filePath || filePath.length == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}]);
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                code:2
                                            userInfo:@{NSLocalizedDescriptionKey: @"File does not exist"}]);
        }
        return;
    }
    
    // Detect format
    XLBookFormat format = [self detectFormat:filePath];
    
    // Parse based on format
    switch (format) {
        case XLBookFormatEpub:
            [self parseEpubAtPath:filePath withCompletion:completion];
            break;
        case XLBookFormatTxt:
            [self parseTxtAtPath:filePath withCompletion:completion];
            break;
        default:
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                    code:3
                                                userInfo:@{NSLocalizedDescriptionKey: @"Unsupported format"}]);
            }
            break;
    }
}

- (void)getChapterAtIndex:(NSInteger)chapterIndex
                 fromPath:(NSString *)filePath
           withCompletion:(void(^)(XLChapter * _Nullable chapter, NSError * _Nullable error))completion {
    [self parseBookAtPath:filePath withCompletion:^(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        if (chapterIndex < 0 || chapterIndex >= parsedBook.chapters.count) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                    code:4
                                                userInfo:@{NSLocalizedDescriptionKey: @"Chapter index out of range"}]);
            }
            return;
        }
        
        if (completion) {
            completion(parsedBook.chapters[chapterIndex], nil);
        }
    }];
}

- (void)getTableOfContentsFromPath:(NSString *)filePath
                      withCompletion:(void(^)(NSArray<XLTOCItem *> * _Nullable toc, NSError * _Nullable error))completion {
    [self parseBookAtPath:filePath withCompletion:^(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        if (completion) {
            completion(parsedBook.tableOfContents, nil);
        }
    }];
}

- (void)getMetadataFromPath:(NSString *)filePath
              withCompletion:(void(^)(XLBookMetadata * _Nullable metadata, NSError * _Nullable error))completion {
    [self parseBookAtPath:filePath withCompletion:^(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        if (completion) {
            completion(parsedBook.metadata, nil);
        }
    }];
}

#pragma mark - Private Methods

- (XLBookFormat)detectFormat:(NSString *)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"epub"]) {
        return XLBookFormatEpub;
    } else if ([extension isEqualToString:@"fb2"]) {
        return XLBookFormatFb2;
    } else if ([extension isEqualToString:@"mobi"]) {
        return XLBookFormatMobi;
    } else if ([extension isEqualToString:@"txt"]) {
        return XLBookFormatTxt;
    }
    return XLBookFormatTxt; // Default
}

- (void)parseTxtAtPath:(NSString *)filePath
        withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    
    if (error) {
        if (completion) completion(nil, error);
        return;
    }
    
    // Create metadata from filename
    NSString *fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    XLBookMetadata *metadata = [[XLBookMetadata alloc] init];
    metadata.title = fileName;
    metadata.author = nil;
    
    // Split into chapters (by double newlines or page breaks)
    NSArray<NSString *> *paragraphs = [content componentsSeparatedByString:@"\n\n"];
    NSMutableArray<XLChapter *> *chapters = [NSMutableArray array];
    
    NSInteger wordCount = 0;
    for (NSInteger i = 0; i < paragraphs.count; i++) {
        NSString *paragraph = paragraphs[i];
        if (paragraph.length > 0) {
            XLChapter *chapter = [[XLChapter alloc] init];
            chapter.chapterId = [[NSUUID UUID] UUIDString];
            chapter.title = [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
            chapter.index = i;
            chapter.content = paragraph;
            
            // Count words (simple whitespace split)
            NSArray<NSString *> *words = [paragraph componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
            chapter.wordCount = words.count;
            wordCount += chapter.wordCount;
            
            [chapters addObject:chapter];
        }
    }
    
    XLParsedBook *parsedBook = [[XLParsedBook alloc] init];
    parsedBook.metadata = metadata;
    parsedBook.chapters = chapters;
    parsedBook.tableOfContents = @[];
    parsedBook.totalWordCount = wordCount;
    
    if (completion) {
        completion(parsedBook, nil);
    }
}

- (void)parseEpubAtPath:(NSString *)filePath
         withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    // EPUB parsing is complex and requires ZIP extraction and XML parsing
    // For now, return an error indicating EPUB support needs to be implemented
    // This can be extended with a library like ZipArchive or using Foundation's NSFileManager with ZIP support
    if (completion) {
        completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                             code:5
                                         userInfo:@{NSLocalizedDescriptionKey: @"EPUB parsing not yet implemented. Please use TXT format for now."}]);
    }
}

@end
