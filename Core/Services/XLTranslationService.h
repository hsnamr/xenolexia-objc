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
       withCompletion:(void(^)(NSString *translatedWord, NSError *error))completion;

/// Translate an array of words
- (void)translateWords:(NSArray *)words
          fromLanguage:(XLLanguage)sourceLanguage
            toLanguage:(XLLanguage)targetLanguage
        withCompletion:(void(^)(NSArray *translatedWords, NSError *error))completion;

/// Pronounce a word (text-to-speech)
- (void)pronounceWord:(NSString *)word
            inLanguage:(XLLanguage)language;

@end

/// Backend for translation: Microsoft (legacy) or LibreTranslate (FOSS).
typedef NS_ENUM(NSInteger, XLTranslationBackend) {
    XLTranslationBackendMicrosoft = 0,
    XLTranslationBackendLibreTranslate = 1
};

/// Translation service implementation
@interface XLTranslationService : NSObject <XLTranslationService>

+ (instancetype)sharedService;

/// Which backend to use (default Microsoft). Set to LibreTranslate for FOSS.
@property (nonatomic, assign) XLTranslationBackend translationBackend;
/// Base URL for LibreTranslate (e.g. https://libretranslate.com). Used when translationBackend is LibreTranslate.
@property (nonatomic, copy) NSString *libretranslateBaseURL;

@end

NS_ASSUME_NONNULL_END
