//
//  Book.m
//  Xenolexia
//

#import "Book.h"

@implementation XLBook

+ (instancetype)bookWithId:(NSString *)bookId
                     title:(NSString *)title
                    author:(NSString *)author {
    return [[self alloc] initWithId:bookId title:title author:author];
}

- (instancetype)initWithId:(NSString *)bookId
                     title:(NSString *)title
                    author:(NSString *)author {
    self = [super init];
    if (self) {
        self.bookId = bookId;
        self.title = title;
        self.author = author;
        self.format = XLBookFormatTxt;
        self.fileSize = 0;
        self.addedAt = [NSDate date];
        self.lastReadAt = nil;
        self.languagePair = [XLLanguagePair pairWithSource:XLLanguageEnglish target:XLLanguageFrench];
        self.proficiencyLevel = XLProficiencyLevelBeginner;
        self.wordDensity = 0.3;
        self.progress = 0.0;
        self.currentLocation = nil;
        self.currentChapter = 0;
        self.totalChapters = 0;
        self.currentPage = 0;
        self.totalPages = 0;
        self.readingTimeMinutes = 0;
        self.sourceUrl = nil;
        self.isDownloaded = NO;
    }
    return self;
}

- (instancetype)init {
    return [self initWithId:[[NSUUID UUID] UUIDString] title:@"" author:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.bookId = [aDecoder decodeObjectForKey:@"bookId"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.author = [aDecoder decodeObjectForKey:@"author"];
        self.coverPath = [aDecoder decodeObjectForKey:@"coverPath"];
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
        self.format = [aDecoder decodeIntegerForKey:@"format"];
        NSNumber *fileSizeNum = [aDecoder decodeObjectForKey:@"fileSize"];
        self.fileSize = fileSizeNum ? [fileSizeNum longLongValue] : 0;
        self.addedAt = [aDecoder decodeObjectForKey:@"addedAt"];
        self.lastReadAt = [aDecoder decodeObjectForKey:@"lastReadAt"];
        self.languagePair = [aDecoder decodeObjectForKey:@"languagePair"];
        self.proficiencyLevel = [aDecoder decodeIntegerForKey:@"proficiencyLevel"];
        NSNumber *wordDensityNum = [aDecoder decodeObjectForKey:@"wordDensity"];
        self.wordDensity = wordDensityNum ? [wordDensityNum doubleValue] : 0.0;
        NSNumber *progressNum = [aDecoder decodeObjectForKey:@"progress"];
        self.progress = progressNum ? [progressNum doubleValue] : 0.0;
        self.currentLocation = [aDecoder decodeObjectForKey:@"currentLocation"];
        self.currentChapter = [aDecoder decodeIntegerForKey:@"currentChapter"];
        self.totalChapters = [aDecoder decodeIntegerForKey:@"totalChapters"];
        self.currentPage = [aDecoder decodeIntegerForKey:@"currentPage"];
        self.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        self.readingTimeMinutes = [aDecoder decodeIntegerForKey:@"readingTimeMinutes"];
        self.sourceUrl = [aDecoder decodeObjectForKey:@"sourceUrl"];
        self.isDownloaded = [aDecoder decodeBoolForKey:@"isDownloaded"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.bookId forKey:@"bookId"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.author forKey:@"author"];
    [aCoder encodeObject:self.coverPath forKey:@"coverPath"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    [aCoder encodeInteger:self.format forKey:@"format"];
    NSNumber *fileSizeNum = [NSNumber numberWithLongLong:self.fileSize];
    [aCoder encodeObject:fileSizeNum forKey:@"fileSize"];
    [aCoder encodeObject:self.addedAt forKey:@"addedAt"];
    [aCoder encodeObject:self.lastReadAt forKey:@"lastReadAt"];
    [aCoder encodeObject:self.languagePair forKey:@"languagePair"];
    [aCoder encodeInteger:self.proficiencyLevel forKey:@"proficiencyLevel"];
    NSNumber *wordDensityNum = [NSNumber numberWithDouble:self.wordDensity];
    [aCoder encodeObject:wordDensityNum forKey:@"wordDensity"];
    NSNumber *progressNum = [NSNumber numberWithDouble:self.progress];
    [aCoder encodeObject:progressNum forKey:@"progress"];
    [aCoder encodeObject:self.currentLocation forKey:@"currentLocation"];
    [aCoder encodeInteger:self.currentChapter forKey:@"currentChapter"];
    [aCoder encodeInteger:self.totalChapters forKey:@"totalChapters"];
    [aCoder encodeInteger:self.currentPage forKey:@"currentPage"];
    [aCoder encodeInteger:self.totalPages forKey:@"totalPages"];
    [aCoder encodeInteger:self.readingTimeMinutes forKey:@"readingTimeMinutes"];
    [aCoder encodeObject:self.sourceUrl forKey:@"sourceUrl"];
    [aCoder encodeBool:self.isDownloaded forKey:@"isDownloaded"];
}

@end

@implementation XLBookMetadata

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"";
        self.author = nil;
        self.bookDescription = nil;
        self.coverUrl = nil;
        self.language = nil;
        self.publisher = nil;
        self.publishDate = nil;
        self.isbn = nil;
        self.subjects = [[NSArray alloc] init];
    }
    return self;
}

@end

@implementation XLChapter

+ (instancetype)chapterWithId:(NSString *)chapterId
                         title:(NSString *)title
                         index:(NSInteger)index
                       content:(NSString *)content {
    XLChapter *chapter = [[XLChapter alloc] init];
    chapter.chapterId = chapterId;
    chapter.title = title;
    chapter.index = index;
    chapter.content = content;
    chapter.wordCount = 0;
    chapter.href = nil;
    return chapter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.chapterId = [[NSUUID UUID] UUIDString];
        self.title = @"";
        self.index = 0;
        self.content = @"";
        self.wordCount = 0;
        self.href = nil;
    }
    return self;
}

@end

@implementation XLTOCItem

+ (instancetype)itemWithId:(NSString *)itemId
                     title:(NSString *)title
                      href:(NSString *)href
                     level:(NSInteger)level {
    XLTOCItem *item = [[XLTOCItem alloc] init];
    item.itemId = itemId;
    item.title = title;
    item.href = href;
    item.level = level;
    item.children = nil;
    return item;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.itemId = [[NSUUID UUID] UUIDString];
        self.title = @"";
        self.href = @"";
        self.level = 0;
        self.children = nil;
    }
    return self;
}

@end

@implementation XLParsedBook

- (instancetype)init {
    self = [super init];
    if (self) {
        self.metadata = [[XLBookMetadata alloc] init];
        self.chapters = [[NSArray alloc] init];
        self.tableOfContents = [[NSArray alloc] init];
        self.totalWordCount = 0;
    }
    return self;
}

@end
