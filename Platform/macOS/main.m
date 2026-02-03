//
//  main.m
//  Xenolexia (macOS)
//
//  macOS (AppKit) entry point. Uses same desktop app delegate as Linux via SmallStep SSHostApplication.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "../Linux/UI/XLLinuxApp.h"

int main(int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    XLLinuxApp *app = [XLLinuxApp sharedApp];
    [app run];

    [pool drain];
    return 0;
}
