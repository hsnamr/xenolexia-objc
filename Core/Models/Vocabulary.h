//
//  Vocabulary.h
//  Xenolexia
//
//  Vocabulary models matching React/C# implementations

#import <Foundation/Foundation.h>
#import "Language.h"

NS_ASSUME_NONNULL_BEGIN

/// Parts of speech
typedef NS_ENUM(NSInteger, XLPartOfSpeech) {
    XLPartOfSpeechNoun = 0,
    XLPartOfSpeechVerb,
    XLPartOfSpeechAdjective,
    XLPartOfSpeechAdverb,
    XLPartOfSpeechPronoun,
    XLPartOfSpeechPreposition,
    XLPartOfSpeechConjunction,
    XLPartOfSpeechInterjection,
    XLPartOfSpeechArticle,
    XLPartOfSpeechOther
};

/// Vocabulary status
typedef NS_ENUM(NSInteger, XLVocabularyStatus) {
    XLVocabularyStatusNew = 0,
    XLVocabularyStatusLearning,
    XLVocabularyStatusReview,
    XLVocabularyStatusLearned
};

/// Word entry in the database
@interface XLWordEntry : NSObject

@property (nonatomic, copy) NSString *wordId;
@property (nonatomic, copy) NSString *sourceWord;
@property (nonatomic, copy) NSString *targetWord;
@property (nonatomic) XLLanguage sourceLanguage;
@property (nonatomic) XLLanguage targetLanguage;
@property (nonatomic) XLProficiencyLevel proficiencyLevel;
@property (nonatomic) NSInteger frequencyRank;
@property (nonatomic) XLPartOfSpeech partOfSpeech;
@property (nonatomic, retain) NSArray *variants; // Alternative forms (plurals, conjugations)
@property (nonatomic, copy) NSString *pronunciation; // IPA or transliteration

+ (instancetype)entryWithSourceWord:(NSString *)sourceWord
                          targetWord:(NSString *)targetWord
                      sourceLanguage:(XLLanguage)sourceLanguage
                      targetLanguage:(XLLanguage)targetLanguage;

@end

/// Vocabulary item saved by user
@interface XLVocabularyItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *vocabularyId;
@property (nonatomic, copy) NSString *sourceWord;
@property (nonatomic, copy) NSString *targetWord;
@property (nonatomic) XLLanguage sourceLanguage;
@property (nonatomic) XLLanguage targetLanguage;
@property (nonatomic, copy) NSString *contextSentence;
@property (nonatomic, copy) NSString *bookId;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, retain) NSDate *addedAt;
@property (nonatomic, retain) NSDate *lastReviewedAt;
@property (nonatomic) NSInteger reviewCount;
@property (nonatomic) double easeFactor; // SM-2 algorithm
@property (nonatomic) NSInteger interval; // Days until next review
@property (nonatomic) XLVocabularyStatus status;

+ (instancetype)itemWithSourceWord:(NSString *)sourceWord
                         targetWord:(NSString *)targetWord
                     sourceLanguage:(XLLanguage)sourceLanguage
                     targetLanguage:(XLLanguage)targetLanguage;

/// Spec status strings: new, learning, review, learned (Xenolexia Core Spec)
+ (NSString *)codeStringForStatus:(XLVocabularyStatus)status;
+ (XLVocabularyStatus)statusForCodeString:(NSString *)codeString;

@end

NS_ASSUME_NONNULL_END
