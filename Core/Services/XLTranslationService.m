//
//  XLTranslationService.m
//  Xenolexia
//

#import "XLTranslationService.h"
#import "XLLibreTranslateClient.h"
#import "../../TranslationService.h" // Legacy Microsoft

@implementation XLTranslationService

+ (instancetype)sharedService {
    static XLTranslationService *sharedService = nil;
    if (sharedService == nil) {
        sharedService = [[self alloc] init];
    }
    return sharedService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _translationBackend = XLTranslationBackendMicrosoft;
        _libretranslateBaseURL = @"https://libretranslate.com";
    }
    return self;
}

- (void)translateWord:(NSString *)word
         fromLanguage:(XLLanguage)sourceLanguage
           toLanguage:(XLLanguage)targetLanguage
       withCompletion:(void(^)(NSString *translatedWord, NSError *error))completion {
    NSString *sourceCode = [XLLanguageInfo codeStringForLanguage:sourceLanguage];
    NSString *targetCode = [XLLanguageInfo codeStringForLanguage:targetLanguage];
    
    if (self.translationBackend == XLTranslationBackendLibreTranslate) {
        NSString *base = self.libretranslateBaseURL ?: @"https://libretranslate.com";
        [XLLibreTranslateClient translateText:word fromLanguage:sourceCode toLanguage:targetCode baseURL:base completion:^(NSString *translatedText, NSError *error) {
            if (completion) completion(translatedText, error);
        }];
        return;
    }
    TranslationService *legacyService = [TranslationService sharedTranslator];
    [legacyService doTranslateWord:word from:sourceCode to:targetCode withCompletion:^(NSString *translatedText) {
        if (completion) completion(translatedText, nil);
    }];
}

- (void)translateWords:(NSArray<NSString *> *)words
          fromLanguage:(XLLanguage)sourceLanguage
            toLanguage:(XLLanguage)targetLanguage
        withCompletion:(void(^)(NSArray<NSString *> * _Nullable translatedWords, NSError * _Nullable error))completion {
    // For now, translate sequentially (can be optimized with batching)
    NSMutableArray<NSString *> *translatedWords = [NSMutableArray array];
    __block NSError *lastError = nil;
    __block NSInteger completed = 0;
    
    if (words.count == 0) {
        if (completion) completion([[NSArray alloc] init], nil);
        return;
    }
    
    for (NSString *word in words) {
        [self translateWord:word
               fromLanguage:sourceLanguage
                 toLanguage:targetLanguage
             withCompletion:^(NSString *translatedWord, NSError *error) {
            if (error) {
                lastError = error;
            } else if (translatedWord) {
                [translatedWords addObject:translatedWord];
            }
            
            completed++;
            if (completed == [words count]) {
                if (completion) {
                    completion([translatedWords copy], lastError);
                }
            }
        }];
    }
}

- (void)pronounceWord:(NSString *)word
            inLanguage:(XLLanguage)language {
    // Use legacy service for pronunciation
    TranslationService *legacyService = [TranslationService sharedTranslator];
    NSString *languageCode = [XLLanguageInfo codeStringForLanguage:language];
    [legacyService doSayWord:word];
}

@end
