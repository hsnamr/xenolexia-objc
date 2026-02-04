//
//  XLNativeParsers.m
//  Xenolexia
//
//  Thin Obj-C wrappers for native XLPDFReader, XLFB2Reader, XLMobiReader.
//  Replaces xenolexia-shared-c PDF, FB2, MOBI. Returns nil if native lib unavailable or parse fails.
//

#import "XLNativeParsers.h"
#import "../Models/Book.h"
#import "../Native/XLPDFReader.h"
#import "../Native/XLFB2Reader.h"
#import "../Native/XLMobiReader.h"

@implementation XLNativeParsers

#pragma mark - PDF

+ (XLParsedBook *)parsePdfAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:1 userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        return nil;
    }
    XLPDFReader *pdf = [XLPDFReader openAtPath:path error:error];
    if (!pdf) return nil;
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [pdf title] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [pdf author];
    NSMutableArray *chapters = [NSMutableArray array];
    NSInteger totalWords = 0;
    NSInteger pageCount = [pdf pageCount];
    for (NSInteger i = 0; i < pageCount; i++) {
        NSString *content = [pdf pageTextAtIndex:i] ?: @"";
        NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSInteger wc = [words count];
        totalWords += wc;
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = [NSString stringWithFormat:@"Page %ld", (long)(i + 1)];
        ch.index = (NSInteger)i;
        ch.content = content;
        ch.wordCount = wc;
        [chapters addObject:ch];
        [ch release];
    }
    if ([chapters count] == 0) {
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = @"Content";
        ch.index = 0;
        ch.content = @"";
        ch.wordCount = 0;
        [chapters addObject:ch];
        [ch release];
    }
    XLParsedBook *book = [[XLParsedBook alloc] init];
    book.metadata = metadata;
    book.chapters = chapters;
    book.tableOfContents = [NSArray array];
    book.totalWordCount = totalWords;
    return [book autorelease];
}

#pragma mark - FB2

+ (XLParsedBook *)parseFb2AtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:1 userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        return nil;
    }
    XLFB2Reader *fb2 = [XLFB2Reader openAtPath:path error:error];
    if (!fb2) return nil;
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [fb2 title] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [fb2 author];
    NSMutableArray *chapters = [NSMutableArray array];
    NSInteger totalWords = 0;
    NSInteger sectionCount = [fb2 sectionCount];
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSString *title = [fb2 sectionTitleAtIndex:i] ?: [NSString stringWithFormat:@"Section %ld", (long)(i + 1)];
        NSString *content = [fb2 sectionTextAtIndex:i] ?: @"";
        NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSInteger wc = [words count];
        totalWords += wc;
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = title;
        ch.index = (NSInteger)i;
        ch.content = content;
        ch.wordCount = wc;
        [chapters addObject:ch];
        [ch release];
    }
    if ([chapters count] == 0) {
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = @"Content";
        ch.index = 0;
        ch.content = @"";
        ch.wordCount = 0;
        [chapters addObject:ch];
        [ch release];
    }
    XLParsedBook *book = [[XLParsedBook alloc] init];
    book.metadata = metadata;
    book.chapters = chapters;
    book.tableOfContents = [NSArray array];
    book.totalWordCount = totalWords;
    return [book autorelease];
}

#pragma mark - MOBI

+ (XLParsedBook *)parseMobiAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:1 userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        return nil;
    }
    XLMobiReader *mobi = [XLMobiReader openAtPath:path error:error];
    if (!mobi) return nil;
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [mobi title] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [mobi author];
    NSMutableArray *chapters = [NSMutableArray array];
    NSInteger totalWords = 0;
    NSInteger partCount = [mobi partCount];
    if (partCount > 0) {
        for (NSInteger i = 0; i < partCount; i++) {
            NSString *content = [mobi partAtIndex:i] ?: @"";
            NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
            NSInteger wc = [words count];
            totalWords += wc;
            XLChapter *ch = [[XLChapter alloc] init];
            ch.chapterId = [[NSUUID UUID] UUIDString];
            ch.title = [NSString stringWithFormat:@"Part %ld", (long)(i + 1)];
            ch.index = (NSInteger)i;
            ch.content = content;
            ch.wordCount = wc;
            [chapters addObject:ch];
            [ch release];
        }
    } else {
        NSString *content = [mobi fullText] ?: @"";
        NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        totalWords = [words count];
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = @"Content";
        ch.index = 0;
        ch.content = content;
        ch.wordCount = totalWords;
        [chapters addObject:ch];
        [ch release];
    }
    if ([chapters count] == 0) {
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = @"Content";
        ch.index = 0;
        ch.content = @"";
        ch.wordCount = 0;
        [chapters addObject:ch];
        [ch release];
    }
    XLParsedBook *book = [[XLParsedBook alloc] init];
    book.metadata = metadata;
    book.chapters = chapters;
    book.tableOfContents = [NSArray array];
    book.totalWordCount = totalWords;
    return [book autorelease];
}

@end
