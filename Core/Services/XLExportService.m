//
//  XLExportService.m
//  Xenolexia
//

#import "XLExportService.h"
#import "../Models/Language.h"
#import "../Models/Vocabulary.h"
#import "SSFileSystem.h"
#import "CHCSVParser.h"

@interface XLExportService () {
    SSFileSystem *_fileSystem;
}
@end

@implementation XLExportService

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileSystem = [SSFileSystem sharedFileSystem];
    }
    return self;
}

- (void)exportVocabularyItems:(NSArray<XLVocabularyItem *> *)items
                        format:(XLExportFormat)format
                    toFilePath:(NSString *)filePath
                withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    NSString *content = nil;
    
    switch (format) {
        case XLExportFormatCSV:
            content = [self exportToCSV:items];
            break;
        case XLExportFormatJSON:
            content = [self exportToJSON:items];
            break;
        case XLExportFormatAnki:
            content = [self exportToAnki:items];
            break;
    }
    
    if (!content) {
        if (completion) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to generate export content"
                                                                  forKey:NSLocalizedDescriptionKey];
            completion(NO, [NSError errorWithDomain:@"XLExportService"
                                               code:1
                                           userInfo:userInfo]);
        }
        return;
    }
    
    // Use SmallStep for cross-platform file writing
    NSError *error = nil;
    BOOL success = [_fileSystem writeString:content toPath:filePath error:&error];
    
    if (completion) {
        completion(success, error);
    }
}

- (NSString *)exportToCSV:(NSArray *)items {
    // Use CHCSVWriter (FOSS) for correct CSV escaping; write to memory then return string
    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:stream encoding:NSUTF8StringEncoding delimiter:(unichar)','];
    if (!writer) {
        return nil;
    }
    // Spec 04-algorithms: source_word, target_word, source_language, target_language [, context_sentence] [, book_title] [, status, review_count, ease_factor, interval, added_at]
    [writer writeLineOfFields:@[ @"source_word", @"target_word", @"source_language", @"target_language", @"context_sentence", @"book_title", @"status", @"review_count", @"ease_factor", @"interval", @"added_at" ]];
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    dateFmt.dateFormat = @"yyyy-MM-dd";
    for (XLVocabularyItem *item in items) {
        [writer writeLineOfFields:@[
            item.sourceWord ?: @"",
            item.targetWord ?: @"",
            [XLLanguageInfo codeStringForLanguage:item.sourceLanguage],
            [XLLanguageInfo codeStringForLanguage:item.targetLanguage],
            item.contextSentence ?: @"",
            item.bookTitle ?: @"",
            [XLVocabularyItem codeStringForStatus:item.status],
            [NSString stringWithFormat:@"%ld", (long)item.reviewCount],
            [NSString stringWithFormat:@"%.2f", item.easeFactor],
            [NSString stringWithFormat:@"%ld", (long)item.interval],
            [dateFmt stringFromDate:item.addedAt]
        ]];
    }
    [writer closeStream];
    NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [writer release];
    if (!data || [data length] == 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)exportToJSON:(NSArray<XLVocabularyItem *> *)items {
    NSMutableArray<NSDictionary *> *jsonItems = [NSMutableArray array];
    NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
    for (XLVocabularyItem *item in items) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            item.sourceWord, @"sourceWord",
            item.targetWord, @"targetWord",
            [XLLanguageInfo codeStringForLanguage:item.sourceLanguage], @"sourceLanguage",
            [XLLanguageInfo codeStringForLanguage:item.targetLanguage], @"targetLanguage",
            nil];
        if (item.contextSentence) [dict setObject:item.contextSentence forKey:@"contextSentence"];
        if (item.bookId) [dict setObject:item.bookId forKey:@"bookId"];
        if (item.bookTitle) [dict setObject:item.bookTitle forKey:@"bookTitle"];
        [dict setObject:[iso stringFromDate:item.addedAt] forKey:@"addedAt"];
        if (item.lastReviewedAt) [dict setObject:[iso stringFromDate:item.lastReviewedAt] forKey:@"lastReviewedAt"];
        [dict setObject:@(item.reviewCount) forKey:@"reviewCount"];
        [dict setObject:@(item.easeFactor) forKey:@"easeFactor"];
        [dict setObject:@(item.interval) forKey:@"interval"];
        [dict setObject:[XLVocabularyItem codeStringForStatus:item.status] forKey:@"status"];
        [jsonItems addObject:dict];
    }
    NSDictionary *wrapper = @{
        @"exportedAt": [iso stringFromDate:[NSDate date]],
        @"itemCount": @(items.count),
        @"format": @"xenolexia-vocabulary-v1",
        @"items": jsonItems
    };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:wrapper options:NSJSONWritingPrettyPrinted error:&error];
    if (error) return @"{}";
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)exportToAnki:(NSArray *)items {
    NSMutableString *tsv = [[NSMutableString alloc] init];
    // Spec 04-algorithms: front = target (foreign), back = source + context; tags = sourceLang-targetLang status
    [tsv appendString:@"#separator:tab\n#html:true\n#tags column:3\n"];
    for (XLVocabularyItem *item in items) {
        NSString *front = item.targetWord;
        NSMutableString *back = [NSMutableString stringWithString:item.sourceWord];
        if (item.contextSentence.length) {
            [back appendFormat:@"<br><br><i>\"%@\"</i>", item.contextSentence];
        }
        if (item.bookTitle.length) {
            [back appendFormat:@"<br><small>From: %@</small>", item.bookTitle];
        }
        NSString *tags = [NSString stringWithFormat:@"%@-%@ %@", [XLLanguageInfo codeStringForLanguage:item.sourceLanguage], [XLLanguageInfo codeStringForLanguage:item.targetLanguage], [XLVocabularyItem codeStringForStatus:item.status]];
        [tsv appendFormat:@"%@\t%@\t%@\n", front, back, tags];
    }
    return [tsv copy];
}

- (NSString *)statusString:(XLVocabularyStatus)status {
    switch (status) {
        case XLVocabularyStatusNew:
            return @"New";
        case XLVocabularyStatusLearning:
            return @"Learning";
        case XLVocabularyStatusReview:
            return @"Review";
        case XLVocabularyStatusLearned:
            return @"Learned";
    }
}

@end
