//
//  SSConcurrency.h
//  SmallStep
//
//  Cross-platform concurrency abstraction
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Cross-platform concurrency utilities
@interface SSConcurrency : NSObject

/// Execute a selector on a background thread
/// @param selector The selector to execute
/// @param target The target object
/// @param object Optional object to pass to selector
+ (void)performSelectorInBackground:(SEL)selector onTarget:(id)target withObject:(id)object;

/// Execute a selector on the main thread
/// @param selector The selector to execute
/// @param target The target object
/// @param object Optional object to pass to selector
/// @param waitUntilDone Whether to wait for completion
+ (void)performSelectorOnMainThread:(SEL)selector onTarget:(id)target withObject:(id)object waitUntilDone:(BOOL)waitUntilDone;

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
/// Execute a block on a background thread (macOS only)
/// @param block The block to execute on background thread
+ (void)performInBackground:(void (^)(void))block;

/// Execute a block on the main thread (macOS only)
/// @param block The block to execute on main thread
/// @param waitUntilDone Whether to wait for completion
+ (void)performOnMainThread:(void (^)(void))block waitUntilDone:(BOOL)waitUntilDone;
#endif

@end

NS_ASSUME_NONNULL_END
