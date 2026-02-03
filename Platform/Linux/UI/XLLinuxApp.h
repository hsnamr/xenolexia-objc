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
#import "Screens/XLVocabularyWindowController.h"
#import "Screens/XLReviewWindowController.h"
#import "Screens/XLSettingsWindowController.h"
#import "Screens/XLOnboardingWindowController.h"
#import "Screens/XLStatisticsWindowController.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"
#import "../../../Core/Models/Reader.h"
#import "../../../SmallStep/SmallStep/Core/SSAppDelegate.h"

@interface XLLinuxApp : NSObject <SSAppDelegate, NSApplicationDelegate, XLLibraryWindowDelegate, XLBookDetailWindowDelegate, XLReaderWindowDelegate, XLVocabularyWindowDelegate, XLReviewWindowDelegate, XLSettingsWindowDelegate, XLOnboardingWindowDelegate, XLStatisticsWindowDelegate, XLStorageServiceDelegate> {
    XLLibraryWindowController *_libraryController;
    XLBookDetailWindowController *_bookDetailController;
    XLReaderWindowController *_readerController;
    XLVocabularyWindowController *_vocabularyController;
    XLReviewWindowController *_reviewController;
    XLSettingsWindowController *_settingsController;
    XLOnboardingWindowController *_onboardingController;
    XLStatisticsWindowController *_statisticsController;
    id _statusItem; // NSStatusItem if system tray is supported (Phase 7.3)
}

+ (instancetype)sharedApp;

- (void)run;

@end
