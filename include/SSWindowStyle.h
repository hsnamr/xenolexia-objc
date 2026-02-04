//
//  SSWindowStyle.h
//  SmallStep
//
//  Cross-platform window style abstraction
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Cross-platform window style mask
/// Provides platform-agnostic window style constants
@interface SSWindowStyle : NSObject

/// Standard window style: titled, closable, miniaturizable, resizable
+ (NSUInteger)standardWindowMask;

/// Titled window mask
+ (NSUInteger)titledWindowMask;

/// Closable window mask
+ (NSUInteger)closableWindowMask;

/// Miniaturizable window mask
+ (NSUInteger)miniaturizableWindowMask;

/// Resizable window mask
+ (NSUInteger)resizableWindowMask;

@end

NS_ASSUME_NONNULL_END
