//
//  XLNativeParsers.h
//  Xenolexia
//
//  Thin Obj-C wrappers for native XLPDFReader, XLFB2Reader, XLMobiReader. Returns nil if parse fails or lib unavailable.
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
