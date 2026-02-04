//
//  XLEpubReader.m
//  Xenolexia
//
//  EPUB reader using libzip + libxml2. Replaces xenolexia-shared-c xenolexia_epub.
//

#import "XLEpubReader.h"
#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <zip.h>
#import <string.h>
#import <stdlib.h>

@interface XLEpubReader ()
@property (nonatomic, assign) zip_t *zip;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSString *rootDir;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSArray<NSString *> *spinePaths;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *tocEntries; // title, href, level
@property (nonatomic, assign) xmlDoc *opfDoc;
@property (nonatomic, assign) xmlXPathContext *opfXpath;
@end

static NSString *resolvePath(NSString *basePath, NSString *path) {
    NSString *base = [basePath stringByDeletingLastPathComponent];
    if ([path length] > 0 && [path characterAtIndex:0] == '/')
        path = [path substringFromIndex:1];
    if ([base length] == 0) return path;
    return [base stringByAppendingPathComponent:path];
}

static NSData *readZipEntry(zip_t *z, const char *path) {
    if (!z || !path) return nil;
    zip_file_t *f = zip_fopen(z, path, 0);
    if (!f) return nil;
    NSMutableData *out = [NSMutableData data];
    char buf[4096];
    zip_int64_t n;
    while ((n = zip_fread(f, buf, sizeof(buf))) > 0)
        [out appendBytes:buf length:(size_t)n];
    zip_fclose(f);
    return out;
}

@implementation XLEpubReader

- (void)dealloc {
    if (_opfXpath) xmlXPathFreeContext(_opfXpath);
    if (_opfDoc) xmlFreeDoc(_opfDoc);
    if (_zip) zip_close(_zip);
    [super dealloc];
}

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Path is empty"}];
        return nil;
    }
    int err = 0;
    zip_t *z = zip_open([path UTF8String], 0, &err);
    if (!z) {
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Failed to open EPUB (ZIP)"}];
        return nil;
    }

    NSData *containerData = readZipEntry(z, "META-INF/container.xml");
    if (!containerData || [containerData length] == 0) {
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Missing container.xml"}];
        return nil;
    }

    xmlDoc *containerDoc = xmlReadMemory((const char *)[containerData bytes], (int)[containerData length], NULL, NULL, XML_PARSE_RECOVER | XML_PARSE_NOERROR);
    if (!containerDoc) {
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Invalid container.xml"}];
        return nil;
    }

    xmlNode *root = xmlDocGetRootElement(containerDoc);
    xmlNode *rootfiles = NULL;
    for (xmlNode *n = root ? root->children : NULL; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE && xmlStrEqual(n->name, (const xmlChar *)"rootfiles")) {
            rootfiles = n;
            break;
        }
    }
    xmlNode *rootfile = NULL;
    for (xmlNode *n = rootfiles ? rootfiles->children : NULL; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE && xmlStrEqual(n->name, (const xmlChar *)"rootfile")) {
            rootfile = n;
            break;
        }
    }
    xmlChar *fullPath = rootfile ? xmlGetProp(rootfile, (const xmlChar *)"full-path") : NULL;
    NSString *rootPath = fullPath ? [NSString stringWithUTF8String:(const char *)fullPath] : nil;
    if (fullPath) xmlFree(fullPath);
    xmlFreeDoc(containerDoc);

    if (!rootPath || [rootPath length] == 0) {
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"No rootfile in container"}];
        return nil;
    }

    NSData *opfData = readZipEntry(z, [rootPath UTF8String]);
    if (!opfData || [opfData length] == 0) {
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Missing OPF"}];
        return nil;
    }

    xmlDoc *opfDoc = xmlReadMemory((const char *)[opfData bytes], (int)[opfData length], NULL, NULL, XML_PARSE_RECOVER | XML_PARSE_NOERROR);
    if (!opfDoc) {
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"Invalid OPF"}];
        return nil;
    }

    xmlXPathContext *opfXpath = xmlXPathNewContext(opfDoc);
    if (!opfXpath) {
        xmlFreeDoc(opfDoc);
        zip_close(z);
        if (error) *error = [NSError errorWithDomain:@"XLEpubReader" code:1099 userInfo:@{NSLocalizedDescriptionKey: @"XPath context"}];
        return nil;
    }

    XLEpubReader *reader = [[[XLEpubReader alloc] init] autorelease];
    reader.zip = z;
    reader.rootPath = rootPath;
    reader.rootDir = [rootPath stringByDeletingLastPathComponent];
    reader.opfDoc = opfDoc;
    reader.opfXpath = opfXpath;

    xmlNode *opfRoot = xmlDocGetRootElement(opfDoc);
    NSString *title = @"";
    NSString *identifier = @"";
    NSString *language = @"";
    NSMutableDictionary *manifest = [NSMutableDictionary dictionary];
    NSMutableArray *spinePaths = [NSMutableArray array];

    for (xmlNode *n = opfRoot ? opfRoot->children : NULL; n; n = n->next) {
        if (n->type != XML_ELEMENT_NODE) continue;
        if (xmlStrEqual(n->name, (const xmlChar *)"metadata")) {
            for (xmlNode *m = n->children; m; m = m->next) {
                if (m->type != XML_ELEMENT_NODE) continue;
                const char *name = (const char *)m->name;
                xmlNode *content = m->children;
                while (content && content->type != XML_TEXT_NODE) content = content->next;
                NSString *val = content && content->content ? [NSString stringWithUTF8String:(const char *)content->content] : @"";
                if (strcmp(name, "title") == 0) title = val;
                else if (strcmp(name, "identifier") == 0) identifier = val;
                else if (strcmp(name, "language") == 0) language = val;
            }
        } else if (xmlStrEqual(n->name, (const xmlChar *)"manifest")) {
            for (xmlNode *item = n->children; item; item = item->next) {
                if (item->type != XML_ELEMENT_NODE || !xmlStrEqual(item->name, (const xmlChar *)"item")) continue;
                xmlChar *id_ = xmlGetProp(item, (const xmlChar *)"id");
                xmlChar *href = xmlGetProp(item, (const xmlChar *)"href");
                if (id_ && href)
                    [manifest setObject:[NSString stringWithUTF8String:(const char *)href] forKey:[NSString stringWithUTF8String:(const char *)id_]];
                if (id_) xmlFree(id_);
                if (href) xmlFree(href);
            }
        } else if (xmlStrEqual(n->name, (const xmlChar *)"spine")) {
            for (xmlNode *ref = n->children; ref; ref = ref->next) {
                if (ref->type != XML_ELEMENT_NODE || !xmlStrEqual(ref->name, (const xmlChar *)"itemref")) continue;
                xmlChar *idref = xmlGetProp(ref, (const xmlChar *)"idref");
                if (idref) {
                    NSString *href = [manifest objectForKey:[NSString stringWithUTF8String:(const char *)idref]];
                    if (href) [spinePaths addObject:resolvePath(rootPath, href)];
                    xmlFree(idref);
                }
            }
        }
    }

    reader.title = title;
    reader.identifier = identifier;
    reader.language = language;
    reader.spinePaths = spinePaths;
    reader.tocEntries = [NSArray array]; /* TOC from NCX can be added later */

    if (error) *error = nil;
    return reader;
}

- (NSString *)title { return _title ?: @""; }
- (NSString *)identifier { return _identifier ?: @""; }
- (NSString *)language { return _language ?: @""; }

- (NSString *)metaValueForName:(NSString *)name {
    if (!name || !_opfDoc) return nil;
    xmlNode *meta = xmlDocGetRootElement(_opfDoc);
    if (!meta) return nil;
    for (xmlNode *n = meta->children; n; n = n->next) {
        if (n->type != XML_ELEMENT_NODE || !xmlStrEqual(n->name, (const xmlChar *)"metadata")) continue;
        for (xmlNode *m = n->children; m; m = m->next) {
            if (m->type == XML_ELEMENT_NODE && [name isEqualToString:[NSString stringWithUTF8String:(const char *)m->name]]) {
                xmlNode *c = m->children;
                while (c && c->type != XML_TEXT_NODE) c = c->next;
                return c && c->content ? [NSString stringWithUTF8String:(const char *)c->content] : nil;
            }
        }
        break;
    }
    return nil;
}

- (NSInteger)spineCount { return [_spinePaths count]; }
- (NSString *)spinePathAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[_spinePaths count]) return nil;
    return [_spinePaths objectAtIndex:index];
}

- (NSInteger)tocCount { return [_tocEntries count]; }
- (BOOL)tocAtIndex:(NSInteger)index getTitle:(NSString **)outTitle href:(NSString **)outHref level:(NSInteger *)outLevel {
    if (!outTitle || !outHref || !outLevel || index < 0 || index >= (NSInteger)[_tocEntries count]) return NO;
    NSDictionary *e = [_tocEntries objectAtIndex:index];
    *outTitle = [e objectForKey:@"title"] ?: @"";
    *outHref = [e objectForKey:@"href"] ?: @"";
    *outLevel = [[e objectForKey:@"level"] integerValue];
    return YES;
}

- (NSData *)readFileAtPath:(NSString *)path {
    if (!path) return nil;
    return readZipEntry(_zip, [path UTF8String]);
}

- (NSData *)copyCover {
    if (!_opfDoc) return nil;
    xmlNode *meta = xmlDocGetRootElement(_opfDoc);
    NSString *coverId = nil;
    for (xmlNode *n = meta ? meta->children : NULL; n; n = n->next) {
        if (n->type != XML_ELEMENT_NODE || !xmlStrEqual(n->name, (const xmlChar *)"metadata")) continue;
        for (xmlNode *m = n->children; m; m = m->next) {
            if (m->type == XML_ELEMENT_NODE && xmlStrEqual(m->name, (const xmlChar *)"meta")) {
                xmlChar *nm = xmlGetProp(m, (const xmlChar *)"name");
                if (nm && strcmp((const char *)nm, "cover") == 0) {
                    xmlChar *content = xmlGetProp(m, (const xmlChar *)"content");
                    if (content) coverId = [NSString stringWithUTF8String:(const char *)content];
                    if (content) xmlFree(content);
                }
                if (nm) xmlFree(nm);
                if (coverId) break;
            }
        }
        break;
    }
    if (!coverId) return nil;
    xmlNode *manifest = NULL;
    for (xmlNode *n = meta->children; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE && xmlStrEqual(n->name, (const xmlChar *)"manifest")) { manifest = n; break; }
    }
    for (xmlNode *item = manifest ? manifest->children : NULL; item; item = item->next) {
        if (item->type != XML_ELEMENT_NODE || !xmlStrEqual(item->name, (const xmlChar *)"item")) continue;
        xmlChar *id_ = xmlGetProp(item, (const xmlChar *)"id");
        if (id_ && [coverId isEqualToString:[NSString stringWithUTF8String:(const char *)id_]]) {
            xmlChar *href = xmlGetProp(item, (const xmlChar *)"href");
            NSString *path = href ? resolvePath(_rootPath, [NSString stringWithUTF8String:(const char *)href]) : nil;
            if (href) xmlFree(href);
            if (id_) xmlFree(id_);
            return path ? [self readFileAtPath:path] : nil;
        }
        if (id_) xmlFree(id_);
    }
    return nil;
}

@end
