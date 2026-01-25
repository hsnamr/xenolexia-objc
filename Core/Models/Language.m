//
//  Language.m
//  Xenolexia
//

#import "Language.h"

@implementation XLLanguageInfo

+ (instancetype)infoWithCode:(XLLanguage)code
                        name:(NSString *)name
                  nativeName:(NSString *)nativeName
                       flag:(nullable NSString *)flag
                         rtl:(BOOL)rtl {
    XLLanguageInfo *info = [[XLLanguageInfo alloc] init];
    if (info) {
        info->_code = code;
        info->_name = [name copy];
        info->_nativeName = [nativeName copy];
        info->_flag = [flag copy];
        info->_rtl = rtl;
    }
    return info;
}

+ (NSArray<XLLanguageInfo *> *)supportedLanguages {
    static NSArray<XLLanguageInfo *> *languages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languages = @[
            [XLLanguageInfo infoWithCode:XLLanguageEnglish name:@"English" nativeName:@"English" flag:@"🇬🇧" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageSpanish name:@"Spanish" nativeName:@"Español" flag:@"🇪🇸" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageFrench name:@"French" nativeName:@"Français" flag:@"🇫🇷" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageGerman name:@"German" nativeName:@"Deutsch" flag:@"🇩🇪" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageItalian name:@"Italian" nativeName:@"Italiano" flag:@"🇮🇹" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguagePortuguese name:@"Portuguese" nativeName:@"Português" flag:@"🇵🇹" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageRussian name:@"Russian" nativeName:@"Русский" flag:@"🇷🇺" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageGreek name:@"Greek" nativeName:@"Ελληνικά" flag:@"🇬🇷" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageDutch name:@"Dutch" nativeName:@"Nederlands" flag:@"🇳🇱" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguagePolish name:@"Polish" nativeName:@"Polski" flag:@"🇵🇱" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageTurkish name:@"Turkish" nativeName:@"Türkçe" flag:@"🇹🇷" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageSwedish name:@"Swedish" nativeName:@"Svenska" flag:@"🇸🇪" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageDanish name:@"Danish" nativeName:@"Dansk" flag:@"🇩🇰" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageFinnish name:@"Finnish" nativeName:@"Suomi" flag:@"🇫🇮" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageNorwegian name:@"Norwegian" nativeName:@"Norsk" flag:@"🇳🇴" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageCzech name:@"Czech" nativeName:@"Čeština" flag:@"🇨🇿" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageHungarian name:@"Hungarian" nativeName:@"Magyar" flag:@"🇭🇺" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageRomanian name:@"Romanian" nativeName:@"Română" flag:@"🇷🇴" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageUkrainian name:@"Ukrainian" nativeName:@"Українська" flag:@"🇺🇦" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageJapanese name:@"Japanese" nativeName:@"日本語" flag:@"🇯🇵" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageChinese name:@"Chinese" nativeName:@"中文" flag:@"🇨🇳" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageKorean name:@"Korean" nativeName:@"한국어" flag:@"🇰🇷" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageArabic name:@"Arabic" nativeName:@"العربية" flag:@"🇵🇸" rtl:YES],
            [XLLanguageInfo infoWithCode:XLLanguageHebrew name:@"Hebrew" nativeName:@"עברית" flag:@"🇮🇱" rtl:YES],
            [XLLanguageInfo infoWithCode:XLLanguageHindi name:@"Hindi" nativeName:@"हिन्दी" flag:@"🇮🇳" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageThai name:@"Thai" nativeName:@"ไทย" flag:@"🇹🇭" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageVietnamese name:@"Vietnamese" nativeName:@"Tiếng Việt" flag:@"🇻🇳" rtl:NO],
            [XLLanguageInfo infoWithCode:XLLanguageIndonesian name:@"Indonesian" nativeName:@"Bahasa Indonesia" flag:@"🇮🇩" rtl:NO]
        ];
    });
    return languages;
}

+ (nullable XLLanguageInfo *)infoForCode:(XLLanguage)code {
    NSArray<XLLanguageInfo *> *languages = [self supportedLanguages];
    for (XLLanguageInfo *info in languages) {
        if (info.code == code) {
            return info;
        }
    }
    return nil;
}

+ (NSString *)codeStringForLanguage:(XLLanguage)language {
    NSArray<NSString *> *codes = @[
        @"en", @"el", @"es", @"fr", @"de", @"it", @"pt", @"ru", @"ja", @"zh",
        @"ko", @"ar", @"nl", @"pl", @"tr", @"sv", @"da", @"fi", @"no", @"cs",
        @"hu", @"ro", @"uk", @"he", @"hi", @"th", @"vi", @"id"
    ];
    if (language >= 0 && language < codes.count) {
        return codes[language];
    }
    return @"en";
}

+ (XLLanguage)languageForCodeString:(NSString *)codeString {
    NSDictionary<NSString *, NSNumber *> *codeMap = @{
        @"en": @(XLLanguageEnglish),
        @"el": @(XLLanguageGreek),
        @"es": @(XLLanguageSpanish),
        @"fr": @(XLLanguageFrench),
        @"de": @(XLLanguageGerman),
        @"it": @(XLLanguageItalian),
        @"pt": @(XLLanguagePortuguese),
        @"ru": @(XLLanguageRussian),
        @"ja": @(XLLanguageJapanese),
        @"zh": @(XLLanguageChinese),
        @"ko": @(XLLanguageKorean),
        @"ar": @(XLLanguageArabic),
        @"nl": @(XLLanguageDutch),
        @"pl": @(XLLanguagePolish),
        @"tr": @(XLLanguageTurkish),
        @"sv": @(XLLanguageSwedish),
        @"da": @(XLLanguageDanish),
        @"fi": @(XLLanguageFinnish),
        @"no": @(XLLanguageNorwegian),
        @"cs": @(XLLanguageCzech),
        @"hu": @(XLLanguageHungarian),
        @"ro": @(XLLanguageRomanian),
        @"uk": @(XLLanguageUkrainian),
        @"he": @(XLLanguageHebrew),
        @"hi": @(XLLanguageHindi),
        @"th": @(XLLanguageThai),
        @"vi": @(XLLanguageVietnamese),
        @"id": @(XLLanguageIndonesian)
    };
    NSNumber *langNumber = codeMap[codeString.lowercaseString];
    return langNumber ? langNumber.integerValue : XLLanguageEnglish;
}

@end

@implementation XLLanguagePair

+ (instancetype)pairWithSource:(XLLanguage)source target:(XLLanguage)target {
    XLLanguagePair *pair = [[XLLanguagePair alloc] init];
    pair.sourceLanguage = source;
    pair.targetLanguage = target;
    return pair;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _sourceLanguage = [aDecoder decodeIntegerForKey:@"sourceLanguage"];
        _targetLanguage = [aDecoder decodeIntegerForKey:@"targetLanguage"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.sourceLanguage forKey:@"sourceLanguage"];
    [aCoder encodeInteger:self.targetLanguage forKey:@"targetLanguage"];
}

@end
