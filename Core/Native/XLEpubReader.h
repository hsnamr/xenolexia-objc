//
//  XLEpubReader.h
//  Xenolexia
//
//  EPUB reader using libzip + libxml2 (FOSS). Replaces xenolexia-shared-c xenolexia_epub.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLEpubReader : NSObject

/// Open EPUB at path. Returns nil on failure.
+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error;

/// Metadata
- (NSString *)title;
- (nullable NSString *)identifier;
- (nullable NSString *)language;
- (nullable NSString *)metaValueForName:(NSString *)name;

/// Spine (reading order)
- (NSInteger)spineCount;
- (nullable NSString *)spinePathAtIndex:(NSInteger)index;

/// Table of contents (flat). Returns NO if index out of range.
- (NSInteger)tocCount;
- (BOOL)tocAtIndex:(NSInteger)index getTitle:(NSString **)outTitle href:(NSString **)outHref level:(NSInteger *)outLevel;

/// Read file bytes (e.g. spine path). Returns nil on failure.
- (nullable NSData *)readFileAtPath:(NSString *)path;

/// Cover image bytes. Returns nil if not found.
- (nullable NSData *)copyCover;

@end

NS_ASSUME_NONNULL_END
