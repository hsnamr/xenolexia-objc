//
//  XLStorageService.m
//  Xenolexia
//

#import "XLStorageService.h"
#import <sqlite3.h>
#import <SmallStep/SmallStep.h>

@interface XLStorageService ()

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic) sqlite3 *database;
@property (nonatomic, strong) SSFileSystem *fileSystem;

@end

@implementation XLStorageService

+ (instancetype)sharedService {
    static XLStorageService *sharedService = nil;
    if (sharedService == nil) {
        sharedService = [[self alloc] init];
    }
    return sharedService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Use SmallStep for cross-platform file system access
        _fileSystem = [SSFileSystem sharedFileSystem];
        NSString *documentsDirectory = [_fileSystem documentsDirectory];
        _databasePath = [documentsDirectory stringByAppendingPathComponent:@"xenolexia.db"];
    }
    return self;
}

- (void)initializeDatabaseWithCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    int result = sqlite3_open([self.databasePath UTF8String], &_database);
    if (result != SQLITE_OK) {
        if (completion) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to open database"
                                                                 forKey:NSLocalizedDescriptionKey];
            completion(NO, [NSError errorWithDomain:@"XLStorageService"
                                               code:result
                                           userInfo:userInfo]);
        }
        return;
    }
    
    // Create tables
    NSString *createBooksTable = @"CREATE TABLE IF NOT EXISTS books ("
                                 "id TEXT PRIMARY KEY, "
                                 "title TEXT NOT NULL, "
                                 "author TEXT, "
                                 "cover_path TEXT, "
                                 "file_path TEXT NOT NULL, "
                                 "format INTEGER, "
                                 "file_size INTEGER, "
                                 "added_at INTEGER NOT NULL, "
                                 "last_read_at INTEGER, "
                                 "source_language INTEGER, "
                                 "target_language INTEGER, "
                                 "proficiency_level INTEGER, "
                                 "word_density REAL, "
                                 "progress REAL, "
                                 "current_location TEXT, "
                                 "current_chapter INTEGER, "
                                 "total_chapters INTEGER, "
                                 "current_page INTEGER, "
                                 "total_pages INTEGER, "
                                 "reading_time_minutes INTEGER, "
                                 "source_url TEXT, "
                                 "is_downloaded INTEGER)";
    
    NSString *createVocabularyTable = @"CREATE TABLE IF NOT EXISTS vocabulary ("
                                       "id TEXT PRIMARY KEY, "
                                       "source_word TEXT NOT NULL, "
                                       "target_word TEXT NOT NULL, "
                                       "source_language INTEGER, "
                                       "target_language INTEGER, "
                                       "context_sentence TEXT, "
                                       "book_id TEXT, "
                                       "book_title TEXT, "
                                       "added_at INTEGER NOT NULL, "
                                       "last_reviewed_at INTEGER, "
                                       "review_count INTEGER, "
                                       "ease_factor REAL, "
                                       "interval INTEGER, "
                                       "status INTEGER)";
    
    char *errorMsg = NULL;
    if (sqlite3_exec(self.database, [createBooksTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        if (completion) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:errorMsg ?: "Unknown error"]
                                                                  forKey:NSLocalizedDescriptionKey];
            completion(NO, [NSError errorWithDomain:@"XLStorageService"
                                              code:1
                                          userInfo:userInfo]);
        }
        sqlite3_free(errorMsg);
        return;
    }
    
    if (sqlite3_exec(self.database, [createVocabularyTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"XLStorageService"
                                              code:2
                                          userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:errorMsg ?: "Unknown error"]}]);
        }
        sqlite3_free(errorMsg);
        return;
    }
    
    if (completion) {
        completion(YES, nil);
    }
}

- (void)saveBook:(XLBook *)book withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Implementation would serialize book to database
    // For now, return success
    if (completion) {
        completion(YES, nil);
    }
}

- (void)getBookWithId:(NSString *)bookId withCompletion:(void(^)(XLBook * _Nullable book, NSError * _Nullable error))completion {
    // Implementation would query database
    if (completion) {
        completion(nil, nil);
    }
}

- (void)getAllBooksWithCompletion:(void(^)(NSArray<XLBook *> * _Nullable books, NSError * _Nullable error))completion {
    // Implementation would query database
    if (completion) {
        completion([[NSArray alloc] init], nil);
    }
}

- (void)deleteBookWithId:(NSString *)bookId withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Implementation would delete from database
    if (completion) {
        completion(YES, nil);
    }
}

- (void)saveVocabularyItem:(XLVocabularyItem *)item withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Implementation would serialize item to database
    if (completion) {
        completion(YES, nil);
    }
}

- (void)getVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(XLVocabularyItem * _Nullable item, NSError * _Nullable error))completion {
    // Implementation would query database
    if (completion) {
        completion(nil, nil);
    }
}

- (void)getAllVocabularyItemsWithCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion {
    // Implementation would query database
    if (completion) {
        completion([[NSArray alloc] init], nil);
    }
}

- (void)deleteVocabularyItemWithId:(NSString *)itemId withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Implementation would delete from database
    if (completion) {
        completion(YES, nil);
    }
}

- (void)searchVocabularyWithQuery:(NSString *)query withCompletion:(void(^)(NSArray<XLVocabularyItem *> * _Nullable items, NSError * _Nullable error))completion {
    // Implementation would search database
    if (completion) {
        completion([[NSArray alloc] init], nil);
    }
}

- (void)dealloc {
    if (self.database) {
        sqlite3_close(self.database);
    }
}

@end
