//
//  XLPDFReader.h
//  Xenolexia
//
//  PDF reader using MuPDF (FOSS). Replaces xenolexia-shared-c xenolexia_pdf.
//  When MuPDF is not linked, openAtPath: returns nil.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLPDFReader : NSObject

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error;

- (nullable NSString *)title;
- (nullable NSString *)author;
- (NSInteger)pageCount;
- (nullable NSString *)pageTextAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
