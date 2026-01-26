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
        _theme = XLReaderThemeLight;
        _fontFamily = @"System";
        _fontSize = 16.0;
        _lineHeight = 1.6;
        _marginHorizontal = 24.0;
        _marginVertical = 16.0;
        _textAlign = XLTextAlignLeft;
        _brightness = 1.0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _theme = [aDecoder decodeIntegerForKey:@"theme"];
        _fontFamily = [aDecoder decodeObjectForKey:@"fontFamily"];
        _fontSize = [[aDecoder decodeObjectForKey:@"fontSize"] doubleValue];
        _lineHeight = [[aDecoder decodeObjectForKey:@"lineHeight"] doubleValue];
        _marginHorizontal = [[aDecoder decodeObjectForKey:@"marginHorizontal"] doubleValue];
        _marginVertical = [[aDecoder decodeObjectForKey:@"marginVertical"] doubleValue];
        _textAlign = [aDecoder decodeIntegerForKey:@"textAlign"];
        _brightness = [[aDecoder decodeObjectForKey:@"brightness"] doubleValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.theme forKey:@"theme"];
    [aCoder encodeObject:self.fontFamily forKey:@"fontFamily"];
    [aCoder encodeObject:@(self.fontSize) forKey:@"fontSize"];
    [aCoder encodeObject:@(self.lineHeight) forKey:@"lineHeight"];
    [aCoder encodeObject:@(self.marginHorizontal) forKey:@"marginHorizontal"];
    [aCoder encodeObject:@(self.marginVertical) forKey:@"marginVertical"];
    [aCoder encodeInteger:self.textAlign forKey:@"textAlign"];
    [aCoder encodeObject:@(self.brightness) forKey:@"brightness"];
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
        _originalWord = @"";
        _foreignWord = @"";
        _startIndex = 0;
        _endIndex = 0;
        _wordEntry = nil;
    }
    return self;
}

@end

@implementation XLProcessedChapter

- (instancetype)init {
    self = [super init];
    if (self) {
        _foreignWords = [[NSArray alloc] init];
        _processedContent = @"";
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
        _sessionId = [[NSUUID UUID] UUIDString];
        _bookId = @"";
        _startedAt = [NSDate date];
        _endedAt = nil;
        _pagesRead = 0;
        _wordsRevealed = 0;
        _wordsSaved = 0;
        _duration = 0;
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
        _totalBooksRead = 0;
        _totalReadingTime = 0;
        _totalWordsLearned = 0;
        _currentStreak = 0;
        _longestStreak = 0;
        _averageSessionDuration = 0;
        _wordsRevealedToday = 0;
        _wordsSavedToday = 0;
    }
    return self;
}

@end
