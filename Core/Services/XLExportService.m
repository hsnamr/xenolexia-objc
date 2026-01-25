//
//  XLExportService.m
//  Xenolexia
//

#import "XLExportService.h"

@implementation XLExportService

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
            completion(NO, [NSError errorWithDomain:@"XLExportService"
                                               code:1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Failed to generate export content"}]);
        }
        return;
    }
    
    // Use SmallStep for cross-platform file writing
    NSError *error = nil;
    BOOL success = [self.fileSystem writeString:content toPath:filePath error:&error];
    
    if (completion) {
        completion(success, error);
    }
}

- (NSString *)exportToCSV:(NSArray<XLVocabularyItem *> *)items {
    NSMutableString *csv = [NSMutableString string];
    
    // Header
    [csv appendString:@"Source Word,Target Word,Context Sentence,Book Title,Added At,Review Count,Status\n"];
    
    // Rows
    for (XLVocabularyItem *item in items) {
        NSString *context = item.contextSentence ?: @"";
        NSString *bookTitle = item.bookTitle ?: @"";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *addedAt = [formatter stringFromDate:item.addedAt];
        NSString *status = [self statusString:item.status];
        
        [csv appendFormat:@"\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",%ld,\"%@\"\n",
         item.sourceWord,
         item.targetWord,
         context,
         bookTitle,
         addedAt,
         (long)item.reviewCount,
         status];
    }
    
    return [csv copy];
}

- (NSString *)exportToJSON:(NSArray<XLVocabularyItem *> *)items {
    NSMutableArray<NSDictionary *> *jsonArray = [NSMutableArray array];
    
    for (XLVocabularyItem *item in items) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"id"] = item.vocabularyId;
        dict[@"sourceWord"] = item.sourceWord;
        dict[@"targetWord"] = item.targetWord;
        dict[@"sourceLanguage"] = @(item.sourceLanguage);
        dict[@"targetLanguage"] = @(item.targetLanguage);
        if (item.contextSentence) {
            dict[@"contextSentence"] = item.contextSentence;
        }
        if (item.bookId) {
            dict[@"bookId"] = item.bookId;
        }
        if (item.bookTitle) {
            dict[@"bookTitle"] = item.bookTitle;
        }
        dict[@"addedAt"] = @([item.addedAt timeIntervalSince1970]);
        if (item.lastReviewedAt) {
            dict[@"lastReviewedAt"] = @([item.lastReviewedAt timeIntervalSince1970]);
        }
        dict[@"reviewCount"] = @(item.reviewCount);
        dict[@"easeFactor"] = @(item.easeFactor);
        dict[@"interval"] = @(item.interval);
        dict[@"status"] = @(item.status);
        
        [jsonArray addObject:dict];
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        return @"[]";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)exportToAnki:(NSArray<XLVocabularyItem *> *)items {
    NSMutableString *tsv = [NSMutableString string];
    
    // Anki format: Front\tBack\tTags
    for (XLVocabularyItem *item in items) {
        NSString *front = item.sourceWord;
        NSString *back = item.targetWord;
        if (item.contextSentence) {
            back = [NSString stringWithFormat:@"%@\n\n%@", item.targetWord, item.contextSentence];
        }
        NSString *tags = @"xenolexia";
        if (item.bookTitle) {
            tags = [NSString stringWithFormat:@"%@ %@", tags, item.bookTitle];
        }
        
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
