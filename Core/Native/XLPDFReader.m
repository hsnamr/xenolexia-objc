//
//  XLPDFReader.m
//  Xenolexia
//
//  PDF reader using MuPDF. Build with -DXENOLEXIA_USE_MUPDF and link -lmupdf when available.
//

#import "XLPDFReader.h"

#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
#import <mupdf/fitz.h>
#endif

@interface XLPDFReader ()
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
@property (nonatomic, assign) fz_context *ctx;
@property (nonatomic, assign) fz_document *doc;
#endif
@end

@implementation XLPDFReader

- (void)dealloc {
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    if (_doc) fz_drop_document(_ctx, _doc);
    if (_ctx) fz_drop_context(_ctx);
#endif
    [super dealloc];
}

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLPDFReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Path is empty"}];
        return nil;
    }
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    fz_context *ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx) {
        if (error) *error = [NSError errorWithDomain:@"XLPDFReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"MuPDF context"}];
        return nil;
    }
    fz_document *doc = NULL;
    fz_try(ctx) {
        doc = fz_open_document(ctx, [path UTF8String]);
    }
    fz_catch(ctx) {
        fz_drop_context(ctx);
        if (error) *error = [NSError errorWithDomain:@"XLPDFReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Failed to open PDF"}];
        return nil;
    }
    XLPDFReader *reader = [[[XLPDFReader alloc] init] autorelease];
    reader.ctx = ctx;
    reader.doc = doc;
    if (error) *error = nil;
    return reader;
#else
    (void)path;
    if (error) *error = [NSError errorWithDomain:@"XLPDFReader" code:1099 userInfo:@{NSLocalizedDescriptionKey: @"PDF support not built (link MuPDF with XENOLEXIA_USE_MUPDF)"}];
    return nil;
#endif
}

- (NSString *)title {
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    if (!_ctx || !_doc) return nil;
    char buf[2048];
    if (fz_lookup_metadata(_ctx, _doc, "info:Title", buf, sizeof(buf)) <= 0) return nil;
    return [NSString stringWithUTF8String:buf];
#else
    return nil;
#endif
}

- (NSString *)author {
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    if (!_ctx || !_doc) return nil;
    char buf[2048];
    if (fz_lookup_metadata(_ctx, _doc, "info:Author", buf, sizeof(buf)) <= 0) return nil;
    return [NSString stringWithUTF8String:buf];
#else
    return nil;
#endif
}

- (NSInteger)pageCount {
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    if (!_ctx || !_doc) return 0;
    return (NSInteger)fz_count_pages(_ctx, _doc);
#else
    return 0;
#endif
}

- (NSString *)pageTextAtIndex:(NSInteger)index {
#if defined(XENOLEXIA_USE_MUPDF) && XENOLEXIA_USE_MUPDF
    if (!_ctx || !_doc || index < 0) return nil;
    int np = (int)fz_count_pages(_ctx, _doc);
    if (index >= np) return nil;
    fz_page *page = NULL;
    fz_stext_page *stext = NULL;
    fz_buffer *buf = NULL;
    NSString *out = nil;
    fz_try(_ctx) {
        page = fz_load_page(_ctx, _doc, (int)index);
        stext = fz_new_stext_page_from_page(_ctx, page, NULL);
        buf = fz_new_buffer(_ctx, 256);
        fz_print_stext_page_as_text(_ctx, stext, buf);
        out = [NSString stringWithUTF8String:fz_string_from_buffer(_ctx, buf)];
    }
    fz_always(_ctx) {
        if (buf) fz_drop_buffer(_ctx, buf);
        if (stext) fz_drop_stext_page(_ctx, stext);
        if (page) fz_drop_page(_ctx, page);
    }
    fz_catch(_ctx) { out = nil; }
    return out;
#else
    (void)index;
    return nil;
#endif
}

@end
