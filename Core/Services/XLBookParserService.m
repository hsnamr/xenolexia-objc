//
//  XLBookParserService.m
//  Xenolexia
//

#import "XLBookParserService.h"
#import "XLEpubParser.h"
#import "XLNativeParsers.h"

@implementation XLBookParserService

+ (instancetype)sharedService {
    static XLBookParserService *sharedService = nil;
    if (sharedService == nil) {
        sharedService = [[self alloc] init];
    }
    return sharedService;
}

- (void)parseBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    if (!filePath || filePath.length == 0) {
        if (completion) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"File path is empty"
                                                                  forKey:NSLocalizedDescriptionKey];
            completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                code:1
                                            userInfo:userInfo]);
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        if (completion) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"File does not exist"
                                                                  forKey:NSLocalizedDescriptionKey];
            completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                code:2
                                            userInfo:userInfo]);
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
        case XLBookFormatPdf:
            [self parsePdfAtPath:filePath withCompletion:completion];
            break;
        case XLBookFormatFb2:
            [self parseFb2AtPath:filePath withCompletion:completion];
            break;
        case XLBookFormatMobi:
            [self parseMobiAtPath:filePath withCompletion:completion];
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
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Chapter index out of range"
                                                                      forKey:NSLocalizedDescriptionKey];
                completion(nil, [NSError errorWithDomain:@"XLBookParserService"
                                                    code:4
                                                userInfo:userInfo]);
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
    if ([extension isEqualToString:@"epub"]) return XLBookFormatEpub;
    if ([extension isEqualToString:@"fb2"]) return XLBookFormatFb2;
    if ([extension isEqualToString:@"mobi"] || [extension isEqualToString:@"azw"] || [extension isEqualToString:@"azw3"]) return XLBookFormatMobi;
    if ([extension isEqualToString:@"pdf"]) return XLBookFormatPdf;
    if ([extension isEqualToString:@"txt"]) return XLBookFormatTxt;
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
        if ([paragraph length] > 0) {
            XLChapter *chapter = [[XLChapter alloc] init];
            chapter.chapterId = [[NSUUID UUID] UUIDString];
            chapter.title = [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
            chapter.index = i;
            chapter.content = paragraph;
            
            // Count words (simple whitespace split)
            NSArray *words = [paragraph componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length > 0"];
            words = [words filteredArrayUsingPredicate:predicate];
            chapter.wordCount = [words count];
            wordCount += chapter.wordCount;
            
            [chapters addObject:chapter];
        }
    }
    
    XLParsedBook *parsedBook = [[XLParsedBook alloc] init];
    parsedBook.metadata = metadata;
    parsedBook.chapters = chapters;
    parsedBook.tableOfContents = [[NSArray alloc] init];
    parsedBook.totalWordCount = wordCount;
    
    if (completion) {
        completion(parsedBook, nil);
    }
}

- (void)parseEpubAtPath:(NSString *)filePath
         withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    NSError *error = nil;
    XLParsedBook *parsedBook = [XLEpubParser parseEpubAtPath:filePath error:&error];
    if (completion) completion(parsedBook, error);
}

- (void)parsePdfAtPath:(NSString *)filePath
        withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    NSError *error = nil;
    XLParsedBook *parsedBook = [XLNativeParsers parsePdfAtPath:filePath error:&error];
    if (completion) completion(parsedBook, error);
}

- (void)parseFb2AtPath:(NSString *)filePath
        withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    NSError *error = nil;
    XLParsedBook *parsedBook = [XLNativeParsers parseFb2AtPath:filePath error:&error];
    if (completion) completion(parsedBook, error);
}

- (void)parseMobiAtPath:(NSString *)filePath
        withCompletion:(void(^)(XLParsedBook * _Nullable parsedBook, NSError * _Nullable error))completion {
    NSError *error = nil;
    XLParsedBook *parsedBook = [XLNativeParsers parseMobiAtPath:filePath error:&error];
    if (completion) completion(parsedBook, error);
}

@end
