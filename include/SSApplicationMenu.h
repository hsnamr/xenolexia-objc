//
//  SSApplicationMenu.h
//  SmallStep
//
//  Cross-platform application menu abstraction
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol SSApplicationMenuDelegate;

/// Cross-platform application menu abstraction
/// On macOS: Uses the global menu bar (NSApp mainMenu)
/// On GNUstep/Linux: Uses the main menu (NSApp setMainMenu)
@interface SSApplicationMenu : NSObject {
    id<SSApplicationMenuDelegate> delegate;
    NSMenu *mainMenu;
    NSMenu *fileMenu;
    NSMenu *decodeMenu;
    NSMenu *encodeMenu;
    NSMenu *symbologiesMenu;
    NSMenu *distortionMenu;
    NSMenu *testingMenu;
    NSMenu *libraryMenu;
}

/// Delegate for menu actions
@property (assign, nonatomic) id<SSApplicationMenuDelegate> delegate;

/// Initialize with delegate
- (instancetype)initWithDelegate:(id<SSApplicationMenuDelegate>)delegate;

/// Build and install the menu
- (void)buildMenu;

/// Update menu item states (enabled/disabled)
- (void)updateMenuStates;

/// Populate symbologies menu (call after encoder is available)
- (void)populateSymbologiesMenu;

/// Update symbology checkmarks (call when selection changes)
- (void)updateSymbologyCheckmarks;

/// Show the menu (on platforms that use floating panels)
- (void)showMenu;

/// Hide the menu (on platforms that use floating panels)
- (void)hideMenu;

/// Toggle menu visibility (on platforms that use floating panels)
- (void)toggleMenu;

@end

/// Protocol for menu action callbacks
@protocol SSApplicationMenuDelegate <NSObject>
@optional

// File menu actions
- (void)menuOpenImage:(id)sender;
- (void)menuSaveImage:(id)sender;

// Decode menu actions
- (void)menuDecodeImage:(id)sender;

// Encode menu actions
- (void)menuEncodeBarcode:(id)sender;

// Symbologies menu actions
- (void)menuSelectSymbology:(id)sender;

// Symbology queries
- (NSArray *)getSupportedSymbologies;
- (int)getCurrentSymbology;

// Distortion menu actions
- (void)menuApplyDistortion:(id)sender;
- (void)menuPreviewDistortion:(id)sender;
- (void)menuClearDistortion:(id)sender;

// Testing menu actions
- (void)menuTestDecodability:(id)sender;
- (void)menuRunProgressiveTest:(id)sender;
- (void)menuExportTestResults:(id)sender;

// Library menu actions
- (void)menuLoadLibrary:(id)sender;

// State queries for menu items
- (BOOL)isSaveImageEnabled;
- (BOOL)isDecodeImageEnabled;
- (BOOL)isEncodeBarcodeEnabled;
- (BOOL)isApplyDistortionEnabled;
- (BOOL)isPreviewDistortionEnabled;
- (BOOL)isClearDistortionEnabled;
- (BOOL)isTestDecodabilityEnabled;
- (BOOL)isRunProgressiveTestEnabled;
- (BOOL)isExportTestResultsEnabled;

@end

NS_ASSUME_NONNULL_END
