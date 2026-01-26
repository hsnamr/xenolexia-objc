//
//  XLLinuxApp.h
//  Xenolexia
//
//  Linux (GNUStep) application entry point

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLLinuxApp : NSObject <NSApplicationDelegate>

+ (instancetype)sharedApp;

- (void)run;

@end

NS_ASSUME_NONNULL_END
