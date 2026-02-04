//
//  XLMobiReader.m
//  Xenolexia
//
//  MOBI/Kindle reader using libmobi (FOSS). Replaces xenolexia-shared-c xenolexia_mobi.
//  When libmobi is not linked (XENOLEXIA_USE_LIBMOBI not defined), openAtPath: returns nil.
//

#import "XLMobiReader.h"
#import <string.h>

#if defined(XENOLEXIA_USE_LIBMOBI) && XENOLEXIA_USE_LIBMOBI
#import <mobi.h>

@interface XLMobiReader ()
@property (nonatomic, assign) MOBIData *mobi;
@property (nonatomic, assign) MOBIRawml *rawml;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *bookAuthor;
@property (nonatomic, assign) NSInteger partCount;
@property (nonatomic, assign) MOBIPart **parts; /* cached array; freed in dealloc */
@end

static NSInteger countFlowParts(MOBIPart *flow) {
    NSInteger n = 0;
    while (flow) { n++; flow = flow->next; }
    return n;
}

@implementation XLMobiReader

- (void)dealloc {
    if (_parts) free(_parts);
    if (_rawml) mobi_free_rawml(_rawml);
    if (_mobi) mobi_free(_mobi);
    [_bookTitle release];
    [_bookAuthor release];
    [super dealloc];
}

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLMobiReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Path is empty"}];
        return nil;
    }
    MOBIData *m = mobi_init();
    if (!m) {
        if (error) *error = [NSError errorWithDomain:@"XLMobiReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"libmobi init failed"}];
        return nil;
    }
    MOBI_RET ret = mobi_load_filename(m, [path UTF8String]);
    if (ret != MOBI_SUCCESS) {
        mobi_free(m);
        if (error) *error = [NSError errorWithDomain:@"XLMobiReader" code:(ret == MOBI_ERROR_OPEN) ? 1003 : 1004
            userInfo:@{NSLocalizedDescriptionKey: (ret == MOBI_ERROR_OPEN) ? @"Failed to open file" : @"Failed to parse MOBI"}];
        return nil;
    }
    if (mobi_is_encrypted(m)) {
        mobi_free(m);
        if (error) *error = [NSError errorWithDomain:@"XLMobiReader" code:1005 userInfo:@{NSLocalizedDescriptionKey: @"MOBI is encrypted"}];
        return nil;
    }

    XLMobiReader *reader = [[[XLMobiReader alloc] init] autorelease];
    reader.mobi = m;
    reader.rawml = NULL;
    reader.partCount = 0;
    reader.parts = NULL;

    MOBIRawml *rawml = mobi_init_rawml(m);
    if (rawml && mobi_parse_rawml(rawml, m) == MOBI_SUCCESS && rawml->flow) {
        NSInteger n = countFlowParts(rawml->flow);
        if (n > 0) {
            reader.rawml = rawml;
            reader.partCount = n;
            reader.parts = (MOBIPart **)calloc((size_t)n, sizeof(MOBIPart *));
            if (reader.parts) {
                MOBIPart *p = rawml->flow;
                for (NSInteger i = 0; i < n && p; i++, p = p->next)
                    reader.parts[i] = p;
            } else {
                reader.partCount = 0;
                mobi_free_rawml(rawml);
                reader.rawml = NULL;
            }
        } else {
            mobi_free_rawml(rawml);
        }
    } else if (rawml) {
        mobi_free_rawml(rawml);
    }

    char *title = mobi_meta_get_title(m);
    reader.bookTitle = title ? [NSString stringWithUTF8String:title] : nil;
    char *author = mobi_meta_get_author(m);
    reader.bookAuthor = author ? [NSString stringWithUTF8String:author] : nil;

    return reader;
}

- (nullable NSString *)title { return _bookTitle; }
- (nullable NSString *)author { return _bookAuthor; }
- (NSInteger)partCount { return _partCount; }

- (nullable NSString *)fullText {
    if (!_mobi) return nil;
    size_t maxsize = mobi_get_text_maxsize(_mobi);
    if (maxsize == 0 || maxsize == MOBI_NOTSET) return nil;
    char *buf = (char *)malloc(maxsize + 1);
    if (!buf) return nil;
    size_t len = maxsize;
    MOBI_RET ret = mobi_get_rawml(_mobi, buf, &len);
    if (ret != MOBI_SUCCESS) {
        free(buf);
        return nil;
    }
    buf[len] = '\0';
    NSString *s = [NSString stringWithUTF8String:buf];
    free(buf);
    return s;
}

- (nullable NSString *)partAtIndex:(NSInteger)index {
    if (index < 0 || index >= _partCount || !_parts) return nil;
    MOBIPart *part = _parts[index];
    if (!part || !part->data) return nil;
    size_t sz = part->size;
    char *out = (char *)malloc(sz + 1);
    if (!out) return nil;
    memcpy(out, part->data, sz);
    out[sz] = '\0';
    NSString *s = [NSString stringWithUTF8String:out];
    free(out);
    return s;
}

@end

#else

@implementation XLMobiReader

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error {
    (void)path;
    if (error) *error = [NSError errorWithDomain:@"XLMobiReader" code:1099
        userInfo:@{NSLocalizedDescriptionKey: @"MOBI support not built (link libmobi with XENOLEXIA_USE_LIBMOBI=1)"}];
    return nil;
}

- (nullable NSString *)title { return nil; }
- (nullable NSString *)author { return nil; }
- (NSInteger)partCount { return 0; }
- (nullable NSString *)fullText { return nil; }
- (nullable NSString *)partAtIndex:(NSInteger)index { (void)index; return nil; }

@end

#endif
