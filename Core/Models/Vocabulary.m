//
//  Vocabulary.m
//  Xenolexia
//

#import "Vocabulary.h"

@implementation XLWordEntry

+ (instancetype)entryWithSourceWord:(NSString *)sourceWord
                          targetWord:(NSString *)targetWord
                      sourceLanguage:(XLLanguage)sourceLanguage
                      targetLanguage:(XLLanguage)targetLanguage {
    XLWordEntry *entry = [[XLWordEntry alloc] init];
    entry.wordId = [[NSUUID UUID] UUIDString];
    entry.sourceWord = sourceWord;
    entry.targetWord = targetWord;
    entry.sourceLanguage = sourceLanguage;
    entry.targetLanguage = targetLanguage;
    entry.proficiencyLevel = XLProficiencyLevelBeginner;
    entry.frequencyRank = 0;
    entry.partOfSpeech = XLPartOfSpeechOther;
    entry.variants = @[];
    entry.pronunciation = nil;
    return entry;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _wordId = [[NSUUID UUID] UUIDString];
        _sourceWord = @"";
        _targetWord = @"";
        _sourceLanguage = XLLanguageEnglish;
        _targetLanguage = XLLanguageFrench;
        _proficiencyLevel = XLProficiencyLevelBeginner;
        _frequencyRank = 0;
        _partOfSpeech = XLPartOfSpeechOther;
        _variants = @[];
        _pronunciation = nil;
    }
    return self;
}

@end

@implementation XLVocabularyItem

+ (instancetype)itemWithSourceWord:(NSString *)sourceWord
                         targetWord:(NSString *)targetWord
                     sourceLanguage:(XLLanguage)sourceLanguage
                     targetLanguage:(XLLanguage)targetLanguage {
    XLVocabularyItem *item = [[XLVocabularyItem alloc] init];
    item.vocabularyId = [[NSUUID UUID] UUIDString];
    item.sourceWord = sourceWord;
    item.targetWord = targetWord;
    item.sourceLanguage = sourceLanguage;
    item.targetLanguage = targetLanguage;
    item.contextSentence = nil;
    item.bookId = nil;
    item.bookTitle = nil;
    item.addedAt = [NSDate date];
    item.lastReviewedAt = nil;
    item.reviewCount = 0;
    item.easeFactor = 2.5; // SM-2 default
    item.interval = 0;
    item.status = XLVocabularyStatusNew;
    return item;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _vocabularyId = [[NSUUID UUID] UUIDString];
        _sourceWord = @"";
        _targetWord = @"";
        _sourceLanguage = XLLanguageEnglish;
        _targetLanguage = XLLanguageFrench;
        _contextSentence = nil;
        _bookId = nil;
        _bookTitle = nil;
        _addedAt = [NSDate date];
        _lastReviewedAt = nil;
        _reviewCount = 0;
        _easeFactor = 2.5;
        _interval = 0;
        _status = XLVocabularyStatusNew;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _vocabularyId = [aDecoder decodeObjectForKey:@"vocabularyId"];
        _sourceWord = [aDecoder decodeObjectForKey:@"sourceWord"];
        _targetWord = [aDecoder decodeObjectForKey:@"targetWord"];
        _sourceLanguage = [aDecoder decodeIntegerForKey:@"sourceLanguage"];
        _targetLanguage = [aDecoder decodeIntegerForKey:@"targetLanguage"];
        _contextSentence = [aDecoder decodeObjectForKey:@"contextSentence"];
        _bookId = [aDecoder decodeObjectForKey:@"bookId"];
        _bookTitle = [aDecoder decodeObjectForKey:@"bookTitle"];
        _addedAt = [aDecoder decodeObjectForKey:@"addedAt"];
        _lastReviewedAt = [aDecoder decodeObjectForKey:@"lastReviewedAt"];
        _reviewCount = [aDecoder decodeIntegerForKey:@"reviewCount"];
        _easeFactor = [[aDecoder decodeObjectForKey:@"easeFactor"] doubleValue];
        _interval = [aDecoder decodeIntegerForKey:@"interval"];
        _status = [aDecoder decodeIntegerForKey:@"status"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.vocabularyId forKey:@"vocabularyId"];
    [aCoder encodeObject:self.sourceWord forKey:@"sourceWord"];
    [aCoder encodeObject:self.targetWord forKey:@"targetWord"];
    [aCoder encodeInteger:self.sourceLanguage forKey:@"sourceLanguage"];
    [aCoder encodeInteger:self.targetLanguage forKey:@"targetLanguage"];
    [aCoder encodeObject:self.contextSentence forKey:@"contextSentence"];
    [aCoder encodeObject:self.bookId forKey:@"bookId"];
    [aCoder encodeObject:self.bookTitle forKey:@"bookTitle"];
    [aCoder encodeObject:self.addedAt forKey:@"addedAt"];
    [aCoder encodeObject:self.lastReviewedAt forKey:@"lastReviewedAt"];
    [aCoder encodeInteger:self.reviewCount forKey:@"reviewCount"];
    [aCoder encodeObject:@(self.easeFactor) forKey:@"easeFactor"];
    [aCoder encodeInteger:self.interval forKey:@"interval"];
    [aCoder encodeInteger:self.status forKey:@"status"];
}

@end
