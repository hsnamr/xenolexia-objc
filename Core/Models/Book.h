//
//  Book.h
//  Xenolexia
//
//  Book model matching React/C# implementations

#import <Foundation/Foundation.h>
#import "Language.h"


/// Supported book formats
typedef NS_ENUM(NSInteger, XLBookFormat) {
    XLBookFormatEpub = 0,
    XLBookFormatFb2,
    XLBookFormatMobi,
    XLBookFormatPdf,
    XLBookFormatTxt
};

/// Book entity
@interface XLBook : NSObject <NSCoding>

@property (nonatomic, copy) NSString *bookId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *coverPath;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic) XLBookFormat format;
@property (nonatomic) long long fileSize; // in bytes
@property (nonatomic, retain) NSDate *addedAt;
@property (nonatomic, retain) NSDate *lastReadAt;
@property (nonatomic, retain) XLLanguagePair *languagePair;
@property (nonatomic) XLProficiencyLevel proficiencyLevel;
@property (nonatomic) double wordDensity; // 0.0 - 1.0

// Reading Progress
@property (nonatomic) double progress; // 0-100 percentage
@property (nonatomic, nullable, copy) NSString *currentLocation; // CFI for EPUB, chapter index otherwise
@property (nonatomic) NSInteger currentChapter;
@property (nonatomic) NSInteger totalChapters;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic) NSInteger readingTimeMinutes;

// Download/Source info
@property (nonatomic, copy) NSString *sourceUrl;
@property (nonatomic) BOOL isDownloaded;

+ (instancetype)bookWithId:(NSString *)bookId
                     title:(NSString *)title
                    author:(NSString *)author;

- (instancetype)initWithId:(NSString *)bookId
                     title:(NSString *)title
                    author:(NSString *)author;

@end

/// Book metadata
@interface XLBookMetadata : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *author;
@property (nonatomic, nullable, copy) NSString *bookDescription;
@property (nonatomic, nullable, copy) NSString *coverUrl;
@property (nonatomic, nullable, copy) NSString *language;
@property (nonatomic, nullable, copy) NSString *publisher;
@property (nonatomic, nullable, copy) NSString *publishDate;
@property (nonatomic, nullable, copy) NSString *isbn;
@property (nonatomic, retain) NSArray *subjects;

@end

/// Chapter in a book
@interface XLChapter : NSObject

@property (nonatomic, copy) NSString *chapterId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSInteger index;
@property (nonatomic, copy) NSString *content; // HTML or plain text
@property (nonatomic) NSInteger wordCount;
@property (nonatomic, copy) NSString *href; // Path to the chapter file in EPUB

+ (instancetype)chapterWithId:(NSString *)chapterId
                         title:(NSString *)title
                         index:(NSInteger)index
                       content:(NSString *)content;

@end

/// Table of contents item
@interface XLTOCItem : NSObject

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *href;
@property (nonatomic) NSInteger level;
@property (nonatomic, retain) NSArray *children;

+ (instancetype)itemWithId:(NSString *)itemId
                     title:(NSString *)title
                      href:(NSString *)href
                     level:(NSInteger)level;

@end

/// Parsed book structure
@interface XLParsedBook : NSObject

@property (nonatomic, retain) XLBookMetadata *metadata;
@property (nonatomic, retain) NSArray *chapters;
@property (nonatomic, retain) NSArray *tableOfContents;
@property (nonatomic) NSInteger totalWordCount;

@end

