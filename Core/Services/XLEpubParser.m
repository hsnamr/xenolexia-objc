//
//  XLEpubParser.m
//  Xenolexia
//
//  EPUB parser using xenolexia-shared-c (EPUB3Processor).

#import "XLEpubParser.h"
#import <string.h>
#import "../Models/Book.h"

// Shared C EPUB API (EPUB3Processor wrapper)
#import "xenolexia_epub.h"

@implementation XLEpubParser

+ (XLParsedBook *)parseEpubAtPath:(NSString *)filePath error:(NSError **)error {
    if (!filePath || [filePath length] == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        }
        return nil;
    }

    xenolexia_epub_error_t err = XENOLEXIA_EPUB_OK;
    xenolexia_epub_t *epub = xenolexia_epub_open([filePath UTF8String], &err);
    if (!epub) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Failed to open EPUB: error %d", (int)err];
            *error = [NSError errorWithDomain:@"XLEpubParser" code:(NSInteger)err
                                        userInfo:@{NSLocalizedDescriptionKey: msg}];
        }
        return nil;
    }

    // Metadata
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    char *title = xenolexia_epub_copy_title(epub);
    metadata.title = title ? [NSString stringWithUTF8String:title] : @"Unknown";
    free(title);
    char *author = xenolexia_epub_copy_meta(epub, "creator");
    metadata.author = author ? [NSString stringWithUTF8String:author] : nil;
    free(author);
    char *lang = xenolexia_epub_copy_language(epub);
    metadata.language = lang ? [NSString stringWithUTF8String:lang] : nil;
    free(lang);

    // Chapters from spine
    NSMutableArray *chapters = [NSMutableArray array];
    int32_t spineCount = xenolexia_epub_spine_count(epub);
    NSInteger totalWordCount = 0;

    for (int32_t i = 0; i < spineCount; i++) {
        char *path = xenolexia_epub_copy_spine_path(epub, i);
        if (!path) continue;
        void *bytes = NULL;
        uint32_t size = 0;
        int r = xenolexia_epub_read_file(epub, path, &bytes, &size);
        if (r != 0 || !bytes || size == 0) {
            free(path);
            continue;
        }

        NSData *data = [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:YES];
        NSString *chapterContent = [self stringFromChapterData:data];
        if (!chapterContent || [chapterContent length] == 0) {
            free(path);
            continue;
        }

        XLChapter *chapter = [[XLChapter alloc] init];
        chapter.chapterId = [[NSUUID UUID] UUIDString];
        chapter.title = [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
        chapter.index = (NSInteger)i;
        chapter.content = chapterContent;
        chapter.href = [NSString stringWithUTF8String:path];
        free(path);

        NSArray *words = [chapterContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length > 0"];
        words = [words filteredArrayUsingPredicate:predicate];
        chapter.wordCount = [words count];
        totalWordCount += chapter.wordCount;

        [chapters addObject:chapter];
        [chapter release];
    }

    // TOC
    NSMutableArray *toc = [NSMutableArray array];
    int32_t tocCount = xenolexia_epub_toc_count(epub);
    for (int32_t t = 0; t < tocCount; t++) {
        char *tTitle = NULL, *tHref = NULL;
        int32_t tLevel = 0;
        if (xenolexia_epub_toc_at(epub, t, &tTitle, &tHref, &tLevel) != 0) continue;
        XLTOCItem *item = [[XLTOCItem alloc] init];
        item.itemId = [[NSUUID UUID] UUIDString];
        item.title = tTitle ? [NSString stringWithUTF8String:tTitle] : @"";
        item.href = tHref ? [NSString stringWithUTF8String:tHref] : @"";
        item.level = (NSInteger)tLevel;
        [toc addObject:item];
        [item release];
        free(tTitle);
        free(tHref);
    }

    xenolexia_epub_close(epub);

    // Phase 7.1: Use TOC titles for chapters when spine href matches TOC href
    [self applyTocTitlesToChapters:chapters toc:toc];

    XLParsedBook *parsedBook = [[XLParsedBook alloc] init];
    parsedBook.metadata = metadata;
    parsedBook.chapters = chapters;
    parsedBook.tableOfContents = toc;
    parsedBook.totalWordCount = totalWordCount;
    return [parsedBook autorelease];
}

+ (NSData *)extractFile:(NSString *)filePath fromEpub:(NSString *)epubPath error:(NSError **)error {
    xenolexia_epub_error_t err = XENOLEXIA_EPUB_OK;
    xenolexia_epub_t *epub = xenolexia_epub_open([epubPath UTF8String], &err);
    if (!epub) {
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:(NSInteger)err
                                        userInfo:@{NSLocalizedDescriptionKey: @"Failed to open EPUB"}];
        }
        return nil;
    }
    void *bytes = NULL;
    uint32_t size = 0;
    int r = xenolexia_epub_read_file(epub, [filePath UTF8String], &bytes, &size);
    xenolexia_epub_close(epub);
    if (r != 0 || !bytes) {
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:1004
                                        userInfo:@{NSLocalizedDescriptionKey: @"File not found in EPUB"}];
        }
        return nil;
    }
    NSData *data = [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:YES];
    return data;
}

+ (NSString *)getOpfPathFromContainer:(NSData *)containerData error:(NSError **)error {
    (void)containerData;
    if (error) *error = [NSError errorWithDomain:@"XLEpubParser" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Use xenolexia_epub API; container not used"}];
    return nil;
}

+ (NSDictionary *)parseOpfFile:(NSData *)opfData basePath:(NSString *)basePath error:(NSError **)error {
    (void)opfData;
    (void)basePath;
    if (error) *error = [NSError errorWithDomain:@"XLEpubParser" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Use xenolexia_epub API; OPF not used"}];
    return nil;
}

+ (NSString *)parseChapterContent:(NSData *)chapterData error:(NSError **)error {
    return [self stringFromChapterData:chapterData];
}

/** Normalize href for comparison (strip fragment, leading ./). */
+ (NSString *)normalizeHref:(NSString *)href {
    if (!href || [href length] == 0) return @"";
    NSString *s = href;
    if ([s hasPrefix:@"./"]) s = [s substringFromIndex:2];
    NSRange frag = [s rangeOfString:@"#"];
    if (frag.location != NSNotFound) s = [s substringToIndex:frag.location];
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

/** Apply TOC titles to chapters when spine href matches TOC href (Phase 7.1). */
+ (void)applyTocTitlesToChapters:(NSMutableArray *)chapters toc:(NSArray *)toc {
    if (!chapters || !toc || [toc count] == 0) return;
    for (XLChapter *chapter in chapters) {
        NSString *chapterNorm = [self normalizeHref:chapter.href];
        if ([chapterNorm length] == 0) continue;
        for (XLTOCItem *item in toc) {
            NSString *tocNorm = [self normalizeHref:item.href];
            if ([tocNorm length] > 0 && ([chapterNorm isEqualToString:tocNorm] ||
                [chapterNorm hasSuffix:tocNorm] || [tocNorm hasSuffix:chapterNorm])) {
                if ([item.title length] > 0) {
                    chapter.title = item.title;
                }
                break;
            }
        }
    }
}

/** Extract readable text/HTML from chapter bytes (UTF-8). */
+ (NSString *)stringFromChapterData:(NSData *)data {
    if (!data || [data length] == 0) return nil;
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!s) s = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    return [s autorelease];
}

@end
