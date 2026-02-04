//
//  XLMobiReader.h
//  Xenolexia
//
//  MOBI/Kindle reader using libmobi (FOSS). Replaces xenolexia-shared-c xenolexia_mobi.
//  When libmobi is not linked, openAtPath: returns nil.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLMobiReader : NSObject

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error;

- (nullable NSString *)title;
- (nullable NSString *)author;
- (NSInteger)partCount;
- (nullable NSString *)fullText;
- (nullable NSString *)partAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
