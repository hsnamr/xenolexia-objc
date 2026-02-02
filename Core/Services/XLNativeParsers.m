//
//  XLNativeParsers.m
//  Xenolexia
//
//  Wraps xenolexia_pdf, xenolexia_fb2, xenolexia_mobi C APIs.
//

#import "XLNativeParsers.h"
#import "../Models/Book.h"
#import "xenolexia_pdf.h"
#import "xenolexia_fb2.h"
#import "xenolexia_mobi.h"

@implementation XLNativeParsers

+ (NSString *)stringFromCAndFree:(char *)cstr freeFn:(void (*)(void *))freeFn {
    if (!cstr) return nil;
    NSString *s = [NSString stringWithUTF8String:cstr];
    if (freeFn) freeFn(cstr);
    return s;
}

#pragma mark - PDF

+ (XLParsedBook *)parsePdfAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:1 userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        return nil;
    }
    xenolexia_pdf_error_t err = XENOLEXIA_PDF_OK;
    xenolexia_pdf_t *pdf = xenolexia_pdf_open([path UTF8String], &err);
    if (!pdf) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:(NSInteger)err userInfo:@{NSLocalizedDescriptionKey: @"Failed to open PDF"}];
        return nil;
    }
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [self stringFromCAndFree:xenolexia_pdf_copy_title(pdf) freeFn:xenolexia_pdf_free] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [self stringFromCAndFree:xenolexia_pdf_copy_author(pdf) freeFn:xenolexia_pdf_free];
    NSMutableArray *chapters = [NSMutableArray array];
    int32_t pageCount = xenolexia_pdf_page_count(pdf);
    NSInteger totalWords = 0;
    for (int32_t i = 0; i < pageCount; i++) {
        char *text = xenolexia_pdf_copy_page_text(pdf, i);
        NSString *content = [self stringFromCAndFree:text freeFn:xenolexia_pdf_free] ?: @"";
        NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSInteger wc = [words count];
        totalWords += wc;
        XLChapter *ch = [[XLChapter alloc] init];
        ch.chapterId = [[NSUUID UUID] UUIDString];
        ch.title = [NSString stringWithFormat:@"Page %d", (int)(i + 1)];
        ch.index = (NSInteger)i;
        ch.content = content;
        ch.wordCount = wc;
        [chapters addObject:ch];
        [ch release];
    }
    xenolexia_pdf_close(pdf);
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
    xenolexia_fb2_error_t err = XENOLEXIA_FB2_OK;
    xenolexia_fb2_t *fb2 = xenolexia_fb2_open([path UTF8String], &err);
    if (!fb2) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:(NSInteger)err userInfo:@{NSLocalizedDescriptionKey: @"Failed to open FB2"}];
        return nil;
    }
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [self stringFromCAndFree:xenolexia_fb2_copy_title(fb2) freeFn:xenolexia_fb2_free] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [self stringFromCAndFree:xenolexia_fb2_copy_author(fb2) freeFn:xenolexia_fb2_free];
    NSMutableArray *chapters = [NSMutableArray array];
    int32_t sectionCount = xenolexia_fb2_section_count(fb2);
    NSInteger totalWords = 0;
    for (int32_t i = 0; i < sectionCount; i++) {
        NSString *title = [self stringFromCAndFree:xenolexia_fb2_copy_section_title(fb2, i) freeFn:xenolexia_fb2_free] ?: [NSString stringWithFormat:@"Section %d", (int)(i + 1)];
        NSString *content = [self stringFromCAndFree:xenolexia_fb2_copy_section_text(fb2, i) freeFn:xenolexia_fb2_free] ?: @"";
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
    xenolexia_fb2_close(fb2);
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
    xenolexia_mobi_error_t err = XENOLEXIA_MOBI_OK;
    xenolexia_mobi_t *mobi = xenolexia_mobi_open([path UTF8String], &err);
    if (!mobi) {
        if (error) *error = [NSError errorWithDomain:@"XLNativeParsers" code:(NSInteger)err userInfo:@{NSLocalizedDescriptionKey: @"Failed to open MOBI"}];
        return nil;
    }
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [self stringFromCAndFree:xenolexia_mobi_copy_title(mobi) freeFn:xenolexia_mobi_free] ?: [[path lastPathComponent] stringByDeletingPathExtension];
    metadata.author = [self stringFromCAndFree:xenolexia_mobi_copy_author(mobi) freeFn:xenolexia_mobi_free];
    NSMutableArray *chapters = [NSMutableArray array];
    NSInteger totalWords = 0;
    int32_t partCount = xenolexia_mobi_part_count(mobi);
    if (partCount > 0) {
        for (int32_t i = 0; i < partCount; i++) {
            char *part = xenolexia_mobi_copy_part(mobi, i);
            NSString *content = [self stringFromCAndFree:part freeFn:xenolexia_mobi_free] ?: @"";
            NSArray *words = [content componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
            NSInteger wc = [words count];
            totalWords += wc;
            XLChapter *ch = [[XLChapter alloc] init];
            ch.chapterId = [[NSUUID UUID] UUIDString];
            ch.title = [NSString stringWithFormat:@"Part %d", (int)(i + 1)];
            ch.index = (NSInteger)i;
            ch.content = content;
            ch.wordCount = wc;
            [chapters addObject:ch];
            [ch release];
        }
    }
    else {
        char *full = xenolexia_mobi_copy_full_text(mobi);
        NSString *content = [self stringFromCAndFree:full freeFn:xenolexia_mobi_free] ?: @"";
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
    xenolexia_mobi_close(mobi);
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
