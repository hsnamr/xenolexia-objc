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
        entry.variants = [[NSArray alloc] init];
    entry.pronunciation = nil;
    return entry;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.wordId = [[NSUUID UUID] UUIDString];
        self.sourceWord = @"";
        self.targetWord = @"";
        self.sourceLanguage = XLLanguageEnglish;
        self.targetLanguage = XLLanguageFrench;
        self.proficiencyLevel = XLProficiencyLevelBeginner;
        self.frequencyRank = 0;
        self.partOfSpeech = XLPartOfSpeechOther;
        self.variants = [[NSArray alloc] init];
        self.pronunciation = nil;
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
        self.vocabularyId = [[NSUUID UUID] UUIDString];
        self.sourceWord = @"";
        self.targetWord = @"";
        self.sourceLanguage = XLLanguageEnglish;
        self.targetLanguage = XLLanguageFrench;
        self.contextSentence = nil;
        self.bookId = nil;
        self.bookTitle = nil;
        self.addedAt = [NSDate date];
        self.lastReviewedAt = nil;
        self.reviewCount = 0;
        self.easeFactor = 2.5;
        self.interval = 0;
        self.status = XLVocabularyStatusNew;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.vocabularyId = [aDecoder decodeObjectForKey:@"vocabularyId"];
        self.sourceWord = [aDecoder decodeObjectForKey:@"sourceWord"];
        self.targetWord = [aDecoder decodeObjectForKey:@"targetWord"];
        self.sourceLanguage = [aDecoder decodeIntegerForKey:@"sourceLanguage"];
        self.targetLanguage = [aDecoder decodeIntegerForKey:@"targetLanguage"];
        self.contextSentence = [aDecoder decodeObjectForKey:@"contextSentence"];
        self.bookId = [aDecoder decodeObjectForKey:@"bookId"];
        self.bookTitle = [aDecoder decodeObjectForKey:@"bookTitle"];
        self.addedAt = [aDecoder decodeObjectForKey:@"addedAt"];
        self.lastReviewedAt = [aDecoder decodeObjectForKey:@"lastReviewedAt"];
        self.reviewCount = [aDecoder decodeIntegerForKey:@"reviewCount"];
        NSNumber *easeFactorNum = [aDecoder decodeObjectForKey:@"easeFactor"];
        self.easeFactor = easeFactorNum ? [easeFactorNum doubleValue] : 2.5;
        self.interval = [aDecoder decodeIntegerForKey:@"interval"];
        self.status = [aDecoder decodeIntegerForKey:@"status"];
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
    NSNumber *easeFactorNum = [NSNumber numberWithDouble:self.easeFactor];
    [aCoder encodeObject:easeFactorNum forKey:@"easeFactor"];
    [aCoder encodeInteger:self.interval forKey:@"interval"];
    [aCoder encodeInteger:self.status forKey:@"status"];
}

@end
