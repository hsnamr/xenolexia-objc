//
//  XLLinuxApp.h
//  Xenolexia
//
//  Linux (GNUStep) application entry point

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Screens/XLLibraryWindowController.h"
#import "Screens/XLBookDetailWindowController.h"
#import "Screens/XLReaderWindowController.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@interface XLLinuxApp : NSObject <NSApplicationDelegate, XLLibraryWindowDelegate, XLBookDetailWindowDelegate, XLReaderWindowDelegate, XLStorageServiceDelegate> {
    XLLibraryWindowController *_libraryController;
    XLBookDetailWindowController *_bookDetailController;
    XLReaderWindowController *_readerController;
}

+ (instancetype)sharedApp;

- (void)run;

@end
