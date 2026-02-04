//
//  XLFB2Reader.m
//  Xenolexia
//
//  FB2 reader using libxml2. Replaces xenolexia-shared-c xenolexia_fb2.
//

#import "XLFB2Reader.h"
#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface XLFB2Reader ()
@property (nonatomic, assign) xmlDoc *doc;
@property (nonatomic, assign) xmlXPathContext *xpathCtx;
@property (nonatomic, assign) xmlXPathObject *sectionsXPathObj; /* kept so sections nodeset stays valid */
@property (nonatomic, assign) xmlNodeSet *sections;
@property (nonatomic) NSInteger sectionCount;
@end

static NSString *copyTextContent(xmlNode *node) {
    xmlChar *x = xmlNodeGetContent(node);
    if (!x) return nil;
    NSString *out = [NSString stringWithUTF8String:(const char *)x];
    xmlFree(x);
    return out;
}

static void collectText(xmlNode *node, NSMutableString *buf) {
    for (xmlNode *cur = node; cur; cur = cur->next) {
        if (cur->type == XML_TEXT_NODE && cur->content)
            [buf appendString:[NSString stringWithUTF8String:(const char *)cur->content]];
        else if (cur->type == XML_ELEMENT_NODE) {
            if (xmlStrEqual(cur->name, (const xmlChar *)"p") || xmlStrEqual(cur->name, (const xmlChar *)"empty-line")) {
                collectText(cur->children, buf);
                if (xmlStrEqual(cur->name, (const xmlChar *)"p")) [buf appendString:@"\n"];
            } else
                collectText(cur->children, buf);
        }
    }
}

static NSString *getSectionTitle(xmlNode *section) {
    for (xmlNode *n = section->children; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE && xmlStrEqual(n->name, (const xmlChar *)"title")) {
            xmlNode *p = n->children;
            while (p && p->type != XML_ELEMENT_NODE) p = p->next;
            if (p && xmlStrEqual(p->name, (const xmlChar *)"p"))
                return copyTextContent(p);
            return copyTextContent(n);
        }
    }
    return nil;
}

static NSString *getSectionText(xmlNode *section) {
    NSMutableString *buf = [NSMutableString string];
    for (xmlNode *n = section->children; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE && (xmlStrEqual(n->name, (const xmlChar *)"p") || xmlStrEqual(n->name, (const xmlChar *)"title")))
            collectText(n->children, buf);
    }
    return [buf length] ? [NSString stringWithString:buf] : nil;
}

@implementation XLFB2Reader

- (void)dealloc {
    if (_sectionsXPathObj) xmlXPathFreeObject(_sectionsXPathObj);
    if (_xpathCtx) xmlXPathFreeContext(_xpathCtx);
    if (_doc) xmlFreeDoc(_doc);
    [super dealloc];
}

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error {
    if (!path || [path length] == 0) {
        if (error) *error = [NSError errorWithDomain:@"XLFB2Reader" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"Path is empty"}];
        return nil;
    }
    xmlDoc *doc = xmlReadFile([path UTF8String], NULL, XML_PARSE_RECOVER | XML_PARSE_NOERROR);
    if (!doc) {
        if (error) *error = [NSError errorWithDomain:@"XLFB2Reader" code:1008 userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse FB2"}];
        return nil;
    }
    xmlXPathContext *ctx = xmlXPathNewContext(doc);
    if (!ctx) {
        xmlFreeDoc(doc);
        if (error) *error = [NSError errorWithDomain:@"XLFB2Reader" code:1099 userInfo:nil];
        return nil;
    }
    xmlXPathObject *bodyObj = xmlXPathEvalExpression((const xmlChar *)"//*[local-name()='body']/*[local-name()='section']", ctx);
    xmlNodeSet *sections = (bodyObj && bodyObj->nodesetval) ? bodyObj->nodesetval : NULL;
    int sectionCount = sections ? sections->nodeNr : 0;
    if (bodyObj && !sections) xmlXPathFreeObject(bodyObj);

    XLFB2Reader *reader = [[[XLFB2Reader alloc] init] autorelease];
    reader.doc = doc;
    reader.xpathCtx = ctx;
    reader.sectionsXPathObj = sections ? bodyObj : NULL;
    reader.sections = sections;
    reader.sectionCount = sectionCount;
    if (error) *error = nil;
    return reader;
}

- (NSString *)title {
    if (!_doc || !_xpathCtx) return @"";
    xmlXPathObject *obj = xmlXPathEvalExpression((const xmlChar *)"//*[local-name()='title-info']/*[local-name()='book-title']", _xpathCtx);
    NSString *out = nil;
    if (obj && obj->nodesetval && obj->nodesetval->nodeNr > 0)
        out = copyTextContent(obj->nodesetval->nodeTab[0]);
    if (obj) xmlXPathFreeObject(obj);
    return out ?: @"";
}

- (NSString *)author {
    if (!_doc || !_xpathCtx) return nil;
    xmlXPathObject *obj = xmlXPathEvalExpression((const xmlChar *)"//*[local-name()='title-info']/*[local-name()='author']", _xpathCtx);
    if (!obj || !obj->nodesetval || obj->nodesetval->nodeNr == 0) {
        if (obj) xmlXPathFreeObject(obj);
        return nil;
    }
    xmlNode *author = obj->nodesetval->nodeTab[0];
    xmlXPathFreeObject(obj);
    NSString *first = nil, *last = nil;
    for (xmlNode *n = author->children; n; n = n->next) {
        if (n->type == XML_ELEMENT_NODE) {
            if (xmlStrEqual(n->name, (const xmlChar *)"first-name")) first = copyTextContent(n);
            else if (xmlStrEqual(n->name, (const xmlChar *)"last-name")) last = copyTextContent(n);
        }
    }
    if (first && last) return [NSString stringWithFormat:@"%@ %@", first, last];
    return first ?: last;
}

- (NSInteger)sectionCount { return _sectionCount; }
- (NSString *)sectionTitleAtIndex:(NSInteger)index {
    if (!_sections || index < 0 || index >= _sectionCount) return nil;
    return getSectionTitle(_sections->nodeTab[index]);
}
- (NSString *)sectionTextAtIndex:(NSInteger)index {
    if (!_sections || index < 0 || index >= _sectionCount) return nil;
    return getSectionText(_sections->nodeTab[index]);
}

@end
