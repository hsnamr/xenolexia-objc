//
//  XLTranslationEngine.m
//  Xenolexia
//

#import "XLTranslationEngine.h"
#import "XLTranslationService.h"

@interface XLTranslationEngine ()

@property (nonatomic, strong) XLTranslationOptions *options;
@property (nonatomic, strong) NSMutableDictionary<NSString *, XLWordEntry *> *wordCache;

@end

@implementation XLTranslationEngine

- (instancetype)initWithOptions:(XLTranslationOptions *)options {
    self = [super init];
    if (self) {
        _options = options;
        _wordCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)processChapter:(XLChapter *)chapter
        withCompletion:(void(^)(XLProcessedChapter * _Nullable processedChapter, NSError * _Nullable error))completion {
    [self processContent:chapter.content withCompletion:^(NSString * _Nullable processedContent, NSArray<XLForeignWordData *> * _Nullable foreignWords, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        XLProcessedChapter *processedChapter = [[XLProcessedChapter alloc] init];
        processedChapter.chapterId = chapter.chapterId;
        processedChapter.title = chapter.title;
        processedChapter.index = chapter.index;
        processedChapter.content = chapter.content;
        processedChapter.wordCount = chapter.wordCount;
        processedChapter.href = chapter.href;
        processedChapter.processedContent = processedContent ?: @"";
        processedChapter.foreignWords = foreignWords ?: @[];
        
        if (completion) {
            completion(processedChapter, nil);
        }
    }];
}

- (void)processContent:(NSString *)content
        withCompletion:(void(^)(NSString * _Nullable processedContent, NSArray<XLForeignWordData *> * _Nullable foreignWords, NSError * _Nullable error))completion {
    // Tokenize text
    NSArray<NSString *> *words = [self tokenizeText:content];
    
    // Select words to replace based on proficiency and density
    NSArray<NSString *> *wordsToReplace = [self selectWordsToReplace:words];
    
    // Process replacements
    NSMutableString *processedContent = [content mutableCopy];
    NSMutableArray<XLForeignWordData *> *foreignWords = [NSMutableArray array];
    NSInteger offset = 0;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSString *word in wordsToReplace) {
        dispatch_group_enter(group);
        
        [self getTranslationForWord:word completion:^(XLWordEntry * _Nullable entry, NSError * _Nullable error) {
            if (entry && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSRange range = [processedContent rangeOfString:word
                                                            options:NSCaseInsensitiveSearch
                                                              range:NSMakeRange(offset, processedContent.length - offset)];
                    if (range.location != NSNotFound) {
                        // Replace word
                        [processedContent replaceCharactersInRange:range withString:entry.targetWord];
                        
                        // Create foreign word data
                        XLForeignWordData *data = [XLForeignWordData dataWithOriginalWord:word
                                                                              foreignWord:entry.targetWord
                                                                               startIndex:range.location
                                                                                 endIndex:range.location + entry.targetWord.length
                                                                                wordEntry:entry];
                        [foreignWords addObject:data];
                        
                        offset = range.location + entry.targetWord.length;
                    }
                });
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, queue, ^{
        if (completion) {
            completion([processedContent copy], [foreignWords copy], nil);
        }
    });
}

#pragma mark - Private Methods

- (NSArray<NSString *> *)tokenizeText:(NSString *)text {
    // Simple tokenization - split by whitespace and punctuation
    NSCharacterSet *wordBoundarySet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r.,!?;:()[]{}\"'-"];
    NSArray<NSString *> *components = [text componentsSeparatedByCharactersInSet:wordBoundarySet];
    
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSString *component in components) {
        NSString *trimmed = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0 && trimmed.length >= 2 && trimmed.length <= 25) {
            [words addObject:[trimmed lowercaseString]];
        }
    }
    
    return words;
}

- (NSArray<NSString *> *)selectWordsToReplace:(NSArray<NSString *> *)words {
    // Filter by frequency rank based on proficiency level
    NSInteger minRank, maxRank;
    switch (self.options.proficiencyLevel) {
        case XLProficiencyLevelBeginner:
            minRank = 1;
            maxRank = 500;
            break;
        case XLProficiencyLevelIntermediate:
            minRank = 501;
            maxRank = 2000;
            break;
        case XLProficiencyLevelAdvanced:
            minRank = 2001;
            maxRank = 5000;
            break;
    }
    
    // Select words based on density
    NSInteger targetCount = (NSInteger)(words.count * self.options.wordDensity);
    NSMutableArray<NSString *> *selected = [NSMutableArray array];
    
    // Simple selection: take first N words that meet criteria
    for (NSString *word in words) {
        if (selected.count >= targetCount) break;
        
        // Skip excluded words
        if ([self.options.excludeWords containsObject:word]) continue;
        
        // For now, accept all words (frequency filtering would require a database)
        [selected addObject:word];
    }
    
    return selected;
}

- (void)getTranslationForWord:(NSString *)word
                    completion:(void(^)(XLWordEntry * _Nullable entry, NSError * _Nullable error))completion {
    // Check cache first
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%ld_%ld",
                         word,
                         (long)self.options.languagePair.sourceLanguage,
                         (long)self.options.languagePair.targetLanguage];
    
    XLWordEntry *cached = self.wordCache[cacheKey];
    if (cached) {
        if (completion) completion(cached, nil);
        return;
    }
    
    // Get translation from service
    XLTranslationService *translationService = [XLTranslationService sharedService];
    [translationService translateWord:word
                            fromLanguage:self.options.languagePair.sourceLanguage
                              toLanguage:self.options.languagePair.targetLanguage
                          withCompletion:^(NSString * _Nullable translatedWord, NSError * _Nullable error) {
        if (error || !translatedWord) {
            if (completion) completion(nil, error);
            return;
        }
        
        // Create word entry
        XLWordEntry *entry = [XLWordEntry entryWithSourceWord:word
                                                    targetWord:translatedWord
                                                sourceLanguage:self.options.languagePair.sourceLanguage
                                                targetLanguage:self.options.languagePair.targetLanguage];
        entry.proficiencyLevel = self.options.proficiencyLevel;
        
        // Cache it
        self.wordCache[cacheKey] = entry;
        
        if (completion) completion(entry, nil);
    }];
}

@end

@implementation XLTranslationOptions

+ (instancetype)optionsWithLanguagePair:(XLLanguagePair *)languagePair
                       proficiencyLevel:(XLProficiencyLevel)proficiencyLevel
                           wordDensity:(double)wordDensity {
    XLTranslationOptions *options = [[XLTranslationOptions alloc] init];
    options.languagePair = languagePair;
    options.proficiencyLevel = proficiencyLevel;
    options.wordDensity = wordDensity;
    options.excludeWords = @[];
    return options;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _languagePair = [XLLanguagePair pairWithSource:XLLanguageEnglish target:XLLanguageFrench];
        _proficiencyLevel = XLProficiencyLevelBeginner;
        _wordDensity = 0.3;
        _excludeWords = @[];
    }
    return self;
}

@end
