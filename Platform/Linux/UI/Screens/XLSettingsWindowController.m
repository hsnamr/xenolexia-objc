//
//  XLSettingsWindowController.m
//  Xenolexia
//
//  Settings window implementation (Phase 4)

#import "XLSettingsWindowController.h"
#import "../../../../Core/Services/XLStorageService.h"

#define ROW(y) (400 - (y) * 28)
#define LABEL_X 20
#define FIELD_X 180
#define W 360

@interface XLSettingsWindowController ()
- (void)buildForm;
- (void)prefsToForm;
- (void)formToPrefs;
@end

@implementation XLSettingsWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _storageService = [XLStorageService sharedService];
        _prefs = [[XLUserPreferences defaultPreferences] retain];
    }
    return self;
}

- (void)dealloc {
    [_prefs release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setTitle:@"Xenolexia - Settings"];
    [self.window setContentSize:NSMakeSize(560, 420)];
    [self buildForm];
    [self loadPreferences];
}

- (void)buildForm {
    NSView *contentView = [self.window contentView];
    NSInteger y = 0;

    NSTextField *srcL = [self label:@"Source language" at:ROW(y++)];
    _sourceLangPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, W, 24)];
    [contentView addSubview:srcL];
    [contentView addSubview:_sourceLangPopUp];
    y++;

    NSTextField *tgtL = [self label:@"Target language" at:ROW(y++)];
    _targetLangPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, W, 24)];
    [contentView addSubview:tgtL];
    [contentView addSubview:_targetLangPopUp];
    y++;

    NSTextField *profL = [self label:@"Proficiency" at:ROW(y++)];
    _proficiencyPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, W, 24)];
    [_proficiencyPopUp addItemWithTitle:@"Beginner"];
    [_proficiencyPopUp addItemWithTitle:@"Intermediate"];
    [_proficiencyPopUp addItemWithTitle:@"Advanced"];
    [contentView addSubview:profL];
    [contentView addSubview:_proficiencyPopUp];
    y++;

    NSTextField *densL = [self label:@"Word density (0.1–0.5)" at:ROW(y++)];
    _wordDensitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 200, 24)];
    [_wordDensitySlider setMinValue:0.1];
    [_wordDensitySlider setMaxValue:0.5];
    [_wordDensitySlider setDoubleValue:0.3];
    _wordDensityLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X + 210, ROW(y) - 4, 80, 24)];
    [_wordDensityLabel setEditable:NO];
    [_wordDensityLabel setBordered:NO];
    [_wordDensityLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_wordDensitySlider setTarget:self];
    [_wordDensitySlider setAction:@selector(densitySliderChanged:)];
    [contentView addSubview:densL];
    [contentView addSubview:_wordDensitySlider];
    [contentView addSubview:_wordDensityLabel];
    y++;

    NSTextField *themeL = [self label:@"Reader theme" at:ROW(y++)];
    _themePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, W, 24)];
    [_themePopUp addItemWithTitle:@"Light"];
    [_themePopUp addItemWithTitle:@"Dark"];
    [_themePopUp addItemWithTitle:@"Sepia"];
    [contentView addSubview:themeL];
    [contentView addSubview:_themePopUp];
    y++;

    NSTextField *fontL = [self label:@"Font family" at:ROW(y++)];
    _fontFamilyField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, W, 24)];
    [contentView addSubview:fontL];
    [contentView addSubview:_fontFamilyField];
    y++;

    NSTextField *sizeL = [self label:@"Font size" at:ROW(y++)];
    _fontSizeField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 80, 24)];
    [contentView addSubview:sizeL];
    [contentView addSubview:_fontSizeField];
    y++;

    NSTextField *lineL = [self label:@"Line height" at:ROW(y++)];
    _lineHeightField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 80, 24)];
    [contentView addSubview:lineL];
    [contentView addSubview:_lineHeightField];
    y++;

    NSTextField *mH = [self label:@"Margin horizontal" at:ROW(y++)];
    _marginHField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 80, 24)];
    [contentView addSubview:mH];
    [contentView addSubview:_marginHField];
    y++;

    NSTextField *mV = [self label:@"Margin vertical" at:ROW(y++)];
    _marginVField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 80, 24)];
    [contentView addSubview:mV];
    [contentView addSubview:_marginVField];
    y++;

    NSTextField *goalL = [self label:@"Daily goal (minutes)" at:ROW(y++)];
    _dailyGoalField = [[NSTextField alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 80, 24)];
    [contentView addSubview:goalL];
    [contentView addSubview:_dailyGoalField];
    y++;

    NSTextField *notifL = [self label:@"Notifications" at:ROW(y++)];
    _notificationsCheckBox = [[NSButton alloc] initWithFrame:NSMakeRect(FIELD_X, ROW(y) - 4, 200, 24)];
    [_notificationsCheckBox setButtonType:NSSwitchButton];
    [_notificationsCheckBox setTitle:@"Enabled"];
    [contentView addSubview:notifL];
    [contentView addSubview:_notificationsCheckBox];
    y++;

    _saveButton = [[NSButton alloc] initWithFrame:NSMakeRect(300, 20, 100, 32)];
    [_saveButton setTitle:@"Save"];
    [_saveButton setTarget:self];
    [_saveButton setAction:@selector(saveClicked:)];
    [contentView addSubview:_saveButton];

    _resetButton = [[NSButton alloc] initWithFrame:NSMakeRect(410, 20, 130, 32)];
    [_resetButton setTitle:@"Reset to defaults"];
    [_resetButton setTarget:self];
    [_resetButton setAction:@selector(resetClicked:)];
    [contentView addSubview:_resetButton];

    [self prefsToForm];
}

- (NSTextField *)label:(NSString *)text at:(CGFloat)y {
    NSTextField *l = [[NSTextField alloc] initWithFrame:NSMakeRect(LABEL_X, y, 150, 20)];
    [l setStringValue:text];
    [l setEditable:NO];
    [l setBordered:NO];
    [l setBackgroundColor:[NSColor controlBackgroundColor]];
    return [l autorelease];
}

- (void)densitySliderChanged:(id)sender {
    [_wordDensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", [_wordDensitySlider doubleValue]]];
}

- (void)loadPreferences {
    [_storageService getPreferencesWithDelegate:self];
}

#pragma mark - XLStorageServiceDelegate

- (void)storageService:(id)service didGetPreferences:(XLUserPreferences *)prefs withError:(NSError *)error {
    if (error || !prefs) {
        [self prefsToForm];
        return;
    }
    [_prefs release];
    _prefs = [prefs retain];
    [self prefsToForm];
}

- (void)storageService:(id)service didSavePreferencesWithSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [_saveButton setTitle:@"Saved"];
    }
}

- (void)prefsToForm {
    NSArray *langs = [XLLanguageInfo supportedLanguages];
    [_sourceLangPopUp removeAllItems];
    [_targetLangPopUp removeAllItems];
    for (XLLanguageInfo *info in langs) {
        [_sourceLangPopUp addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", info.name, info.nativeName]];
        [_targetLangPopUp addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", info.name, info.nativeName]];
    }
    NSInteger srcIdx = 0, tgtIdx = 0;
    for (NSUInteger i = 0; i < [langs count]; i++) {
        XLLanguageInfo *info = [langs objectAtIndex:i];
        if (info.code == _prefs.defaultSourceLanguage) srcIdx = i;
        if (info.code == _prefs.defaultTargetLanguage) tgtIdx = i;
    }
    [_sourceLangPopUp selectItemAtIndex:srcIdx];
    [_targetLangPopUp selectItemAtIndex:tgtIdx];
    [_proficiencyPopUp selectItemAtIndex:_prefs.defaultProficiencyLevel];
    [_wordDensitySlider setDoubleValue:_prefs.defaultWordDensity];
    [_wordDensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", _prefs.defaultWordDensity]];
    [_themePopUp selectItemAtIndex:_prefs.readerSettings.theme];
    [_fontFamilyField setStringValue:_prefs.readerSettings.fontFamily ?: @"System"];
    [_fontSizeField setStringValue:[NSString stringWithFormat:@"%.1f", _prefs.readerSettings.fontSize]];
    [_lineHeightField setStringValue:[NSString stringWithFormat:@"%.2f", _prefs.readerSettings.lineHeight]];
    [_marginHField setStringValue:[NSString stringWithFormat:@"%.0f", _prefs.readerSettings.marginHorizontal]];
    [_marginVField setStringValue:[NSString stringWithFormat:@"%.0f", _prefs.readerSettings.marginVertical]];
    [_dailyGoalField setStringValue:[NSString stringWithFormat:@"%ld", (long)_prefs.dailyGoal]];
    [_notificationsCheckBox setState:_prefs.notificationsEnabled ? NSOnState : NSOffState];
}

- (void)formToPrefs {
    NSArray *langs = [XLLanguageInfo supportedLanguages];
    NSInteger srcIdx = [_sourceLangPopUp indexOfSelectedItem];
    NSInteger tgtIdx = [_targetLangPopUp indexOfSelectedItem];
    if (srcIdx >= 0 && srcIdx < (NSInteger)[langs count]) {
        _prefs.defaultSourceLanguage = [(XLLanguageInfo *)[langs objectAtIndex:srcIdx] code];
    }
    if (tgtIdx >= 0 && tgtIdx < (NSInteger)[langs count]) {
        _prefs.defaultTargetLanguage = [(XLLanguageInfo *)[langs objectAtIndex:tgtIdx] code];
    }
    _prefs.defaultProficiencyLevel = (XLProficiencyLevel)[_proficiencyPopUp indexOfSelectedItem];
    _prefs.defaultWordDensity = [_wordDensitySlider doubleValue];
    _prefs.readerSettings.theme = (XLReaderTheme)[_themePopUp indexOfSelectedItem];
    _prefs.readerSettings.fontFamily = [[[_fontFamilyField stringValue] copy] autorelease];
    _prefs.readerSettings.fontSize = [[_fontSizeField stringValue] doubleValue];
    if (_prefs.readerSettings.fontSize <= 0) _prefs.readerSettings.fontSize = 16;
    _prefs.readerSettings.lineHeight = [[_lineHeightField stringValue] doubleValue];
    if (_prefs.readerSettings.lineHeight <= 0) _prefs.readerSettings.lineHeight = 1.6;
    _prefs.readerSettings.marginHorizontal = [[_marginHField stringValue] doubleValue];
    _prefs.readerSettings.marginVertical = [[_marginVField stringValue] doubleValue];
    _prefs.dailyGoal = [[_dailyGoalField stringValue] integerValue];
    if (_prefs.dailyGoal <= 0) _prefs.dailyGoal = 30;
    _prefs.notificationsEnabled = ([_notificationsCheckBox state] == NSOnState);
}

- (IBAction)saveClicked:(id)sender {
    [self formToPrefs];
    [_saveButton setTitle:@"Saving..."];
    [_storageService savePreferences:_prefs delegate:self];
}

- (IBAction)resetClicked:(id)sender {
    [_prefs release];
    _prefs = [[XLUserPreferences defaultPreferences] retain];
    [self prefsToForm];
    [_storageService savePreferences:_prefs delegate:self];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(settingsWindowDidClose)]) {
        [_delegate settingsWindowDidClose];
    }
}

@end
