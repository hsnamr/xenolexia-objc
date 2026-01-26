//
//  XLStorageService.m
//  Xenolexia
//

#import "XLStorageService.h"
#import "XLStorageServiceDelegate.h"
#import "../../../SmallStep/SmallStep/Core/SSFileSystem.h"

// SQLite3 declarations (minimal interface for GNUStep compatibility)
// Note: Install libsqlite3-dev package for full sqlite3.h header
#ifndef SQLITE_OK
#define SQLITE_OK           0
#define SQLITE_DONE        101
#define SQLITE_ROW         100
#define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
struct sqlite3;
struct sqlite3_stmt;
typedef struct sqlite3 sqlite3;
typedef struct sqlite3_stmt sqlite3_stmt;
typedef void (*sqlite3_destructor_type)(void*);
int sqlite3_open(const char *filename, struct sqlite3 **ppDb);
int sqlite3_close(struct sqlite3 *db);
int sqlite3_prepare_v2(struct sqlite3 *db, const char *zSql, int nByte, struct sqlite3_stmt **ppStmt, const char **pzTail);
int sqlite3_step(struct sqlite3_stmt *pStmt);
int sqlite3_finalize(struct sqlite3_stmt *pStmt);
int sqlite3_bind_text(struct sqlite3_stmt *pStmt, int i, const char *zData, int nData, void (*xDel)(void*));
int sqlite3_bind_int(struct sqlite3_stmt *pStmt, int i, int value);
int sqlite3_bind_int64(struct sqlite3_stmt *pStmt, int i, long long value);
int sqlite3_bind_double(struct sqlite3_stmt *pStmt, int i, double value);
const unsigned char *sqlite3_column_text(struct sqlite3_stmt *pStmt, int iCol);
int sqlite3_column_int(struct sqlite3_stmt *pStmt, int iCol);
long long sqlite3_column_int64(struct sqlite3_stmt *pStmt, int iCol);
double sqlite3_column_double(struct sqlite3_stmt *pStmt, int iCol);
const char *sqlite3_errmsg(struct sqlite3 *db);
int sqlite3_exec(struct sqlite3 *db, const char *sql, int (*callback)(void*,int,char**,char**), void *arg, char **errmsg);
void sqlite3_free(void *p);
#endif

@interface XLStorageService ()

- (XLBook *)bookFromStatement:(sqlite3_stmt *)stmt;

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
        _databasePath = [[documentsDirectory stringByAppendingPathComponent:@"xenolexia.db"] retain];
    }
    return self;
}

- (void)initializeDatabaseWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    int result = sqlite3_open([_databasePath UTF8String], &_database);
    if (result != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to open database"
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService"
                                               code:result
                                           userInfo:userInfo];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
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
    if (sqlite3_exec(_database, [createBooksTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:errorMsg ?: "Unknown error"]
                                                                  forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService"
                                              code:1
                                          userInfo:userInfo];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
        }
        sqlite3_free(errorMsg);
        return;
    }
    
    if (sqlite3_exec(_database, [createVocabularyTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:errorMsg ?: "Unknown error"]
                                                                  forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService"
                                              code:2
                                          userInfo:userInfo];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
        }
        sqlite3_free(errorMsg);
        return;
    }
    
    if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
        [delegate storageService:self didInitializeDatabaseWithSuccess:YES error:nil];
    }
}

- (void)saveBook:(XLBook *)book delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        // Retry after initialization
        if (_database) {
            [self saveBook:book delegate:delegate];
        }
        return;
    }
    
    NSString *sql = @"INSERT OR REPLACE INTO books (id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_language, target_language, proficiency_level, word_density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didSaveBook:withSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to prepare statement: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didSaveBook:book withSuccess:NO error:error];
        }
        return;
    }
    
    sqlite3_bind_text(stmt, 1, [book.bookId UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, [book.title UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, [book.author UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4, book.coverPath ? [book.coverPath UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5, [book.filePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 6, (int)book.format);
    sqlite3_bind_int64(stmt, 7, book.fileSize);
    sqlite3_bind_int64(stmt, 8, (long long)[book.addedAt timeIntervalSince1970]);
    sqlite3_bind_int64(stmt, 9, book.lastReadAt ? (long long)[book.lastReadAt timeIntervalSince1970] : 0);
    sqlite3_bind_int(stmt, 10, (int)book.languagePair.sourceLanguage);
    sqlite3_bind_int(stmt, 11, (int)book.languagePair.targetLanguage);
    sqlite3_bind_int(stmt, 12, (int)book.proficiencyLevel);
    sqlite3_bind_double(stmt, 13, book.wordDensity);
    sqlite3_bind_double(stmt, 14, book.progress);
    sqlite3_bind_text(stmt, 15, book.currentLocation ? [book.currentLocation UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 16, (int)book.currentChapter);
    sqlite3_bind_int(stmt, 17, (int)book.totalChapters);
    sqlite3_bind_int(stmt, 18, (int)book.currentPage);
    sqlite3_bind_int(stmt, 19, (int)book.totalPages);
    sqlite3_bind_int(stmt, 20, (int)book.readingTimeMinutes);
    sqlite3_bind_text(stmt, 21, book.sourceUrl ? [book.sourceUrl UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 22, book.isDownloaded ? 1 : 0);
    
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    
    if (result != SQLITE_DONE) {
        if ([delegate respondsToSelector:@selector(storageService:didSaveBook:withSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to save book: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didSaveBook:book withSuccess:NO error:error];
        }
        return;
    }
    
    if ([delegate respondsToSelector:@selector(storageService:didSaveBook:withSuccess:error:)]) {
        [delegate storageService:self didSaveBook:book withSuccess:YES error:nil];
    }
}

- (void)getBookWithId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        // Retry after initialization
        if (_database) {
            [self getBookWithId:bookId delegate:delegate];
        }
        return;
    }
    
    NSString *sql = @"SELECT id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_language, target_language, proficiency_level, word_density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded FROM books WHERE id = ?";
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetBook:withError:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to prepare statement: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didGetBook:nil withError:error];
        }
        return;
    }
    
    sqlite3_bind_text(stmt, 1, [bookId UTF8String], -1, SQLITE_TRANSIENT);
    
    result = sqlite3_step(stmt);
    XLBook *book = nil;
    
    if (result == SQLITE_ROW) {
        book = [self bookFromStatement:stmt];
    }
    
    sqlite3_finalize(stmt);
    
    if ([delegate respondsToSelector:@selector(storageService:didGetBook:withError:)]) {
        [delegate storageService:self didGetBook:book withError:nil];
    }
}

- (void)getAllBooksWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    [self getAllBooksWithSortBy:@"lastReadAt" order:@"DESC" delegate:delegate];
}

- (void)getAllBooksWithSortBy:(NSString *)sortBy order:(NSString *)order delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        // Retry after initialization
        if (_database) {
            [self getAllBooksWithSortBy:sortBy order:order delegate:delegate];
        }
        return;
    }
    
    // Map sort field names
    NSDictionary *sortFieldMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"last_read_at", @"lastReadAt",
                                   @"added_at", @"addedAt",
                                   @"title", @"title",
                                   @"author", @"author",
                                   @"progress", @"progress",
                                   nil];
    NSString *dbSortField = [sortFieldMap objectForKey:sortBy];
    if (!dbSortField) {
        dbSortField = @"last_read_at";
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_language, target_language, proficiency_level, word_density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded FROM books ORDER BY %@ %@", dbSortField, order];
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetAllBooks:withError:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to prepare statement: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didGetAllBooks:[[NSArray alloc] init] withError:error];
        }
        return;
    }
    
    NSMutableArray *books = [NSMutableArray array];
    while ((result = sqlite3_step(stmt)) == SQLITE_ROW) {
        XLBook *book = [self bookFromStatement:stmt];
        if (book) {
            [books addObject:book];
        }
    }
    
    sqlite3_finalize(stmt);
    
    if ([delegate respondsToSelector:@selector(storageService:didGetAllBooks:withError:)]) {
        [delegate storageService:self didGetAllBooks:books withError:nil];
    }
}

- (void)deleteBookWithId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        // Retry after initialization
        if (_database) {
            [self deleteBookWithId:bookId delegate:delegate];
        }
        return;
    }
    
    NSString *sql = @"DELETE FROM books WHERE id = ?";
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didDeleteBookWithId:withSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to prepare statement: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didDeleteBookWithId:bookId withSuccess:NO error:error];
        }
        return;
    }
    
    sqlite3_bind_text(stmt, 1, [bookId UTF8String], -1, SQLITE_TRANSIENT);
    
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    
    if (result != SQLITE_DONE) {
        if ([delegate respondsToSelector:@selector(storageService:didDeleteBookWithId:withSuccess:error:)]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to delete book: %s", sqlite3_errmsg(_database)]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:userInfo];
            [delegate storageService:self didDeleteBookWithId:bookId withSuccess:NO error:error];
        }
        return;
    }
    
    if ([delegate respondsToSelector:@selector(storageService:didDeleteBookWithId:withSuccess:error:)]) {
        [delegate storageService:self didDeleteBookWithId:bookId withSuccess:YES error:nil];
    }
}

- (void)saveVocabularyItem:(XLVocabularyItem *)item delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    // Implementation would serialize item to database
    if ([delegate respondsToSelector:@selector(storageService:didSaveVocabularyItem:withSuccess:error:)]) {
        [delegate storageService:self didSaveVocabularyItem:item withSuccess:YES error:nil];
    }
}

- (void)getVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    // Implementation would query database
    if ([delegate respondsToSelector:@selector(storageService:didGetVocabularyItem:withError:)]) {
        [delegate storageService:self didGetVocabularyItem:nil withError:nil];
    }
}

- (void)getAllVocabularyItemsWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    // Implementation would query database
    if ([delegate respondsToSelector:@selector(storageService:didGetAllVocabularyItems:withError:)]) {
        [delegate storageService:self didGetAllVocabularyItems:[[NSArray alloc] init] withError:nil];
    }
}

- (void)deleteVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    // Implementation would delete from database
    if ([delegate respondsToSelector:@selector(storageService:didDeleteVocabularyItemWithId:withSuccess:error:)]) {
        [delegate storageService:self didDeleteVocabularyItemWithId:itemId withSuccess:YES error:nil];
    }
}

- (void)searchVocabularyWithQuery:(NSString *)query delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    // Implementation would search database
    if ([delegate respondsToSelector:@selector(storageService:didSearchVocabulary:withError:)]) {
        [delegate storageService:self didSearchVocabulary:[[NSArray alloc] init] withError:nil];
    }
}

- (XLBook *)bookFromStatement:(sqlite3_stmt *)stmt {
    XLBook *book = [[XLBook alloc] init];
    
    const char *bookIdStr = (const char *)sqlite3_column_text(stmt, 0);
    book.bookId = bookIdStr ? [NSString stringWithUTF8String:bookIdStr] : @"";
    
    const char *titleStr = (const char *)sqlite3_column_text(stmt, 1);
    book.title = titleStr ? [NSString stringWithUTF8String:titleStr] : @"";
    
    const char *authorStr = (const char *)sqlite3_column_text(stmt, 2);
    book.author = authorStr ? [NSString stringWithUTF8String:authorStr] : @"";
    
    const char *coverPathStr = (const char *)sqlite3_column_text(stmt, 3);
    book.coverPath = coverPathStr ? [NSString stringWithUTF8String:coverPathStr] : nil;
    
    const char *filePathStr = (const char *)sqlite3_column_text(stmt, 4);
    book.filePath = filePathStr ? [NSString stringWithUTF8String:filePathStr] : @"";
    
    book.format = (XLBookFormat)sqlite3_column_int(stmt, 5);
    book.fileSize = sqlite3_column_int64(stmt, 6);
    
    long long addedAtTimestamp = sqlite3_column_int64(stmt, 7);
    book.addedAt = [NSDate dateWithTimeIntervalSince1970:addedAtTimestamp];
    
    long long lastReadAtTimestamp = sqlite3_column_int64(stmt, 8);
    book.lastReadAt = lastReadAtTimestamp > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadAtTimestamp] : nil;
    
    XLLanguage sourceLang = (XLLanguage)sqlite3_column_int(stmt, 9);
    XLLanguage targetLang = (XLLanguage)sqlite3_column_int(stmt, 10);
    book.languagePair = [XLLanguagePair pairWithSource:sourceLang target:targetLang];
    
    book.proficiencyLevel = (XLProficiencyLevel)sqlite3_column_int(stmt, 11);
    book.wordDensity = sqlite3_column_double(stmt, 12);
    book.progress = sqlite3_column_double(stmt, 13);
    
    const char *currentLocationStr = (const char *)sqlite3_column_text(stmt, 14);
    book.currentLocation = currentLocationStr ? [NSString stringWithUTF8String:currentLocationStr] : nil;
    
    book.currentChapter = sqlite3_column_int(stmt, 15);
    book.totalChapters = sqlite3_column_int(stmt, 16);
    book.currentPage = sqlite3_column_int(stmt, 17);
    book.totalPages = sqlite3_column_int(stmt, 18);
    book.readingTimeMinutes = sqlite3_column_int(stmt, 19);
    
    const char *sourceUrlStr = (const char *)sqlite3_column_text(stmt, 20);
    book.sourceUrl = sourceUrlStr ? [NSString stringWithUTF8String:sourceUrlStr] : nil;
    
    book.isDownloaded = sqlite3_column_int(stmt, 21) != 0;
    
    return book;
}

- (void)dealloc {
    if (_database) {
        sqlite3_close(_database);
    }
    if (_databasePath) {
        [_databasePath release];
    }
    if (_fileSystem) {
        [_fileSystem release];
    }
    [super dealloc];
}

@end
