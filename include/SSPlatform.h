//
//  SSPlatform.h
//  SmallStep
//
//  Platform detection and abstraction layer

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Supported platforms
typedef NS_ENUM(NSInteger, SSPlatformType) {
    SSPlatformTypeUnknown = 0,
    SSPlatformTypemacOS,
    SSPlatformTypeiOS,
    SSPlatformTypeLinux,
    SSPlatformTypeWindows
};

/// Platform information
@interface SSPlatform : NSObject

/// Current platform type
+ (SSPlatformType)currentPlatform;

/// Check if running on macOS
+ (BOOL)isMacOS;

/// Check if running on iOS
+ (BOOL)isiOS;

/// Check if running on Linux (GNUStep)
+ (BOOL)isLinux;

/// Check if running on Windows (WinObjC)
+ (BOOL)isWindows;

/// Platform name string
+ (NSString *)platformName;

/// Platform version string
+ (NSString *)platformVersion;

@end

NS_ASSUME_NONNULL_END
