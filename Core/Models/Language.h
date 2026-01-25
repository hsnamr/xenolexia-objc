//
//  Language.h
//  Xenolexia
//
//  Language and proficiency level definitions

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Supported language codes
typedef NS_ENUM(NSInteger, XLLanguage) {
    XLLanguageEnglish = 0,
    XLLanguageGreek,
    XLLanguageSpanish,
    XLLanguageFrench,
    XLLanguageGerman,
    XLLanguageItalian,
    XLLanguagePortuguese,
    XLLanguageRussian,
    XLLanguageJapanese,
    XLLanguageChinese,
    XLLanguageKorean,
    XLLanguageArabic,
    XLLanguageDutch,
    XLLanguagePolish,
    XLLanguageTurkish,
    XLLanguageSwedish,
    XLLanguageDanish,
    XLLanguageFinnish,
    XLLanguageNorwegian,
    XLLanguageCzech,
    XLLanguageHungarian,
    XLLanguageRomanian,
    XLLanguageUkrainian,
    XLLanguageHebrew,
    XLLanguageHindi,
    XLLanguageThai,
    XLLanguageVietnamese,
    XLLanguageIndonesian
};

/// Proficiency levels
typedef NS_ENUM(NSInteger, XLProficiencyLevel) {
    XLProficiencyLevelBeginner = 0,
    XLProficiencyLevelIntermediate,
    XLProficiencyLevelAdvanced
};

/// CEFR levels
typedef NS_ENUM(NSInteger, XLCEFRLevel) {
    XLCEFRLevelA1 = 0,
    XLCEFRLevelA2,
    XLCEFRLevelB1,
    XLCEFRLevelB2,
    XLCEFRLevelC1,
    XLCEFRLevelC2
};

/// Language metadata for display
@interface XLLanguageInfo : NSObject

@property (nonatomic, readonly) XLLanguage code;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *nativeName;
@property (nonatomic, readonly, nullable, copy) NSString *flag; // Emoji flag
@property (nonatomic, readonly) BOOL rtl; // Right-to-left language

+ (instancetype)infoWithCode:(XLLanguage)code
                        name:(NSString *)name
                  nativeName:(NSString *)nativeName
                       flag:(nullable NSString *)flag
                         rtl:(BOOL)rtl;

+ (NSArray<XLLanguageInfo *> *)supportedLanguages;
+ (nullable XLLanguageInfo *)infoForCode:(XLLanguage)code;
+ (NSString *)codeStringForLanguage:(XLLanguage)language;
+ (XLLanguage)languageForCodeString:(NSString *)codeString;

@end

/// Language pair for translation
@interface XLLanguagePair : NSObject <NSCoding>

@property (nonatomic) XLLanguage sourceLanguage;
@property (nonatomic) XLLanguage targetLanguage;

+ (instancetype)pairWithSource:(XLLanguage)source target:(XLLanguage)target;

@end

NS_ASSUME_NONNULL_END
