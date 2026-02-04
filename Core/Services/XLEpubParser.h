//
//  XLEpubParser.h
//  Xenolexia
//
//  EPUB parser using native XLEpubReader (libzip + libxml2).

#import <Foundation/Foundation.h>
#import "../Models/Book.h"

/// EPUB parser using native XLEpubReader (libzip + libxml2).
@interface XLEpubParser : NSObject

/// Parse EPUB file and return parsed book structure
+ (XLParsedBook *)parseEpubAtPath:(NSString *)filePath error:(NSError **)error;

/// Extract a file from EPUB ZIP archive
+ (NSData *)extractFile:(NSString *)filePath fromEpub:(NSString *)epubPath error:(NSError **)error;

/// Get OPF file path from container.xml
+ (NSString *)getOpfPathFromContainer:(NSData *)containerData error:(NSError **)error;

/// Parse OPF file to extract metadata and manifest
+ (NSDictionary *)parseOpfFile:(NSData *)opfData basePath:(NSString *)basePath error:(NSError **)error;

/// Parse HTML/XHTML chapter content
+ (NSString *)parseChapterContent:(NSData *)chapterData error:(NSError **)error;

@end
