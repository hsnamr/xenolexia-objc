//
//  XLEpubParser.m
//  Xenolexia
//
//  EPUB parser using native XLEpubReader (libzip + libxml2). Replaces xenolexia-shared-c.
//  Chapter content: uses libxml2 (FOSS) for HTML→plain text when data looks like HTML.

#import "XLEpubParser.h"
#import "../Models/Book.h"
#import "XLEpubReader.h"
#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/HTMLparser.h>
#import <stdlib.h>
#import <string.h>

/** Recursively collect text from an xmlNode tree (libxml2). */
static void collectTextFromNode(xmlNode *node, NSMutableString *out) {
    if (!node) return;
    if (node->type == XML_TEXT_NODE && node->content) {
        char *trimmed = (char *)node->content;
        while (*trimmed == ' ' || *trimmed == '\t' || *trimmed == '\n' || *trimmed == '\r') trimmed++;
        size_t len = strlen(trimmed);
        while (len > 0 && (trimmed[len - 1] == ' ' || trimmed[len - 1] == '\t' || trimmed[len - 1] == '\n' || trimmed[len - 1] == '\r')) len--;
        if (len > 0) {
            NSString *s = [[NSString alloc] initWithBytes:trimmed length:len encoding:NSUTF8StringEncoding];
            if (s) {
                if ([out length] > 0) [out appendString:@" "];
                [out appendString:s];
                [s release];
            }
        }
    }
    for (xmlNode *cur = node->children; cur; cur = cur->next)
        collectTextFromNode(cur, out);
}

/** Extract plain text from HTML/XHTML bytes using libxml2 (FOSS). Returns nil on parse failure. */
static NSString *plainTextFromHTMLData(NSData *data) {
    if (!data || [data length] == 0) return nil;
    const char *bytes = (const char *)[data bytes];
    int len = (int)[data length];
    xmlDoc *doc = htmlReadMemory(bytes, len, NULL, NULL, XML_PARSE_RECOVER | XML_PARSE_NOERROR | XML_PARSE_NOWARNING);
    if (!doc) return nil;
    xmlNode *root = xmlDocGetRootElement(doc);
    NSMutableString *result = [NSMutableString string];
    if (root) collectTextFromNode(root, result);
    xmlFreeDoc(doc);
    return [result length] > 0 ? [[result copy] autorelease] : nil;
}

/** Heuristic: data looks like HTML if it contains '<' and '>' in the first 2KB. */
static BOOL dataLooksLikeHTML(NSData *data) {
    if (!data || [data length] < 4) return NO;
    const char *p = (const char *)[data bytes];
    size_t len = [data length];
    if (len > 2048) len = 2048;
    int hasLt = 0, hasGt = 0;
    for (size_t i = 0; i < len; i++) {
        if (p[i] == '<') hasLt = 1;
        if (p[i] == '>') hasGt = 1;
        if (hasLt && hasGt) return YES;
    }
    return NO;
}

@implementation XLEpubParser

+ (XLParsedBook *)parseEpubAtPath:(NSString *)filePath error:(NSError **)error {
    if (!filePath || [filePath length] == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"File path is empty"}];
        }
        return nil;
    }

    XLEpubReader *epub = [XLEpubReader openAtPath:filePath error:error];
    if (!epub) return nil;

    // Metadata
    XLBookMetadata *metadata = [[[XLBookMetadata alloc] init] autorelease];
    metadata.title = [epub title] ?: @"Unknown";
    metadata.author = [epub metaValueForName:@"creator"];
    metadata.language = [epub language];

    // Chapters from spine
    NSMutableArray *chapters = [NSMutableArray array];
    NSInteger spineCount = [epub spineCount];
    NSInteger totalWordCount = 0;

    for (NSInteger i = 0; i < spineCount; i++) {
        NSString *path = [epub spinePathAtIndex:i];
        if (!path) continue;
        NSData *data = [epub readFileAtPath:path];
        if (!data || [data length] == 0) continue;

        NSString *chapterContent = [self stringFromChapterData:data];
        if (!chapterContent || [chapterContent length] == 0) continue;

        XLChapter *chapter = [[XLChapter alloc] init];
        chapter.chapterId = [[NSUUID UUID] UUIDString];
        chapter.title = [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
        chapter.index = (NSInteger)i;
        chapter.content = chapterContent;
        chapter.href = path;

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
    NSInteger tocCount = [epub tocCount];
    for (NSInteger t = 0; t < tocCount; t++) {
        NSString *tTitle = nil, *tHref = nil;
        NSInteger tLevel = 0;
        if (![epub tocAtIndex:t getTitle:&tTitle href:&tHref level:&tLevel]) continue;
        XLTOCItem *item = [[XLTOCItem alloc] init];
        item.itemId = [[NSUUID UUID] UUIDString];
        item.title = tTitle ?: @"";
        item.href = tHref ?: @"";
        item.level = (NSInteger)tLevel;
        [toc addObject:item];
        [item release];
    }

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
    XLEpubReader *epub = [XLEpubReader openAtPath:epubPath error:error];
    if (!epub) return nil;
    NSData *data = [epub readFileAtPath:filePath];
    if (!data) {
        if (error) *error = [NSError errorWithDomain:@"XLEpubParser" code:1004
            userInfo:@{NSLocalizedDescriptionKey: @"File not found in EPUB"}];
        return nil;
    }
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

/** Extract readable text from chapter bytes. Uses libxml2 (FOSS) for HTML→text when content looks like HTML; otherwise UTF-8/ISO Latin-1 decode. */
+ (NSString *)stringFromChapterData:(NSData *)data {
    if (!data || [data length] == 0) return nil;
    if (dataLooksLikeHTML(data)) {
        NSString *plain = plainTextFromHTMLData(data);
        if (plain) return plain;
    }
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!s) s = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    return [s autorelease];
}

@end
