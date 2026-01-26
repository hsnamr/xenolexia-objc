//
//  XLManager.m
//  Xenolexia
//

#import "XLManager.h"
#import "XLBookParserService.h"
#import "XLTranslationEngine.h"
#import "XLTranslationService.h"
#import "XLStorageService.h"
#import "XLExportService.h"
#import "../../DictionaryService.h"
#import "../../DownloadService.h"

@interface XLManager ()

@property (nonatomic, strong) XLBookParserService *bookParser;
@property (nonatomic, strong) XLTranslationEngine *translationEngine;
@property (nonatomic, strong) XLTranslationService *translationService;
@property (nonatomic, strong) XLStorageService *storageService;
@property (nonatomic, strong) XLExportService *exportService;
@property (nonatomic, strong) DictionaryService *dictionaryService; // Legacy
@property (nonatomic, strong) DownloadService *downloadService; // Legacy

@end

@implementation XLManager

+ (instancetype)sharedManager {
    static XLManager *sharedManager = nil;
    if (sharedManager == nil) {
        sharedManager = [[self alloc] init];
    }
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _bookParser = [XLBookParserService sharedService];
        _translationService = [XLTranslationService sharedService];
        _storageService = [XLStorageService sharedService];
        _exportService = [[XLExportService alloc] init];
        _dictionaryService = [[DictionaryService alloc] init];
        _downloadService = [[DownloadService alloc] init];
        
        // Initialize storage
        [_storageService initializeDatabaseWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed to initialize database: %@", error);
            }
        }];
    }
    return self;
}

#pragma mark - Book Operations

- (void)importBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLBook *book, NSError *error))completion {
    [self.bookParser parseBookAtPath:filePath withCompletion:^(XLParsedBook *parsedBook, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // Create book from parsed data
        XLBook *book = [[XLBook alloc] initWithId:[[NSUUID UUID] UUIDString]
                                             title:parsedBook.metadata.title
                                            author:parsedBook.metadata.author ?: @""];
        book.filePath = filePath;
        book.format = [self detectFormat:filePath];
        book.totalChapters = [parsedBook.chapters count];
        
        // Save to storage
        [self.storageService saveBook:book withCompletion:^(BOOL success, NSError * _Nullable saveError) {
            if (completion) {
                completion(success ? book : nil, saveError);
            }
        }];
    }];
}

- (void)processBook:(XLBook *)book
     withCompletion:(void(^)(XLProcessedChapter *processedChapter, NSError *error))completion {
    // Create translation options from book settings
    XLTranslationOptions *options = [XLTranslationOptions optionsWithLanguagePair:book.languagePair
                                                                 proficiencyLevel:book.proficiencyLevel
                                                                     wordDensity:book.wordDensity];
    
    // Create translation engine
    self.translationEngine = [[XLTranslationEngine alloc] initWithOptions:options];
    
    // Get current chapter
    [self.bookParser getChapterAtIndex:book.currentChapter
                              fromPath:book.filePath
                        withCompletion:^(XLChapter *chapter, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // Process chapter
        [self.translationEngine processChapter:chapter withCompletion:completion];
    }];
}

#pragma mark - Translation Operations

- (void)translateWord:(NSString *)word
       withCompletion:(void(^)(NSString *translatedWord, NSError *error))completion {
    // Use default language pair (can be made configurable)
    XLLanguagePair *languagePair = [XLLanguagePair pairWithSource:XLLanguageEnglish target:XLLanguageFrench];
    
    [self.translationService translateWord:word
                              fromLanguage:languagePair.sourceLanguage
                                toLanguage:languagePair.targetLanguage
                            withCompletion:completion];
}

- (void)pronounceWord:(NSString *)word {
    // Use default target language
    [self.translationService pronounceWord:word inLanguage:XLLanguageFrench];
}

#pragma mark - Vocabulary Operations

- (void)saveWordToVocabulary:(XLVocabularyItem *)item
               withCompletion:(void(^)(BOOL success, NSError *error))completion {
    [self.storageService saveVocabularyItem:item withCompletion:completion];
}

- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray *items, NSError *error))completion {
    [self.storageService getAllVocabularyItemsWithCompletion:completion];
}

#pragma mark - Legacy Methods

- (void)downloadFile:(NSURL *)fileURL {
    // Use SmallStep for cross-platform directory access
    SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
    NSString *documentsDirectory = [fileSystem documentsDirectory];
    [self.downloadService downloadFrom:fileURL toDirectory:documentsDirectory];
}

- (void)listFiles {
    // Use SmallStep for cross-platform directory access
    SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
    NSString *documentsDirectory = [fileSystem documentsDirectory];
    [self.downloadService listFilesInDirectory:documentsDirectory];
}

- (NSString *)replaceWordsInDocument:(NSString *)htmlString {
    // Use legacy dictionary service
    NSDictionary *dictionary = [self.dictionaryService loadDictionary];
    if (!dictionary) {
        return htmlString;
    }
    
    NSMutableString *result = [htmlString mutableCopy];
    for (NSString *key in dictionary) {
        [result replaceOccurrencesOfString:key
                                 withString:dictionary[key]
                                    options:0
                                      range:NSMakeRange(0, result.length)];
    }
    
    return [result copy];
}

#pragma mark - Private Methods

- (XLBookFormat)detectFormat:(NSString *)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    if ([extension isEqualToString:@"epub"]) {
        return XLBookFormatEpub;
    } else if ([extension isEqualToString:@"fb2"]) {
        return XLBookFormatFb2;
    } else if ([extension isEqualToString:@"mobi"]) {
        return XLBookFormatMobi;
    } else if ([extension isEqualToString:@"txt"]) {
        return XLBookFormatTxt;
    }
    return XLBookFormatTxt;
}

@end
