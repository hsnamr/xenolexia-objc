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
        
        // Initialize storage (silently, errors will be logged if needed)
        // Database will be initialized on first use
    }
    return self;
}

#pragma mark - Book Operations

- (void)importBookAtPath:(NSString *)filePath
          withCompletion:(void(^)(XLBook *book, NSError *error))completion {
    // Get file size
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
    long long fileSize = 0;
    if (fileAttributes) {
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        if (fileSizeNumber) {
            fileSize = [fileSizeNumber longLongValue];
        }
    }
    
    [self.bookParser parseBookAtPath:filePath withCompletion:^(XLParsedBook *parsedBook, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // Create book from parsed data
        XLBook *book = [[XLBook alloc] initWithId:[[NSUUID UUID] UUIDString]
                                             title:parsedBook.metadata.title ? parsedBook.metadata.title : @"Unknown Title"
                                            author:parsedBook.metadata.author ? parsedBook.metadata.author : @"Unknown Author"];
        book.filePath = filePath;
        book.format = [self detectFormat:filePath];
        book.totalChapters = [parsedBook.chapters count];
        book.fileSize = fileSize;
        
        // Save to storage
        XLStorageServiceBlockHelper *helper = [[XLStorageServiceBlockHelper alloc] init];
        helper.saveBookCompletion = ^(BOOL success, NSError *saveError) {
            if (completion) {
                completion(success ? book : nil, saveError);
            }
        };
        [self.storageService saveBook:book delegate:helper];
    }];
}

// Delegate-based version (GNUStep compatible)
- (void)importBookAtPath:(NSString *)filePath delegate:(id<XLManagerDelegate>)delegate {
    // Use block-based method internally and bridge to delegate
    [self importBookAtPath:filePath withCompletion:^(XLBook *book, NSError *error) {
        if ([delegate respondsToSelector:@selector(manager:didImportBook:withError:)]) {
            [delegate manager:self didImportBook:book withError:error];
        }
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

// Delegate-based version (GNUStep compatible)
- (void)processBook:(XLBook *)book delegate:(id<XLManagerDelegate>)delegate {
    // Use block-based method internally and bridge to delegate
    [self processBook:book withCompletion:^(XLProcessedChapter *processedChapter, NSError *error) {
        if ([delegate respondsToSelector:@selector(manager:didProcessChapter:withError:)]) {
            [delegate manager:self didProcessChapter:processedChapter withError:error];
        }
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

// Delegate-based version (GNUStep compatible)
- (void)translateWord:(NSString *)word delegate:(id<XLManagerDelegate>)delegate {
    // Use block-based method internally and bridge to delegate
    [self translateWord:word withCompletion:^(NSString *translatedWord, NSError *error) {
        if ([delegate respondsToSelector:@selector(manager:didTranslateWord:toTranslation:withError:)]) {
            [delegate manager:self didTranslateWord:word toTranslation:translatedWord withError:error];
        }
    }];
}

- (void)pronounceWord:(NSString *)word {
    // Use default target language
    [self.translationService pronounceWord:word inLanguage:XLLanguageFrench];
}

#pragma mark - Vocabulary Operations

- (void)saveWordToVocabulary:(XLVocabularyItem *)item
               withCompletion:(void(^)(BOOL success, NSError *error))completion {
    // Use block helper to bridge to delegate-based storage service
    XLStorageServiceBlockHelper *helper = [[XLStorageServiceBlockHelper alloc] init];
    helper.saveVocabularyItemCompletion = completion;
    [self.storageService saveVocabularyItem:item delegate:helper];
}

// Delegate-based version (GNUStep compatible)
- (void)saveWordToVocabulary:(XLVocabularyItem *)item delegate:(id<XLManagerDelegate>)delegate {
    // Use block-based method internally and bridge to delegate
    [self saveWordToVocabulary:item withCompletion:^(BOOL success, NSError *error) {
        if ([delegate respondsToSelector:@selector(manager:didSaveWordToVocabulary:withSuccess:error:)]) {
            [delegate manager:self didSaveWordToVocabulary:item withSuccess:success error:error];
        }
    }];
}

- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray *items, NSError *error))completion {
    XLStorageServiceBlockHelper *helper = [[XLStorageServiceBlockHelper alloc] init];
    helper.getAllVocabularyItemsCompletion = completion;
    [self.storageService getAllVocabularyItemsWithDelegate:helper];
}

// Delegate-based version (GNUStep compatible)
- (void)getAllVocabularyItemsWithDelegate:(id<XLManagerDelegate>)delegate {
    // Bridge storage service delegate to manager delegate
    // Create a bridge delegate that converts storage callbacks to manager callbacks
    id<XLStorageServiceDelegate> bridgeDelegate = (id<XLStorageServiceDelegate>)[[NSObject alloc] init];
    // For now, we need a proper bridge - this is a simplified version
    // The storage service will call its delegate, which we need to convert
    // For MVP, we'll create a simple bridge class
    [self.storageService getAllVocabularyItemsWithDelegate:bridgeDelegate];
    // TODO: Create proper bridge delegate class
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
