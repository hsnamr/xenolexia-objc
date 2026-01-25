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
        _bookId = [bookId copy];
        _title = [title copy];
        _author = [author copy];
        _format = XLBookFormatTxt;
        _fileSize = 0;
        _addedAt = [NSDate date];
        _lastReadAt = nil;
        _languagePair = [XLLanguagePair pairWithSource:XLLanguageEnglish target:XLLanguageFrench];
        _proficiencyLevel = XLProficiencyLevelBeginner;
        _wordDensity = 0.3;
        _progress = 0.0;
        _currentLocation = nil;
        _currentChapter = 0;
        _totalChapters = 0;
        _currentPage = 0;
        _totalPages = 0;
        _readingTimeMinutes = 0;
        _sourceUrl = nil;
        _isDownloaded = NO;
    }
    return self;
}

- (instancetype)init {
    return [self initWithId:[[NSUUID UUID] UUIDString] title:@"" author:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _bookId = [aDecoder decodeObjectForKey:@"bookId"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _author = [aDecoder decodeObjectForKey:@"author"];
        _coverPath = [aDecoder decodeObjectForKey:@"coverPath"];
        _filePath = [aDecoder decodeObjectForKey:@"filePath"];
        _format = [aDecoder decodeIntegerForKey:@"format"];
        _fileSize = [[aDecoder decodeObjectForKey:@"fileSize"] longLongValue];
        _addedAt = [aDecoder decodeObjectForKey:@"addedAt"];
        _lastReadAt = [aDecoder decodeObjectForKey:@"lastReadAt"];
        _languagePair = [aDecoder decodeObjectForKey:@"languagePair"];
        _proficiencyLevel = [aDecoder decodeIntegerForKey:@"proficiencyLevel"];
        _wordDensity = [[aDecoder decodeObjectForKey:@"wordDensity"] doubleValue];
        _progress = [[aDecoder decodeObjectForKey:@"progress"] doubleValue];
        _currentLocation = [aDecoder decodeObjectForKey:@"currentLocation"];
        _currentChapter = [aDecoder decodeIntegerForKey:@"currentChapter"];
        _totalChapters = [aDecoder decodeIntegerForKey:@"totalChapters"];
        _currentPage = [aDecoder decodeIntegerForKey:@"currentPage"];
        _totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        _readingTimeMinutes = [aDecoder decodeIntegerForKey:@"readingTimeMinutes"];
        _sourceUrl = [aDecoder decodeObjectForKey:@"sourceUrl"];
        _isDownloaded = [aDecoder decodeBoolForKey:@"isDownloaded"];
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
    [aCoder encodeObject:@(self.fileSize) forKey:@"fileSize"];
    [aCoder encodeObject:self.addedAt forKey:@"addedAt"];
    [aCoder encodeObject:self.lastReadAt forKey:@"lastReadAt"];
    [aCoder encodeObject:self.languagePair forKey:@"languagePair"];
    [aCoder encodeInteger:self.proficiencyLevel forKey:@"proficiencyLevel"];
    [aCoder encodeObject:@(self.wordDensity) forKey:@"wordDensity"];
    [aCoder encodeObject:@(self.progress) forKey:@"progress"];
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
        _title = @"";
        _author = nil;
        _bookDescription = nil;
        _coverUrl = nil;
        _language = nil;
        _publisher = nil;
        _publishDate = nil;
        _isbn = nil;
        _subjects = @[];
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
        _chapterId = [[NSUUID UUID] UUIDString];
        _title = @"";
        _index = 0;
        _content = @"";
        _wordCount = 0;
        _href = nil;
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
        _itemId = [[NSUUID UUID] UUIDString];
        _title = @"";
        _href = @"";
        _level = 0;
        _children = nil;
    }
    return self;
}

@end

@implementation XLParsedBook

- (instancetype)init {
    self = [super init];
    if (self) {
        _metadata = [[XLBookMetadata alloc] init];
        _chapters = @[];
        _tableOfContents = @[];
        _totalWordCount = 0;
    }
    return self;
}

@end
