//
//  XLTranslationService.m
//  Xenolexia
//

#import "XLTranslationService.h"
#import "../../TranslationService.h" // Legacy service for now

@implementation XLTranslationService

+ (instancetype)sharedService {
    static XLTranslationService *sharedService = nil;
    if (sharedService == nil) {
        sharedService = [[self alloc] init];
    }
    return sharedService;
}

- (void)translateWord:(NSString *)word
         fromLanguage:(XLLanguage)sourceLanguage
           toLanguage:(XLLanguage)targetLanguage
       withCompletion:(void(^)(NSString *translatedWord, NSError *error))completion {
    // For now, use the legacy TranslationService
    // This can be replaced with a proper translation API implementation
    TranslationService *legacyService = [TranslationService sharedTranslator];
    
    // Convert language codes to strings (legacy service expects "en", "ja", etc.)
    NSString *sourceCode = [XLLanguageInfo codeStringForLanguage:sourceLanguage];
    NSString *targetCode = [XLLanguageInfo codeStringForLanguage:targetLanguage];
    
    // Use legacy service method that accepts language codes
    [legacyService doTranslateWord:word from:sourceCode to:targetCode withCompletion:^(NSString *translatedText) {
        if (completion) {
            completion(translatedText, nil);
        }
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
