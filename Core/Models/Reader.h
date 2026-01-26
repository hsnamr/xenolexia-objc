//
//  Reader.h
//  Xenolexia
//
//  Reader models matching React/C# implementations

#import <Foundation/Foundation.h>
#import "Book.h"
#import "Vocabulary.h"

NS_ASSUME_NONNULL_BEGIN

/// Reader theme
typedef NS_ENUM(NSInteger, XLReaderTheme) {
    XLReaderThemeLight = 0,
    XLReaderThemeDark,
    XLReaderThemeSepia
};

/// Text alignment
typedef NS_ENUM(NSInteger, XLTextAlign) {
    XLTextAlignLeft = 0,
    XLTextAlignJustify
};

/// Reader settings
@interface XLReaderSettings : NSObject <NSCoding>

@property (nonatomic) XLReaderTheme theme;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic) double fontSize; // in sp/pt
@property (nonatomic) double lineHeight; // multiplier
@property (nonatomic) double marginHorizontal; // in dp/pt
@property (nonatomic) double marginVertical; // in dp/pt
@property (nonatomic) XLTextAlign textAlign;
@property (nonatomic) double brightness; // 0.0 - 1.0

+ (instancetype)defaultSettings;

@end

/// Foreign word data in processed content
@interface XLForeignWordData : NSObject

@property (nonatomic, copy) NSString *originalWord;
@property (nonatomic, copy) NSString *foreignWord;
@property (nonatomic) NSInteger startIndex;
@property (nonatomic) NSInteger endIndex;
@property (nonatomic, retain) XLWordEntry *wordEntry;

+ (instancetype)dataWithOriginalWord:(NSString *)originalWord
                           foreignWord:(NSString *)foreignWord
                            startIndex:(NSInteger)startIndex
                              endIndex:(NSInteger)endIndex
                             wordEntry:(XLWordEntry *)wordEntry;

@end

/// Processed chapter with foreign words
@interface XLProcessedChapter : XLChapter

@property (nonatomic, retain) NSArray *foreignWords;
@property (nonatomic, copy) NSString *processedContent; // HTML with foreign words marked

@end

/// Reading session
@interface XLReadingSession : NSObject

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *bookId;
@property (nonatomic, retain) NSDate *startedAt;
@property (nonatomic, retain) NSDate *endedAt;
@property (nonatomic) NSInteger pagesRead;
@property (nonatomic) NSInteger wordsRevealed;
@property (nonatomic) NSInteger wordsSaved;
@property (nonatomic) NSTimeInterval duration; // in seconds

+ (instancetype)sessionWithBookId:(NSString *)bookId;

@end

/// Reading statistics
@interface XLReadingStats : NSObject

@property (nonatomic) NSInteger totalBooksRead;
@property (nonatomic) NSTimeInterval totalReadingTime; // in seconds
@property (nonatomic) NSInteger totalWordsLearned;
@property (nonatomic) NSInteger currentStreak; // days
@property (nonatomic) NSInteger longestStreak;
@property (nonatomic) NSTimeInterval averageSessionDuration;
@property (nonatomic) NSInteger wordsRevealedToday;
@property (nonatomic) NSInteger wordsSavedToday;

@end

NS_ASSUME_NONNULL_END
