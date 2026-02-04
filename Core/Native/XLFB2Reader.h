//
//  XLFB2Reader.h
//  Xenolexia
//
//  FictionBook 2 (FB2) reader using libxml2. Replaces xenolexia-shared-c xenolexia_fb2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLFB2Reader : NSObject

+ (nullable instancetype)openAtPath:(NSString *)path error:(NSError **)error;

- (NSString *)title;
- (nullable NSString *)author;
- (NSInteger)sectionCount;
- (nullable NSString *)sectionTitleAtIndex:(NSInteger)index;
- (nullable NSString *)sectionTextAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
