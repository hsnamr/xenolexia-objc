//
//  XLOnboardingWindowController.m
//  Xenolexia
//
//  Onboarding implementation (Phase 5): steps Welcome, Source, Target, Proficiency, Word density, Get started

#import "XLOnboardingWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"

enum {
    kStepWelcome = 0,
    kStepSource,
    kStepTarget,
    kStepProficiency,
    kStepWordDensity,
    kStepGetStarted,
    kStepCount
};

@interface XLOnboardingWindowController ()
- (void)buildUI;
- (void)showStepContent;
- (void)nextClicked:(id)sender;
- (void)skipClicked:(id)sender;
- (void)densityChanged:(id)sender;
- (XLUserPreferences *)currentPreferences;
@end

@implementation XLOnboardingWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _storageService = [XLStorageService sharedService];
        _step = 0;
        _stepSourceLanguage = XLLanguageEnglish;
        _stepTargetLanguage = XLLanguageSpanish;
        _stepProficiency = XLProficiencyLevelBeginner;
        _stepWordDensity = 0.3;
        _didComplete = NO;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setTitle:@"Welcome to Xenolexia"];
    [self.window setContentSize:NSMakeSize(500, 380)];
    [self.window setStyleMask:[self.window styleMask] & ~NSResizableWindowMask];
    [self buildUI];
    [self showStepContent];
}

- (void)buildUI {
    NSView *contentView = [self.window contentView];
    _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 320, 420, 32)];
    [_titleLabel setEditable:NO];
    [_titleLabel setBordered:NO];
    [_titleLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_titleLabel setFont:[NSFont boldSystemFontOfSize:20]];
    [_titleLabel setAlignment:NSCenterTextAlignment];
    [contentView addSubview:_titleLabel];

    _subtitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(40, 260, 420, 50)];
    [_subtitleLabel setEditable:NO];
    [_subtitleLabel setBordered:NO];
    [_subtitleLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_subtitleLabel setFont:[NSFont systemFontOfSize:14]];
    [_subtitleLabel setAlignment:NSCenterTextAlignment];
    [_subtitleLabel setSelectable:YES];
    [contentView addSubview:_subtitleLabel];

    _stepContentView = [[NSView alloc] initWithFrame:NSMakeRect(40, 120, 420, 130)];
    [contentView addSubview:_stepContentView];

    _sourceLangPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 80, 420, 28)];
    _targetLangPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 80, 420, 28)];
    _proficiencyPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 80, 420, 28)];
    [_proficiencyPopUp addItemWithTitle:@"Beginner"];
    [_proficiencyPopUp addItemWithTitle:@"Intermediate"];
    [_proficiencyPopUp addItemWithTitle:@"Advanced"];
    _wordDensitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0, 80, 300, 24)];
    [_wordDensitySlider setMinValue:0.1];
    [_wordDensitySlider setMaxValue:0.5];
    [_wordDensitySlider setDoubleValue:0.3];
    [_wordDensitySlider setTarget:self];
    [_wordDensitySlider setAction:@selector(densityChanged:)];
    _wordDensityValueLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(310, 78, 80, 24)];
    [_wordDensityValueLabel setEditable:NO];
    [_wordDensityValueLabel setBordered:NO];
    [_wordDensityValueLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_stepContentView addSubview:_sourceLangPopUp];
    [_stepContentView addSubview:_targetLangPopUp];
    [_stepContentView addSubview:_proficiencyPopUp];
    [_stepContentView addSubview:_wordDensitySlider];
    [_stepContentView addSubview:_wordDensityValueLabel];

    _nextButton = [[NSButton alloc] initWithFrame:NSMakeRect(280, 30, 120, 32)];
    [_nextButton setTitle:@"Next"];
    [_nextButton setTarget:self];
    [_nextButton setAction:@selector(nextClicked:)];
    [contentView addSubview:_nextButton];

    _skipButton = [[NSButton alloc] initWithFrame:NSMakeRect(50, 30, 140, 32)];
    [_skipButton setTitle:@"I'll do this later"];
    [_skipButton setTarget:self];
    [_skipButton setAction:@selector(skipClicked:)];
    [contentView addSubview:_skipButton];
}

- (void)showStep:(NSInteger)step {
    _step = step;
    [self showStepContent];
}

- (void)showStepContent {
    [_sourceLangPopUp setHidden:YES];
    [_targetLangPopUp setHidden:YES];
    [_proficiencyPopUp setHidden:YES];
    [_wordDensitySlider setHidden:YES];
    [_wordDensityValueLabel setHidden:YES];

    switch (_step) {
        case kStepWelcome:
            [_titleLabel setStringValue:@"Welcome to Xenolexia"];
            [_subtitleLabel setStringValue:@"Xenolexia helps you read in a foreign language.\nChoose your languages and preferences to get started."];
            [_nextButton setTitle:@"Next"];
            [_nextButton setHidden:NO];
            break;
        case kStepSource: {
            [_titleLabel setStringValue:@"Source language"];
            [_subtitleLabel setStringValue:@"The language you're learning (the language of the text)."];
            [_sourceLangPopUp setHidden:NO];
            [_sourceLangPopUp removeAllItems];
            NSArray *langs = [XLLanguageInfo supportedLanguages];
            for (XLLanguageInfo *info in langs) {
                [_sourceLangPopUp addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", info.name, info.nativeName]];
            }
            NSInteger idx = 0;
            for (NSUInteger i = 0; i < [langs count]; i++) {
                if ([(XLLanguageInfo *)[langs objectAtIndex:i] code] == _stepSourceLanguage) { idx = i; break; }
            }
            [_sourceLangPopUp selectItemAtIndex:idx];
            [_nextButton setTitle:@"Next"];
            [_nextButton setHidden:NO];
            break;
        }
        case kStepTarget: {
            [_titleLabel setStringValue:@"Target language"];
            [_subtitleLabel setStringValue:@"Your native language (for translations)."];
            [_targetLangPopUp setHidden:NO];
            [_targetLangPopUp removeAllItems];
            NSArray *langs = [XLLanguageInfo supportedLanguages];
            for (XLLanguageInfo *info in langs) {
                [_targetLangPopUp addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", info.name, info.nativeName]];
            }
            NSInteger idx = 0;
            for (NSUInteger i = 0; i < [langs count]; i++) {
                if ([(XLLanguageInfo *)[langs objectAtIndex:i] code] == _stepTargetLanguage) { idx = i; break; }
            }
            [_targetLangPopUp selectItemAtIndex:idx];
            [_nextButton setTitle:@"Next"];
            [_nextButton setHidden:NO];
            break;
        }
        case kStepProficiency:
            [_titleLabel setStringValue:@"Proficiency level"];
            [_subtitleLabel setStringValue:@"How well do you know the source language?"];
            [_proficiencyPopUp setHidden:NO];
            [_proficiencyPopUp selectItemAtIndex:_stepProficiency];
            [_nextButton setTitle:@"Next"];
            [_nextButton setHidden:NO];
            break;
        case kStepWordDensity:
            [_titleLabel setStringValue:@"Word density"];
            [_subtitleLabel setStringValue:@"How many words to highlight (0.1 = fewer, 0.5 = more)."];
            [_wordDensitySlider setHidden:NO];
            [_wordDensitySlider setDoubleValue:_stepWordDensity];
            [_wordDensityValueLabel setHidden:NO];
            [_wordDensityValueLabel setStringValue:[NSString stringWithFormat:@"%.2f", _stepWordDensity]];
            [_nextButton setTitle:@"Next"];
            [_nextButton setHidden:NO];
            break;
        case kStepGetStarted:
            [_titleLabel setStringValue:@"You're all set"];
            [_subtitleLabel setStringValue:@"Import a book and start reading. You can change these settings anytime."];
            [_nextButton setTitle:@"Get started"];
            [_nextButton setHidden:NO];
            break;
        default:
            break;
    }
}

- (void)densityChanged:(id)sender {
    _stepWordDensity = [_wordDensitySlider doubleValue];
    [_wordDensityValueLabel setStringValue:[NSString stringWithFormat:@"%.2f", _stepWordDensity]];
}

- (void)nextClicked:(id)sender {
    if (_step == kStepSource) {
        NSArray *langs = [XLLanguageInfo supportedLanguages];
        NSInteger idx = [_sourceLangPopUp indexOfSelectedItem];
        if (idx >= 0 && idx < (NSInteger)[langs count])
            _stepSourceLanguage = [(XLLanguageInfo *)[langs objectAtIndex:idx] code];
    } else if (_step == kStepTarget) {
        NSArray *langs = [XLLanguageInfo supportedLanguages];
        NSInteger idx = [_targetLangPopUp indexOfSelectedItem];
        if (idx >= 0 && idx < (NSInteger)[langs count])
            _stepTargetLanguage = [(XLLanguageInfo *)[langs objectAtIndex:idx] code];
    } else if (_step == kStepProficiency) {
        _stepProficiency = (XLProficiencyLevel)[_proficiencyPopUp indexOfSelectedItem];
    } else if (_step == kStepWordDensity) {
        _stepWordDensity = [_wordDensitySlider doubleValue];
    } else if (_step == kStepGetStarted) {
        XLUserPreferences *prefs = [self currentPreferences];
        prefs.hasCompletedOnboarding = YES;
        [_storageService savePreferences:prefs delegate:self];
        _didComplete = YES;
        [self.window close];
        if (_delegate && [_delegate respondsToSelector:@selector(onboardingDidComplete)]) {
            [_delegate onboardingDidComplete];
        }
        return;
    }
    _step++;
    if (_step >= kStepCount) _step = kStepGetStarted;
    [self showStepContent];
}

- (void)skipClicked:(id)sender {
    XLUserPreferences *prefs = [XLUserPreferences defaultPreferences];
    prefs.hasCompletedOnboarding = YES;
    [_storageService savePreferences:prefs delegate:self];
    _didComplete = YES;
    [self.window close];
    if (_delegate && [_delegate respondsToSelector:@selector(onboardingDidComplete)]) {
        [_delegate onboardingDidComplete];
    }
}

- (XLUserPreferences *)currentPreferences {
    XLUserPreferences *prefs = [[XLUserPreferences alloc] init];
    prefs.defaultSourceLanguage = _stepSourceLanguage;
    prefs.defaultTargetLanguage = _stepTargetLanguage;
    prefs.defaultProficiencyLevel = _stepProficiency;
    prefs.defaultWordDensity = _stepWordDensity;
    prefs.readerSettings = [XLReaderSettings defaultSettings];
    prefs.hasCompletedOnboarding = NO;
    prefs.notificationsEnabled = NO;
    prefs.dailyGoal = 30;
    return [prefs autorelease];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didSavePreferencesWithSuccess:(BOOL)success error:(NSError *)error {
    (void)service;
    (void)success;
    (void)error;
}

- (void)windowWillClose:(NSNotification *)notification {
    if (!_didComplete && _delegate && [_delegate respondsToSelector:@selector(onboardingDidComplete)]) {
        [_delegate onboardingDidComplete];
    }
}

@end
