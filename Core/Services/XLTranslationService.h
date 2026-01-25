//
//  XLTranslationService.h
//  Xenolexia
//
//  Translation service interface (refactored from TranslationService)

#import <Foundation/Foundation.h>
#import "../Models/Language.h"

NS_ASSUME_NONNULL_BEGIN

/// Translation service protocol
@protocol XLTranslationService <NSObject>

/// Translate a single word
- (void)translateWord:(NSString *)word
         fromLanguage:(XLLanguage)sourceLanguage
           toLanguage:(XLLanguage)targetLanguage
       withCompletion:(void(^)(NSString * _Nullable translatedWord, NSError * _Nullable error))completion;

/// Translate an array of words
- (void)translateWords:(NSArray<NSString *> *)words
          fromLanguage:(XLLanguage)sourceLanguage
            toLanguage:(XLLanguage)targetLanguage
        withCompletion:(void(^)(NSArray<NSString *> * _Nullable translatedWords, NSError * _Nullable error))completion;

/// Pronounce a word (text-to-speech)
- (void)pronounceWord:(NSString *)word
            inLanguage:(XLLanguage)language;

@end

/// Translation service implementation
@interface XLTranslationService : NSObject <XLTranslationService>

+ (instancetype)sharedService;

@end

NS_ASSUME_NONNULL_END
