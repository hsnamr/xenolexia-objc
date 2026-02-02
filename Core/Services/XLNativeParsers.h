//
//  XLNativeParsers.h
//  Xenolexia
//
//  Thin Obj-C wrappers for xenolexia-shared-c PDF, FB2, MOBI. Returns nil if native lib unavailable or parse fails.
//

#import <Foundation/Foundation.h>
@class XLParsedBook;

NS_ASSUME_NONNULL_BEGIN

@interface XLNativeParsers : NSObject

+ (nullable XLParsedBook *)parsePdfAtPath:(NSString *)path error:(NSError **)error;
+ (nullable XLParsedBook *)parseFb2AtPath:(NSString *)path error:(NSError **)error;
+ (nullable XLParsedBook *)parseMobiAtPath:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
