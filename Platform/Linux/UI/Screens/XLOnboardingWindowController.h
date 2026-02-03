//
//  XLOnboardingWindowController.h
//  Xenolexia
//
//  Onboarding window (Phase 5): welcome, language/proficiency/density, Get started / Skip

#import <AppKit/AppKit.h>
#import "../../../Core/Models/Reader.h"
#import "../../../Core/Models/Language.h"
#import "../../../Core/Services/XLStorageServiceDelegate.h"

@class XLStorageService;

@protocol XLOnboardingWindowDelegate <NSObject>
- (void)onboardingDidComplete;
@end

@interface XLOnboardingWindowController : NSWindowController <XLStorageServiceDelegate> {
    XLStorageService *_storageService;
    NSInteger _step;
    XLLanguage _stepSourceLanguage;
    XLLanguage _stepTargetLanguage;
    XLProficiencyLevel _stepProficiency;
    double _stepWordDensity;
    NSView *_stepContentView;
    NSTextField *_titleLabel;
    NSTextField *_subtitleLabel;
    NSPopUpButton *_sourceLangPopUp;
    NSPopUpButton *_targetLangPopUp;
    NSPopUpButton *_proficiencyPopUp;
    NSSlider *_wordDensitySlider;
    NSTextField *_wordDensityValueLabel;
    NSButton *_nextButton;
    NSButton *_skipButton;
    BOOL _didComplete;
}

@property (nonatomic, assign) id<XLOnboardingWindowDelegate> delegate;

- (void)showStep:(NSInteger)step;

@end
