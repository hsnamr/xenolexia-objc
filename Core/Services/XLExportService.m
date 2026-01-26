//
//  XLExportService.m
//  Xenolexia
//

#import "XLExportService.h"
#import "../../../SmallStep/SmallStep/Core/SSFileSystem.h"

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
    NSMutableString *csv = [[NSMutableString alloc] init];
    
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
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:item.vocabularyId forKey:@"id"];
        [dict setObject:item.sourceWord forKey:@"sourceWord"];
        [dict setObject:item.targetWord forKey:@"targetWord"];
        [dict setObject:[NSNumber numberWithInteger:item.sourceLanguage] forKey:@"sourceLanguage"];
        [dict setObject:[NSNumber numberWithInteger:item.targetLanguage] forKey:@"targetLanguage"];
        if (item.contextSentence) {
            [dict setObject:item.contextSentence forKey:@"contextSentence"];
        }
        if (item.bookId) {
            [dict setObject:item.bookId forKey:@"bookId"];
        }
        if (item.bookTitle) {
            [dict setObject:item.bookTitle forKey:@"bookTitle"];
        }
        [dict setObject:[NSNumber numberWithDouble:[item.addedAt timeIntervalSince1970]] forKey:@"addedAt"];
        if (item.lastReviewedAt) {
            [dict setObject:[NSNumber numberWithDouble:[item.lastReviewedAt timeIntervalSince1970]] forKey:@"lastReviewedAt"];
        }
        [dict setObject:[NSNumber numberWithInteger:item.reviewCount] forKey:@"reviewCount"];
        [dict setObject:[NSNumber numberWithDouble:item.easeFactor] forKey:@"easeFactor"];
        [dict setObject:[NSNumber numberWithInteger:item.interval] forKey:@"interval"];
        [dict setObject:[NSNumber numberWithInteger:item.status] forKey:@"status"];
        
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

- (NSString *)exportToAnki:(NSArray *)items {
    NSMutableString *tsv = [[NSMutableString alloc] init];
    
    // Anki format: Front\tBack\tTags
    NSEnumerator *enumerator = [items objectEnumerator];
    XLVocabularyItem *item;
    while ((item = [enumerator nextObject])) {
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
