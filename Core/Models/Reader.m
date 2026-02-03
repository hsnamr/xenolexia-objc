//
//  Reader.m
//  Xenolexia
//

#import "Reader.h"

@implementation XLReaderSettings

+ (instancetype)defaultSettings {
    XLReaderSettings *settings = [[XLReaderSettings alloc] init];
    settings.theme = XLReaderThemeLight;
    settings.fontFamily = @"System";
    settings.fontSize = 16.0;
    settings.lineHeight = 1.6;
    settings.marginHorizontal = 24.0;
    settings.marginVertical = 16.0;
    settings.textAlign = XLTextAlignLeft;
    settings.brightness = 1.0;
    return settings;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.theme = XLReaderThemeLight;
        self.fontFamily = @"System";
        self.fontSize = 16.0;
        self.lineHeight = 1.6;
        self.marginHorizontal = 24.0;
        self.marginVertical = 16.0;
        self.textAlign = XLTextAlignLeft;
        self.brightness = 1.0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.theme = [aDecoder decodeIntegerForKey:@"theme"];
        self.fontFamily = [aDecoder decodeObjectForKey:@"fontFamily"];
        NSNumber *fontSizeNum = [aDecoder decodeObjectForKey:@"fontSize"];
        self.fontSize = fontSizeNum ? [fontSizeNum doubleValue] : 16.0;
        NSNumber *lineHeightNum = [aDecoder decodeObjectForKey:@"lineHeight"];
        self.lineHeight = lineHeightNum ? [lineHeightNum doubleValue] : 1.6;
        NSNumber *marginHNum = [aDecoder decodeObjectForKey:@"marginHorizontal"];
        self.marginHorizontal = marginHNum ? [marginHNum doubleValue] : 24.0;
        NSNumber *marginVNum = [aDecoder decodeObjectForKey:@"marginVertical"];
        self.marginVertical = marginVNum ? [marginVNum doubleValue] : 16.0;
        self.textAlign = [aDecoder decodeIntegerForKey:@"textAlign"];
        NSNumber *brightnessNum = [aDecoder decodeObjectForKey:@"brightness"];
        self.brightness = brightnessNum ? [brightnessNum doubleValue] : 1.0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.theme forKey:@"theme"];
    [aCoder encodeObject:self.fontFamily forKey:@"fontFamily"];
    NSNumber *fontSizeNum = [NSNumber numberWithDouble:self.fontSize];
    [aCoder encodeObject:fontSizeNum forKey:@"fontSize"];
    NSNumber *lineHeightNum = [NSNumber numberWithDouble:self.lineHeight];
    [aCoder encodeObject:lineHeightNum forKey:@"lineHeight"];
    NSNumber *marginHNum = [NSNumber numberWithDouble:self.marginHorizontal];
    [aCoder encodeObject:marginHNum forKey:@"marginHorizontal"];
    NSNumber *marginVNum = [NSNumber numberWithDouble:self.marginVertical];
    [aCoder encodeObject:marginVNum forKey:@"marginVertical"];
    [aCoder encodeInteger:self.textAlign forKey:@"textAlign"];
    NSNumber *brightnessNum = [NSNumber numberWithDouble:self.brightness];
    [aCoder encodeObject:brightnessNum forKey:@"brightness"];
}

@end

@implementation XLUserPreferences

+ (instancetype)defaultPreferences {
    XLUserPreferences *prefs = [[XLUserPreferences alloc] init];
    prefs.defaultSourceLanguage = XLLanguageEnglish;
    prefs.defaultTargetLanguage = XLLanguageSpanish;
    prefs.defaultProficiencyLevel = XLProficiencyLevelBeginner;
    prefs.defaultWordDensity = 0.3;
    prefs.readerSettings = [XLReaderSettings defaultSettings];
    prefs.hasCompletedOnboarding = NO;
    prefs.notificationsEnabled = NO;
    prefs.dailyGoal = 30;
    return prefs;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.defaultSourceLanguage = XLLanguageEnglish;
        self.defaultTargetLanguage = XLLanguageSpanish;
        self.defaultProficiencyLevel = XLProficiencyLevelBeginner;
        self.defaultWordDensity = 0.3;
        self.readerSettings = [XLReaderSettings defaultSettings];
        self.hasCompletedOnboarding = NO;
        self.notificationsEnabled = NO;
        self.dailyGoal = 30;
    }
    return self;
}

@end

@implementation XLForeignWordData

+ (instancetype)dataWithOriginalWord:(NSString *)originalWord
                           foreignWord:(NSString *)foreignWord
                            startIndex:(NSInteger)startIndex
                              endIndex:(NSInteger)endIndex
                             wordEntry:(XLWordEntry *)wordEntry {
    XLForeignWordData *data = [[XLForeignWordData alloc] init];
    data.originalWord = originalWord;
    data.foreignWord = foreignWord;
    data.startIndex = startIndex;
    data.endIndex = endIndex;
    data.wordEntry = wordEntry;
    return data;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.originalWord = @"";
        self.foreignWord = @"";
        self.startIndex = 0;
        self.endIndex = 0;
        self.wordEntry = nil;
    }
    return self;
}

@end

@implementation XLProcessedChapter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.foreignWords = [[NSArray alloc] init];
        self.processedContent = @"";
    }
    return self;
}

@end

@implementation XLReadingSession

+ (instancetype)sessionWithBookId:(NSString *)bookId {
    XLReadingSession *session = [[XLReadingSession alloc] init];
    session.sessionId = [[NSUUID UUID] UUIDString];
    session.bookId = bookId;
    session.startedAt = [NSDate date];
    session.endedAt = nil;
    session.pagesRead = 0;
    session.wordsRevealed = 0;
    session.wordsSaved = 0;
    session.duration = 0;
    return session;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sessionId = [[NSUUID UUID] UUIDString];
        self.bookId = @"";
        self.startedAt = [NSDate date];
        self.endedAt = nil;
        self.pagesRead = 0;
        self.wordsRevealed = 0;
        self.wordsSaved = 0;
        self.duration = 0;
    }
    return self;
}

- (void)endSession {
    self.endedAt = [NSDate date];
    if (self.startedAt) {
        self.duration = [self.endedAt timeIntervalSinceDate:self.startedAt];
    }
}

@end

@implementation XLReadingStats

- (instancetype)init {
    self = [super init];
    if (self) {
        self.totalBooksRead = 0;
        self.totalReadingTime = 0;
        self.totalWordsLearned = 0;
        self.currentStreak = 0;
        self.longestStreak = 0;
        self.averageSessionDuration = 0;
        self.wordsRevealedToday = 0;
        self.wordsSavedToday = 0;
    }
    return self;
}

@end
