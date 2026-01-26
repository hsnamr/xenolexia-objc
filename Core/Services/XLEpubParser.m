//
//  XLEpubParser.m
//  Xenolexia
//
//  EPUB parser implementation using libzip and libxml2

#import "XLEpubParser.h"
#import <string.h>
#import <libzip/zip.h>
#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

// libzip error handling
static NSError *createZipError(int zipError, const char *message) {
    NSString *errorMsg = [NSString stringWithFormat:@"ZIP error: %s (code: %d)", message ? message : "Unknown", zipError];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"XLEpubParser" code:zipError userInfo:userInfo];
}

// libxml2 error handling
static NSError *createXmlError(const char *message) {
    NSString *errorMsg = [NSString stringWithFormat:@"XML error: %s", message ? message : "Unknown"];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"XLEpubParser" code:1000 userInfo:userInfo];
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
    
    // Open EPUB as ZIP archive
    int zipError = 0;
    struct zip *archive = zip_open([filePath UTF8String], ZIP_RDONLY, &zipError);
    if (!archive) {
        if (error) {
            *error = createZipError(zipError, "Failed to open EPUB file");
        }
        return nil;
    }
    
    @try {
        // Read container.xml
        NSData *containerData = [self extractFile:@"META-INF/container.xml" fromEpub:filePath error:error];
        if (!containerData) {
            zip_close(archive);
            return nil;
        }
        
        // Get OPF file path from container.xml
        NSString *opfPath = [self getOpfPathFromContainer:containerData error:error];
        if (!opfPath) {
            zip_close(archive);
            return nil;
        }
        
        // Extract OPF file
        NSData *opfData = [self extractFile:opfPath fromEpub:filePath error:error];
        if (!opfData) {
            zip_close(archive);
            return nil;
        }
        
        // Get base path (directory containing OPF file)
        NSString *basePath = [opfPath stringByDeletingLastPathComponent];
        if ([basePath length] == 0) {
            basePath = @"OEBPS"; // Default EPUB structure
        }
        
        // Parse OPF file
        NSDictionary *opfInfo = [self parseOpfFile:opfData basePath:basePath error:error];
        if (!opfInfo) {
            zip_close(archive);
            return nil;
        }
        
        // Extract metadata
        XLBookMetadata *metadata = [opfInfo objectForKey:@"metadata"];
        NSArray *manifestItems = [opfInfo objectForKey:@"manifest"];
        NSArray *spineItems = [opfInfo objectForKey:@"spine"];
        NSArray *tocItems = [opfInfo objectForKey:@"toc"];
        
        // Build chapters from spine
        NSMutableArray *chapters = [NSMutableArray array];
        NSInteger totalWordCount = 0;
        
        for (NSInteger i = 0; i < [spineItems count]; i++) {
            NSDictionary *spineItem = [spineItems objectAtIndex:i];
            NSString *itemId = [spineItem objectForKey:@"idref"];
            
            // Find manifest item
            NSDictionary *manifestItem = nil;
            for (NSDictionary *item in manifestItems) {
                if ([[item objectForKey:@"id"] isEqualToString:itemId]) {
                    manifestItem = item;
                    break;
                }
            }
            
            if (!manifestItem) {
                continue;
            }
            
            NSString *href = [manifestItem objectForKey:@"href"];
            NSString *mediaType = [manifestItem objectForKey:@"media-type"];
            
            // Only process HTML/XHTML files
            if (![mediaType hasPrefix:@"application/xhtml+xml"] && 
                ![mediaType hasPrefix:@"text/html"] &&
                ![href hasSuffix:@".html"] && 
                ![href hasSuffix:@".xhtml"] &&
                ![href hasSuffix:@".htm"]) {
                continue;
            }
            
            // Build full path (handle relative paths)
            NSString *fullPath = href;
            if ([basePath length] > 0) {
                // Remove leading slash if present
                if ([href hasPrefix:@"/"]) {
                    href = [href substringFromIndex:1];
                }
                // Handle relative paths with ..
                if ([href hasPrefix:@"../"]) {
                    // Resolve relative path
                    NSString *resolvedPath = basePath;
                    NSString *remaining = href;
                    while ([remaining hasPrefix:@"../"]) {
                        resolvedPath = [resolvedPath stringByDeletingLastPathComponent];
                        remaining = [remaining substringFromIndex:3];
                    }
                    fullPath = [resolvedPath stringByAppendingPathComponent:remaining];
                } else {
                    fullPath = [basePath stringByAppendingPathComponent:href];
                }
            }
            
            // Extract chapter content
            NSData *chapterData = [self extractFile:fullPath fromEpub:filePath error:NULL];
            if (!chapterData) {
                continue;
            }
            
            // Parse chapter content
            NSString *chapterContent = [self parseChapterContent:chapterData error:NULL];
            if (!chapterContent || [chapterContent length] == 0) {
                continue;
            }
            
            // Create chapter
            XLChapter *chapter = [[XLChapter alloc] init];
            chapter.chapterId = [[NSUUID UUID] UUIDString];
            chapter.title = [spineItem objectForKey:@"title"] ? [spineItem objectForKey:@"title"] : [NSString stringWithFormat:@"Chapter %ld", (long)(i + 1)];
            chapter.index = i;
            chapter.content = chapterContent;
            chapter.href = fullPath;
            
            // Count words (simple whitespace split)
            NSArray *words = [chapterContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length > 0"];
            words = [words filteredArrayUsingPredicate:predicate];
            chapter.wordCount = [words count];
            totalWordCount += chapter.wordCount;
            
            [chapters addObject:chapter];
            [chapter release];
        }
        
        // Build TOC
        NSMutableArray *toc = [NSMutableArray array];
        if (tocItems) {
            for (NSDictionary *tocItem in tocItems) {
                XLTOCItem *item = [[XLTOCItem alloc] init];
                item.itemId = [tocItem objectForKey:@"id"] ? [tocItem objectForKey:@"id"] : [[NSUUID UUID] UUIDString];
                item.title = [tocItem objectForKey:@"title"] ? [tocItem objectForKey:@"title"] : @"";
                item.href = [tocItem objectForKey:@"href"] ? [tocItem objectForKey:@"href"] : @"";
                NSNumber *levelNum = [tocItem objectForKey:@"level"];
                item.level = levelNum ? [levelNum integerValue] : 0;
                [toc addObject:item];
                [item release];
            }
        }
        
        // Create parsed book
        XLParsedBook *parsedBook = [[XLParsedBook alloc] init];
        parsedBook.metadata = metadata;
        parsedBook.chapters = chapters;
        parsedBook.tableOfContents = toc;
        parsedBook.totalWordCount = totalWordCount;
        
        zip_close(archive);
        return [parsedBook autorelease];
        
    } @catch (NSException *exception) {
        zip_close(archive);
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:999 
                                    userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
        }
        return nil;
    }
}

+ (NSData *)extractFile:(NSString *)filePath fromEpub:(NSString *)epubPath error:(NSError **)error {
    int zipError = 0;
    struct zip *archive = zip_open([epubPath UTF8String], ZIP_RDONLY, &zipError);
    if (!archive) {
        if (error) {
            *error = createZipError(zipError, "Failed to open EPUB file");
        }
        return nil;
    }
    
    // Find file in archive
    zip_int64_t index = zip_name_locate(archive, [filePath UTF8String], 0);
    if (index < 0) {
        zip_close(archive);
        if (error) {
            *error = createZipError((int)index, "File not found in EPUB");
        }
        return nil;
    }
    
    // Get file stats
    struct zip_stat stat;
    zip_stat_init(&stat);
    if (zip_stat_index(archive, index, 0, &stat) != 0) {
        zip_close(archive);
        if (error) {
            *error = createZipError(-1, "Failed to get file stats");
        }
        return nil;
    }
    
    // Read file data
    struct zip_file *file = zip_fopen_index(archive, index, 0);
    if (!file) {
        zip_close(archive);
        if (error) {
            *error = createZipError(-1, "Failed to open file in archive");
        }
        return nil;
    }
    
    NSMutableData *data = [NSMutableData dataWithLength:stat.size];
    zip_int64_t bytesRead = zip_fread(file, [data mutableBytes], stat.size);
    zip_fclose(file);
    zip_close(archive);
    
    if (bytesRead != stat.size) {
        if (error) {
            *error = createZipError(-1, "Failed to read complete file");
        }
        return nil;
    }
    
    return data;
}

+ (NSString *)getOpfPathFromContainer:(NSData *)containerData error:(NSError **)error {
    xmlDocPtr doc = xmlParseMemory([containerData bytes], (int)[containerData length]);
    if (!doc) {
        if (error) {
            *error = createXmlError("Failed to parse container.xml");
        }
        return nil;
    }
    
    @try {
        // Register namespaces
        xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
        if (!xpathCtx) {
            xmlFreeDoc(doc);
            if (error) {
                *error = createXmlError("Failed to create XPath context");
            }
            return nil;
        }
        
        // Find OPF file path: //container:rootfile[@media-type='application/oebps-package+xml']/@full-path
        // Try multiple XPath expressions for compatibility
        xmlXPathObjectPtr xpathObj = NULL;
        
        // Try with namespace-aware path first
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='rootfile']/@*[local-name()='full-path']", xpathCtx);
        
        // If that fails, try simpler path
        if (!xpathObj || xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            if (xpathObj) xmlXPathFreeObject(xpathObj);
            xpathObj = xmlXPathEvalExpression((xmlChar *)"//rootfile/@full-path", xpathCtx);
        }
        
        // If still fails, try to find any rootfile
        if (!xpathObj || xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            if (xpathObj) xmlXPathFreeObject(xpathObj);
            xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='rootfile']", xpathCtx);
            if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
                // Get full-path attribute manually
                xmlNodePtr rootfileNode = xpathObj->nodesetval->nodeTab[0];
                xmlChar *fullPathAttr = xmlGetProp(rootfileNode, (xmlChar *)"full-path");
                if (!fullPathAttr) {
                    fullPathAttr = xmlGetProp(rootfileNode, (xmlChar *)"full_path");
                }
                if (fullPathAttr) {
                    NSString *path = [NSString stringWithUTF8String:(const char *)fullPathAttr];
                    xmlFree(fullPathAttr);
                    xmlXPathFreeObject(xpathObj);
                    xmlXPathFreeContext(xpathCtx);
                    xmlFreeDoc(doc);
                    return path;
                }
            }
        }
        
        NSString *opfPath = nil;
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node) {
                // If it's an attribute node, get its value
                if (node->type == XML_ATTRIBUTE_NODE) {
                    xmlChar *value = xmlNodeListGetString(doc, node->children, 1);
                    if (value) {
                        opfPath = [NSString stringWithUTF8String:(const char *)value];
                        xmlFree(value);
                    }
                } else {
                    // If it's an element, get the attribute
                    xmlChar *fullPathAttr = xmlGetProp(node, (xmlChar *)"full-path");
                    if (!fullPathAttr) {
                        fullPathAttr = xmlGetProp(node, (xmlChar *)"full_path");
                    }
                    if (fullPathAttr) {
                        opfPath = [NSString stringWithUTF8String:(const char *)fullPathAttr];
                        xmlFree(fullPathAttr);
                    }
                }
            }
        }
        
        if (xpathObj) {
            xmlXPathFreeObject(xpathObj);
        }
        
        xmlXPathFreeObject(xpathObj);
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        
        if (!opfPath) {
            if (error) {
                *error = createXmlError("OPF file path not found in container.xml");
            }
            return nil;
        }
        
        return opfPath;
        
    } @catch (NSException *exception) {
        xmlFreeDoc(doc);
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:1001 
                                    userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
        }
        return nil;
    }
}

+ (NSDictionary *)parseOpfFile:(NSData *)opfData basePath:(NSString *)basePath error:(NSError **)error {
    xmlDocPtr doc = xmlParseMemory([opfData bytes], (int)[opfData length]);
    if (!doc) {
        if (error) {
            *error = createXmlError("Failed to parse OPF file");
        }
        return nil;
    }
    
    @try {
        xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
        if (!xpathCtx) {
            xmlFreeDoc(doc);
            if (error) {
                *error = createXmlError("Failed to create XPath context");
            }
            return nil;
        }
        
        // Parse metadata
        XLBookMetadata *metadata = [[XLBookMetadata alloc] init];
        
        // Title
        xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='title']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.title = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Author
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='creator']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.author = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Description
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='description']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.bookDescription = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Language
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='language']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.language = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Publisher
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='publisher']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.publisher = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Date
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='metadata']/*[local-name()='date']/text()", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr node = xpathObj->nodesetval->nodeTab[0];
            if (node && node->content) {
                metadata.publishDate = [NSString stringWithUTF8String:(const char *)node->content];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Parse manifest
        NSMutableArray *manifestItems = [NSMutableArray array];
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='manifest']/*[local-name()='item']", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            for (int i = 0; i < xpathObj->nodesetval->nodeNr; i++) {
                xmlNodePtr node = xpathObj->nodesetval->nodeTab[i];
                NSMutableDictionary *item = [NSMutableDictionary dictionary];
                
                // Get attributes
                xmlAttrPtr attr = node->properties;
                while (attr) {
                    NSString *attrName = [NSString stringWithUTF8String:(const char *)attr->name];
                    xmlChar *attrValue = xmlGetProp(node, attr->name);
                    if (attrValue) {
                        [item setObject:[NSString stringWithUTF8String:(const char *)attrValue] forKey:attrName];
                        xmlFree(attrValue);
                    }
                    attr = attr->next;
                }
                
                [manifestItems addObject:item];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Parse spine
        NSMutableArray *spineItems = [NSMutableArray array];
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='spine']/*[local-name()='itemref']", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            for (int i = 0; i < xpathObj->nodesetval->nodeNr; i++) {
                xmlNodePtr node = xpathObj->nodesetval->nodeTab[i];
                NSMutableDictionary *item = [NSMutableDictionary dictionary];
                
                // Get idref attribute
                xmlChar *idref = xmlGetProp(node, (xmlChar *)"idref");
                if (idref) {
                    [item setObject:[NSString stringWithUTF8String:(const char *)idref] forKey:@"idref"];
                    xmlFree(idref);
                }
                
                // Try to get title from manifest
                if ([item objectForKey:@"idref"]) {
                    NSString *itemId = [item objectForKey:@"idref"];
                    for (NSDictionary *manifestItem in manifestItems) {
                        if ([[manifestItem objectForKey:@"id"] isEqualToString:itemId]) {
                            NSString *href = [manifestItem objectForKey:@"href"];
                            // Use filename as title if available
                            if (href) {
                                NSString *title = [[href lastPathComponent] stringByDeletingPathExtension];
                                [item setObject:title forKey:@"title"];
                            }
                            break;
                        }
                    }
                }
                
                [spineItems addObject:item];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        // Parse TOC (nav.xhtml or toc.ncx)
        NSMutableArray *tocItems = [NSMutableArray array];
        // Try nav.xhtml first (EPUB 3)
        xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='nav'][@*[local-name()='type']='toc']//*[local-name()='a']", xpathCtx);
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            for (int i = 0; i < xpathObj->nodesetval->nodeNr; i++) {
                xmlNodePtr node = xpathObj->nodesetval->nodeTab[i];
                NSMutableDictionary *item = [NSMutableDictionary dictionary];
                
                // Get href
                xmlChar *href = xmlGetProp(node, (xmlChar *)"href");
                if (href) {
                    [item setObject:[NSString stringWithUTF8String:(const char *)href] forKey:@"href"];
                    xmlFree(href);
                }
                
                // Get text content
                xmlChar *content = xmlNodeGetContent(node);
                if (content) {
                    [item setObject:[NSString stringWithUTF8String:(const char *)content] forKey:@"title"];
                    xmlFree(content);
                }
                
                [item setObject:[NSNumber numberWithInt:0] forKey:@"level"];
                [tocItems addObject:item];
            }
        }
        xmlXPathFreeObject(xpathObj);
        
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                               metadata, @"metadata",
                               manifestItems, @"manifest",
                               spineItems, @"spine",
                               tocItems, @"toc",
                               nil];
        [metadata release];
        
        return result;
        
    } @catch (NSException *exception) {
        xmlFreeDoc(doc);
        if (error) {
            *error = [NSError errorWithDomain:@"XLEpubParser" code:1002 
                                    userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
        }
        return nil;
    }
}

+ (NSString *)parseChapterContent:(NSData *)chapterData error:(NSError **)error {
    xmlDocPtr doc = xmlParseMemory([chapterData bytes], (int)[chapterData length]);
    if (!doc) {
        // Try as plain text
        NSString *content = [[NSString alloc] initWithData:chapterData encoding:NSUTF8StringEncoding];
        return [content autorelease];
    }
    
    @try {
        // Get body content
        xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
        if (!xpathCtx) {
            xmlFreeDoc(doc);
            if (error) {
                *error = createXmlError("Failed to create XPath context");
            }
            return nil;
        }
        
        xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression((xmlChar *)"//*[local-name()='body']", xpathCtx);
        NSString *content = nil;
        
        if (xpathObj && !xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
            xmlNodePtr bodyNode = xpathObj->nodesetval->nodeTab[0];
            xmlChar *bodyContent = xmlNodeGetContent(bodyNode);
            if (bodyContent) {
                content = [NSString stringWithUTF8String:(const char *)bodyContent];
                xmlFree(bodyContent);
            } else {
                // Try to get inner HTML
                xmlBufferPtr buffer = xmlBufferCreate();
                xmlNodeDump(buffer, doc, bodyNode, 0, 1);
                if (buffer && buffer->content) {
                    content = [NSString stringWithUTF8String:(const char *)buffer->content];
                }
                xmlBufferFree(buffer);
            }
        }
        
        xmlXPathFreeObject(xpathObj);
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        
        if (!content) {
            // Fallback: return as plain text
            content = [[NSString alloc] initWithData:chapterData encoding:NSUTF8StringEncoding];
            return [content autorelease];
        }
        
        return content;
        
    } @catch (NSException *exception) {
        xmlFreeDoc(doc);
        // Fallback: return as plain text
        NSString *content = [[NSString alloc] initWithData:chapterData encoding:NSUTF8StringEncoding];
        return [content autorelease];
    }
}

@end
