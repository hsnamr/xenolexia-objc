//
//  XLSettingsWindowController.h
//  Xenolexia
//
//  Settings window (Phase 4): preferences form, Save, Reset to defaults

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Models/Language.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLSettingsWindowDelegate <NSObject>
- (void)settingsWindowDidClose;
@end

@interface XLSettingsWindowController : NSWindowController <XLStorageServiceDelegate> {
    XLStorageService *_storageService;
    XLUserPreferences *_prefs;
    NSPopUpButton *_sourceLangPopUp;
    NSPopUpButton *_targetLangPopUp;
    NSPopUpButton *_proficiencyPopUp;
    NSSlider *_wordDensitySlider;
    NSTextField *_wordDensityLabel;
    NSPopUpButton *_themePopUp;
    NSTextField *_fontFamilyField;
    NSTextField *_fontSizeField;
    NSTextField *_lineHeightField;
    NSTextField *_marginHField;
    NSTextField *_marginVField;
    NSTextField *_dailyGoalField;
    NSButton *_notificationsCheckBox;
    NSButton *_saveButton;
    NSButton *_resetButton;
}

@property (nonatomic, assign) id<XLSettingsWindowDelegate> delegate;

- (void)loadPreferences;

@end
