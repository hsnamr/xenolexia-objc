//
//  XLStorageService.m
//  Xenolexia
//

#import "XLStorageService.h"
#import "XLStorageServiceDelegate.h"
#import "../Models/Language.h"
#import "../Models/Vocabulary.h"
#import "../Models/Reader.h"
#import "../../../SmallStep/SmallStep/Core/SSFileSystem.h"
#include "sm2.h"

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
- (XLVocabularyItem *)vocabularyItemFromStatement:(sqlite3_stmt *)stmt;
- (NSString *)formatStringForBookFormat:(XLBookFormat)format;
- (XLBookFormat)bookFormatForString:(NSString *)s;
- (XLReaderTheme)themeForString:(NSString *)s;
- (NSString *)stringForTheme:(XLReaderTheme)theme;
- (XLTextAlign)textAlignForString:(NSString *)s;
- (NSString *)stringForTextAlign:(XLTextAlign)align;
- (XLReadingSession *)readingSessionFromStatement:(sqlite3_stmt *)stmt;

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
    
    // Create tables (Xenolexia Core Spec 02-sql-schema: snake_case, TEXT for lang/status, INTEGER ms timestamps)
    NSString *createBooksTable = @"CREATE TABLE IF NOT EXISTS books ("
                                 "id TEXT PRIMARY KEY, "
                                 "title TEXT NOT NULL, "
                                 "author TEXT, "
                                 "cover_path TEXT, "
                                 "file_path TEXT NOT NULL, "
                                 "format TEXT NOT NULL, "
                                 "file_size INTEGER, "
                                 "added_at INTEGER NOT NULL, "
                                 "last_read_at INTEGER, "
                                 "source_lang TEXT NOT NULL, "
                                 "target_lang TEXT NOT NULL, "
                                 "proficiency TEXT NOT NULL, "
                                 "density REAL DEFAULT 0.3, "
                                 "progress REAL DEFAULT 0, "
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
                                       "source_lang TEXT NOT NULL, "
                                       "target_lang TEXT NOT NULL, "
                                       "context_sentence TEXT, "
                                       "book_id TEXT, "
                                       "book_title TEXT, "
                                       "added_at INTEGER NOT NULL, "
                                       "last_reviewed_at INTEGER, "
                                       "review_count INTEGER DEFAULT 0, "
                                       "ease_factor REAL DEFAULT 2.5, "
                                       "interval INTEGER DEFAULT 0, "
                                       "status TEXT DEFAULT 'new', "
                                       "FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE SET NULL)";
    
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
    
    // Spec 02-sql-schema: reading_sessions, preferences, word_list
    NSString *createSessionsTable = @"CREATE TABLE IF NOT EXISTS reading_sessions ("
        "id TEXT PRIMARY KEY, "
        "book_id TEXT NOT NULL, "
        "started_at INTEGER NOT NULL, "
        "ended_at INTEGER, "
        "pages_read INTEGER DEFAULT 0, "
        "words_revealed INTEGER DEFAULT 0, "
        "words_saved INTEGER DEFAULT 0, "
        "FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE)";
    NSString *createPreferencesTable = @"CREATE TABLE IF NOT EXISTS preferences ("
        "key TEXT PRIMARY KEY, "
        "value TEXT NOT NULL)";
    NSString *createWordListTable = @"CREATE TABLE IF NOT EXISTS word_list ("
        "id TEXT PRIMARY KEY, "
        "source_word TEXT NOT NULL, "
        "target_word TEXT NOT NULL, "
        "source_lang TEXT NOT NULL, "
        "target_lang TEXT NOT NULL, "
        "proficiency TEXT NOT NULL, "
        "frequency_rank INTEGER, "
        "part_of_speech TEXT, "
        "variants TEXT, "
        "pronunciation TEXT)";
    if (sqlite3_exec(_database, [createSessionsTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK ||
        sqlite3_exec(_database, [createPreferencesTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK ||
        sqlite3_exec(_database, [createWordListTable UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        if (errorMsg) sqlite3_free(errorMsg);
        // Non-fatal: continue so books/vocabulary still work
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
    
    NSString *sql = @"INSERT OR REPLACE INTO books (id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_lang, target_lang, proficiency, density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
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
    sqlite3_bind_text(stmt, 6, [[self formatStringForBookFormat:book.format] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(stmt, 7, book.fileSize);
    sqlite3_bind_int64(stmt, 8, (long long)([book.addedAt timeIntervalSince1970] * 1000));
    sqlite3_bind_int64(stmt, 9, book.lastReadAt ? (long long)([book.lastReadAt timeIntervalSince1970] * 1000) : 0);
    sqlite3_bind_text(stmt, 10, [[XLLanguageInfo codeStringForLanguage:book.languagePair.sourceLanguage] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 11, [[XLLanguageInfo codeStringForLanguage:book.languagePair.targetLanguage] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 12, [[XLLanguageInfo codeStringForProficiency:book.proficiencyLevel] UTF8String], -1, SQLITE_TRANSIENT);
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
    
    NSString *sql = @"SELECT id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_lang, target_lang, proficiency, density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded FROM books WHERE id = ?";
    
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
    
    NSString *sql = [NSString stringWithFormat:@"SELECT id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_lang, target_lang, proficiency, density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded FROM books ORDER BY %@ %@", dbSortField, order];
    
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
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self saveVocabularyItem:item delegate:delegate]; }
        return;
    }
    NSString *sql = @"INSERT OR REPLACE INTO vocabulary (id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didSaveVocabularyItem:withSuccess:error:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didSaveVocabularyItem:item withSuccess:NO error:err];
        }
        return;
    }
    long long addedMs = (long long)([item.addedAt timeIntervalSince1970] * 1000);
    long long lastRevMs = item.lastReviewedAt ? (long long)([item.lastReviewedAt timeIntervalSince1970] * 1000) : 0;
    sqlite3_bind_text(stmt, 1, [item.vocabularyId UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, [item.sourceWord UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, [item.targetWord UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 4, [[XLLanguageInfo codeStringForLanguage:item.sourceLanguage] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5, [[XLLanguageInfo codeStringForLanguage:item.targetLanguage] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 6, item.contextSentence ? [item.contextSentence UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 7, item.bookId ? [item.bookId UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 8, item.bookTitle ? [item.bookTitle UTF8String] : NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(stmt, 9, addedMs);
    sqlite3_bind_int64(stmt, 10, lastRevMs);
    sqlite3_bind_int(stmt, 11, (int)item.reviewCount);
    sqlite3_bind_double(stmt, 12, item.easeFactor);
    sqlite3_bind_int(stmt, 13, (int)item.interval);
    sqlite3_bind_text(stmt, 14, [[XLVocabularyItem codeStringForStatus:item.status] UTF8String], -1, SQLITE_TRANSIENT);
    int result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didSaveVocabularyItem:withSuccess:error:)]) {
        [delegate storageService:self didSaveVocabularyItem:item withSuccess:(result == SQLITE_DONE) error:(result == SQLITE_DONE ? nil : [NSError errorWithDomain:@"XLStorageService" code:result userInfo:nil])];
    }
}

- (void)getVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getVocabularyItemWithId:itemId delegate:delegate]; }
        return;
    }
    NSString *sql = @"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE id = ?";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetVocabularyItem:withError:)]) {
            [delegate storageService:self didGetVocabularyItem:nil withError:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    sqlite3_bind_text(stmt, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    XLVocabularyItem *item = nil;
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        item = [self vocabularyItemFromStatement:stmt];
    }
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didGetVocabularyItem:withError:)]) {
        [delegate storageService:self didGetVocabularyItem:item withError:nil];
    }
}

- (void)getAllVocabularyItemsWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getAllVocabularyItemsWithDelegate:delegate]; }
        return;
    }
    NSString *sql = @"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary ORDER BY added_at DESC";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetAllVocabularyItems:withError:)]) {
            [delegate storageService:self didGetAllVocabularyItems:@[] withError:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    NSMutableArray *items = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        XLVocabularyItem *item = [self vocabularyItemFromStatement:stmt];
        if (item) [items addObject:item];
    }
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didGetAllVocabularyItems:withError:)]) {
        [delegate storageService:self didGetAllVocabularyItems:[items copy] withError:nil];
    }
}

- (void)deleteVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self deleteVocabularyItemWithId:itemId delegate:delegate]; }
        return;
    }
    NSString *sql = @"DELETE FROM vocabulary WHERE id = ?";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didDeleteVocabularyItemWithId:withSuccess:error:)]) {
            [delegate storageService:self didDeleteVocabularyItemWithId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    sqlite3_bind_text(stmt, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    int result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didDeleteVocabularyItemWithId:withSuccess:error:)]) {
        [delegate storageService:self didDeleteVocabularyItemWithId:itemId withSuccess:(result == SQLITE_DONE) error:nil];
    }
}

- (void)searchVocabularyWithQuery:(NSString *)query delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self searchVocabularyWithQuery:query delegate:delegate]; }
        return;
    }
    NSString *sql = @"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE source_word LIKE ? OR target_word LIKE ? ORDER BY added_at DESC";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didSearchVocabulary:withError:)]) {
            [delegate storageService:self didSearchVocabulary:@[] withError:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    NSString *pattern = [NSString stringWithFormat:@"%%%@%%", query];
    sqlite3_bind_text(stmt, 1, [pattern UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, [pattern UTF8String], -1, SQLITE_TRANSIENT);
    NSMutableArray *items = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        XLVocabularyItem *item = [self vocabularyItemFromStatement:stmt];
        if (item) [items addObject:item];
    }
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didSearchVocabulary:withError:)]) {
        [delegate storageService:self didSearchVocabulary:[items copy] withError:nil];
    }
}

- (NSString *)formatStringForBookFormat:(XLBookFormat)format {
    switch (format) {
        case XLBookFormatEpub: return @"epub";
        case XLBookFormatFb2: return @"fb2";
        case XLBookFormatMobi: return @"mobi";
        case XLBookFormatTxt: return @"txt";
    }
    return @"epub";
}

- (XLBookFormat)bookFormatForString:(NSString *)s {
    NSString *lower = [s lowercaseString];
    if ([lower isEqualToString:@"fb2"]) return XLBookFormatFb2;
    if ([lower isEqualToString:@"mobi"]) return XLBookFormatMobi;
    if ([lower isEqualToString:@"txt"]) return XLBookFormatTxt;
    return XLBookFormatEpub;
}

- (XLReaderTheme)themeForString:(NSString *)s {
    NSString *lower = [s lowercaseString];
    if ([lower isEqualToString:@"dark"]) return XLReaderThemeDark;
    if ([lower isEqualToString:@"sepia"]) return XLReaderThemeSepia;
    return XLReaderThemeLight;
}

- (NSString *)stringForTheme:(XLReaderTheme)theme {
    switch (theme) {
        case XLReaderThemeDark: return @"dark";
        case XLReaderThemeSepia: return @"sepia";
        default: return @"light";
    }
}

- (XLTextAlign)textAlignForString:(NSString *)s {
    if ([[s lowercaseString] isEqualToString:@"justify"]) return XLTextAlignJustify;
    return XLTextAlignLeft;
}

- (NSString *)stringForTextAlign:(XLTextAlign)align {
    return (align == XLTextAlignJustify) ? @"justify" : @"left";
}

- (XLReadingSession *)readingSessionFromStatement:(sqlite3_stmt *)stmt {
    XLReadingSession *session = [[XLReadingSession alloc] init];
    const char *cid = (const char *)sqlite3_column_text(stmt, 0);
    session.sessionId = cid ? [NSString stringWithUTF8String:cid] : @"";
    const char *bid = (const char *)sqlite3_column_text(stmt, 1);
    session.bookId = bid ? [NSString stringWithUTF8String:bid] : @"";
    long long startedMs = sqlite3_column_int64(stmt, 2);
    session.startedAt = [NSDate dateWithTimeIntervalSince1970:startedMs / 1000.0];
    long long endedMs = sqlite3_column_int64(stmt, 3);
    session.endedAt = (endedMs > 0) ? [NSDate dateWithTimeIntervalSince1970:endedMs / 1000.0] : nil;
    session.pagesRead = sqlite3_column_int(stmt, 4);
    session.wordsRevealed = sqlite3_column_int(stmt, 5);
    session.wordsSaved = sqlite3_column_int(stmt, 6);
    if (session.endedAt && session.startedAt) {
        session.duration = [session.endedAt timeIntervalSinceDate:session.startedAt];
    }
    return session;
}

- (XLVocabularyItem *)vocabularyItemFromStatement:(sqlite3_stmt *)stmt {
    XLVocabularyItem *item = [[XLVocabularyItem alloc] init];
    const char *cid = (const char *)sqlite3_column_text(stmt, 0);
    item.vocabularyId = cid ? [NSString stringWithUTF8String:cid] : @"";
    const char *src = (const char *)sqlite3_column_text(stmt, 1);
    item.sourceWord = src ? [NSString stringWithUTF8String:src] : @"";
    const char *tgt = (const char *)sqlite3_column_text(stmt, 2);
    item.targetWord = tgt ? [NSString stringWithUTF8String:tgt] : @"";
    const char *sl = (const char *)sqlite3_column_text(stmt, 3);
    const char *tl = (const char *)sqlite3_column_text(stmt, 4);
    item.sourceLanguage = [XLLanguageInfo languageForCodeString:sl ? [NSString stringWithUTF8String:sl] : @"en"];
    item.targetLanguage = [XLLanguageInfo languageForCodeString:tl ? [NSString stringWithUTF8String:tl] : @"en"];
    const char *ctx = (const char *)sqlite3_column_text(stmt, 5);
    item.contextSentence = ctx ? [NSString stringWithUTF8String:ctx] : nil;
    const char *bid = (const char *)sqlite3_column_text(stmt, 6);
    item.bookId = bid ? [NSString stringWithUTF8String:bid] : nil;
    const char *bt = (const char *)sqlite3_column_text(stmt, 7);
    item.bookTitle = bt ? [NSString stringWithUTF8String:bt] : nil;
    long long addedMs = sqlite3_column_int64(stmt, 8);
    item.addedAt = [NSDate dateWithTimeIntervalSince1970:addedMs / 1000.0];
    long long lastRevMs = sqlite3_column_int64(stmt, 9);
    item.lastReviewedAt = lastRevMs > 0 ? [NSDate dateWithTimeIntervalSince1970:lastRevMs / 1000.0] : nil;
    item.reviewCount = sqlite3_column_int(stmt, 10);
    item.easeFactor = sqlite3_column_double(stmt, 11);
    item.interval = sqlite3_column_int(stmt, 12);
    const char *st = (const char *)sqlite3_column_text(stmt, 13);
    item.status = [XLVocabularyItem statusForCodeString:st ? [NSString stringWithUTF8String:st] : @"new"];
    return item;
}

- (void)getVocabularyDueForReviewWithLimit:(NSInteger)limit delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getVocabularyDueForReviewWithLimit:limit delegate:delegate]; }
        return;
    }
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *sql = @"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE status != 'learned' AND (last_reviewed_at IS NULL OR (last_reviewed_at + interval * 86400000) <= ?) ORDER BY last_reviewed_at ASC LIMIT ?";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetVocabularyDueForReview:withError:)]) {
            [delegate storageService:self didGetVocabularyDueForReview:@[] withError:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    sqlite3_bind_int64(stmt, 1, nowMs);
    sqlite3_bind_int(stmt, 2, (int)limit);
    NSMutableArray *items = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        XLVocabularyItem *item = [self vocabularyItemFromStatement:stmt];
        if (item) [items addObject:item];
    }
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didGetVocabularyDueForReview:withError:)]) {
        [delegate storageService:self didGetVocabularyDueForReview:[items copy] withError:nil];
    }
}

- (void)recordReviewForItemId:(NSString *)itemId quality:(NSInteger)quality delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self recordReviewForItemId:itemId quality:quality delegate:delegate]; }
        return;
    }
    NSString *selSql = @"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE id = ?";
    sqlite3_stmt *selStmt = NULL;
    if (sqlite3_prepare_v2(_database, [selSql UTF8String], -1, &selStmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    sqlite3_bind_text(selStmt, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    if (sqlite3_step(selStmt) != SQLITE_ROW) {
        sqlite3_finalize(selStmt);
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:2 userInfo:@{ NSLocalizedDescriptionKey: @"Item not found" }]];
        }
        return;
    }
    XLVocabularyItem *item = [self vocabularyItemFromStatement:selStmt];
    sqlite3_finalize(selStmt);
    if (!item) {
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:2 userInfo:nil]];
        }
        return;
    }
    /* Use shared C SM-2 from xenolexia-shared-c for identical behaviour with C# */
    xenolexia_sm2_state_t state = {
        .ease_factor = item.easeFactor,
        .interval = (int)item.interval,
        .review_count = item.reviewCount,
        .status = XENOLEXIA_SM2_NEW
    };
    xenolexia_sm2_step((int)quality, &state);
    NSInteger rc = state.review_count;
    double ef = state.ease_factor;
    NSInteger iv = state.interval;
    XLVocabularyStatus newStatus = item.status;
    switch (state.status) {
        case XENOLEXIA_SM2_LEARNING: newStatus = XLVocabularyStatusLearning; break;
        case XENOLEXIA_SM2_REVIEW:   newStatus = XLVocabularyStatusReview; break;
        case XENOLEXIA_SM2_LEARNED:  newStatus = XLVocabularyStatusLearned; break;
        default:                     newStatus = XLVocabularyStatusNew; break;
    }
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *upSql = @"UPDATE vocabulary SET last_reviewed_at = ?, review_count = ?, ease_factor = ?, interval = ?, status = ? WHERE id = ?";
    sqlite3_stmt *upStmt = NULL;
    if (sqlite3_prepare_v2(_database, [upSql UTF8String], -1, &upStmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:1 userInfo:nil]];
        }
        return;
    }
    sqlite3_bind_int64(upStmt, 1, nowMs);
    sqlite3_bind_int(upStmt, 2, (int)rc);
    sqlite3_bind_double(upStmt, 3, ef);
    sqlite3_bind_int(upStmt, 4, (int)iv);
    sqlite3_bind_text(upStmt, 5, [[XLVocabularyItem codeStringForStatus:newStatus] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(upStmt, 6, [itemId UTF8String], -1, SQLITE_TRANSIENT);
    int result = sqlite3_step(upStmt);
    sqlite3_finalize(upStmt);
    if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
        [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:(result == SQLITE_DONE) error:nil];
    }
}

- (void)getPreferencesWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getPreferencesWithDelegate:delegate]; }
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *sql = @"SELECT key, value FROM preferences";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetPreferences:withError:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didGetPreferences:nil withError:err];
        }
        return;
    }
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *k = (const char *)sqlite3_column_text(stmt, 0);
        const char *v = (const char *)sqlite3_column_text(stmt, 1);
        if (k && v) {
            [dict setObject:[NSString stringWithUTF8String:v] forKey:[NSString stringWithUTF8String:k]];
        }
    }
    sqlite3_finalize(stmt);

    NSString *(^get)(NSString *, NSString *) = ^(NSString *key, NSString *defaultValue) {
        NSString *v = [dict objectForKey:key];
        return v.length ? v : defaultValue;
    };
    XLUserPreferences *prefs = [[XLUserPreferences alloc] init];
    prefs.defaultSourceLanguage = [XLLanguageInfo languageForCodeString:get(@"source_lang", @"en")];
    prefs.defaultTargetLanguage = [XLLanguageInfo languageForCodeString:get(@"target_lang", @"es")];
    prefs.defaultProficiencyLevel = [XLLanguageInfo proficiencyForCodeString:get(@"proficiency", @"beginner")];
    prefs.defaultWordDensity = [get(@"word_density", @"0.3") doubleValue];
    if (prefs.defaultWordDensity <= 0) prefs.defaultWordDensity = 0.3;
    prefs.readerSettings = [[XLReaderSettings alloc] init];
    prefs.readerSettings.theme = [self themeForString:get(@"reader_theme", @"light")];
    prefs.readerSettings.fontFamily = get(@"reader_font_family", @"System");
    prefs.readerSettings.fontSize = [get(@"reader_font_size", @"16") doubleValue];
    if (prefs.readerSettings.fontSize <= 0) prefs.readerSettings.fontSize = 16;
    prefs.readerSettings.lineHeight = [get(@"reader_line_height", @"1.6") doubleValue];
    if (prefs.readerSettings.lineHeight <= 0) prefs.readerSettings.lineHeight = 1.6;
    prefs.readerSettings.marginHorizontal = [get(@"reader_margin_horizontal", @"24") doubleValue];
    prefs.readerSettings.marginVertical = [get(@"reader_margin_vertical", @"16") doubleValue];
    prefs.readerSettings.textAlign = [self textAlignForString:get(@"reader_text_align", @"left")];
    prefs.readerSettings.brightness = [get(@"reader_brightness", @"1") doubleValue];
    if (prefs.readerSettings.brightness <= 0) prefs.readerSettings.brightness = 1.0;
    prefs.hasCompletedOnboarding = [get(@"onboarding_done", @"false") isEqualToString:@"true"];
    prefs.notificationsEnabled = [get(@"notifications_enabled", @"false") isEqualToString:@"true"];
    prefs.dailyGoal = (NSInteger)[get(@"daily_goal", @"30") integerValue];
    if (prefs.dailyGoal <= 0) prefs.dailyGoal = 30;
    if ([delegate respondsToSelector:@selector(storageService:didGetPreferences:withError:)]) {
        [delegate storageService:self didGetPreferences:prefs withError:nil];
    }
}

- (void)savePreferences:(XLUserPreferences *)prefs delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self savePreferences:prefs delegate:delegate]; }
        return;
    }
    NSArray *pairs = @[
        @[ @"source_lang", [XLLanguageInfo codeStringForLanguage:prefs.defaultSourceLanguage] ],
        @[ @"target_lang", [XLLanguageInfo codeStringForLanguage:prefs.defaultTargetLanguage] ],
        @[ @"proficiency", [XLLanguageInfo codeStringForProficiency:prefs.defaultProficiencyLevel] ],
        @[ @"word_density", [NSString stringWithFormat:@"%.17g", prefs.defaultWordDensity] ],
        @[ @"reader_theme", [self stringForTheme:prefs.readerSettings.theme] ],
        @[ @"reader_font_family", prefs.readerSettings.fontFamily ?: @"System" ],
        @[ @"reader_font_size", [NSString stringWithFormat:@"%.17g", prefs.readerSettings.fontSize] ],
        @[ @"reader_line_height", [NSString stringWithFormat:@"%.17g", prefs.readerSettings.lineHeight] ],
        @[ @"reader_margin_horizontal", [NSString stringWithFormat:@"%.17g", prefs.readerSettings.marginHorizontal] ],
        @[ @"reader_margin_vertical", [NSString stringWithFormat:@"%.17g", prefs.readerSettings.marginVertical] ],
        @[ @"reader_text_align", [self stringForTextAlign:prefs.readerSettings.textAlign] ],
        @[ @"reader_brightness", [NSString stringWithFormat:@"%.17g", prefs.readerSettings.brightness] ],
        @[ @"onboarding_done", prefs.hasCompletedOnboarding ? @"true" : @"false" ],
        @[ @"notifications_enabled", prefs.notificationsEnabled ? @"true" : @"false" ],
        @[ @"daily_goal", [NSString stringWithFormat:@"%ld", (long)prefs.dailyGoal] ]
    ];
    NSString *sql = @"INSERT OR REPLACE INTO preferences (key, value) VALUES (?, ?)";
    for (NSArray *kv in pairs) {
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            if ([delegate respondsToSelector:@selector(storageService:didSavePreferencesWithSuccess:error:)]) {
                NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
                [delegate storageService:self didSavePreferencesWithSuccess:NO error:err];
            }
            return;
        }
        sqlite3_bind_text(stmt, 1, [[kv objectAtIndex:0] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [[kv objectAtIndex:1] UTF8String], -1, SQLITE_TRANSIENT);
        int result = sqlite3_step(stmt);
        sqlite3_finalize(stmt);
        if (result != SQLITE_DONE) {
            if ([delegate respondsToSelector:@selector(storageService:didSavePreferencesWithSuccess:error:)]) {
                NSError *err = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
                [delegate storageService:self didSavePreferencesWithSuccess:NO error:err];
            }
            return;
        }
    }
    if ([delegate respondsToSelector:@selector(storageService:didSavePreferencesWithSuccess:error:)]) {
        [delegate storageService:self didSavePreferencesWithSuccess:YES error:nil];
    }
}

- (void)startReadingSessionForBookId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self startReadingSessionForBookId:bookId delegate:delegate]; }
        return;
    }
    NSString *sessionId = [[NSUUID UUID] UUIDString];
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *sql = @"INSERT INTO reading_sessions (id, book_id, started_at, ended_at, pages_read, words_revealed, words_saved) VALUES (?, ?, ?, NULL, 0, 0, 0)";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didStartReadingSessionWithId:error:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didStartReadingSessionWithId:nil error:err];
        }
        return;
    }
    sqlite3_bind_text(stmt, 1, [sessionId UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, [bookId UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(stmt, 3, nowMs);
    int result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (result != SQLITE_DONE) {
        if ([delegate respondsToSelector:@selector(storageService:didStartReadingSessionWithId:error:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:result userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didStartReadingSessionWithId:nil error:err];
        }
        return;
    }
    if ([delegate respondsToSelector:@selector(storageService:didStartReadingSessionWithId:error:)]) {
        [delegate storageService:self didStartReadingSessionWithId:sessionId error:nil];
    }
}

- (void)endReadingSessionWithId:(NSString *)sessionId wordsRevealed:(NSInteger)wordsRevealed wordsSaved:(NSInteger)wordsSaved delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self endReadingSessionWithId:sessionId wordsRevealed:wordsRevealed wordsSaved:wordsSaved delegate:delegate]; }
        return;
    }
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *sql = @"UPDATE reading_sessions SET ended_at = ?, words_revealed = ?, words_saved = ? WHERE id = ?";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didEndReadingSessionWithSuccess:error:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didEndReadingSessionWithSuccess:NO error:err];
        }
        return;
    }
    sqlite3_bind_int64(stmt, 1, nowMs);
    sqlite3_bind_int(stmt, 2, (int)wordsRevealed);
    sqlite3_bind_int(stmt, 3, (int)wordsSaved);
    sqlite3_bind_text(stmt, 4, [sessionId UTF8String], -1, SQLITE_TRANSIENT);
    int result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didEndReadingSessionWithSuccess:error:)]) {
        [delegate storageService:self didEndReadingSessionWithSuccess:(result == SQLITE_DONE) error:nil];
    }
}

- (void)getActiveSessionForBookId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getActiveSessionForBookId:bookId delegate:delegate]; }
        return;
    }
    NSString *sql = @"SELECT id, book_id, started_at, ended_at, pages_read, words_revealed, words_saved FROM reading_sessions WHERE book_id = ? AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetActiveSession:withError:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didGetActiveSession:nil withError:err];
        }
        return;
    }
    sqlite3_bind_text(stmt, 1, [bookId UTF8String], -1, SQLITE_TRANSIENT);
    XLReadingSession *session = nil;
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        session = [self readingSessionFromStatement:stmt];
    }
    sqlite3_finalize(stmt);
    if ([delegate respondsToSelector:@selector(storageService:didGetActiveSession:withError:)]) {
        [delegate storageService:self didGetActiveSession:session withError:nil];
    }
}

- (void)getReadingStatsWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getReadingStatsWithDelegate:delegate]; }
        return;
    }
    NSMutableSet *bookIds = [NSMutableSet set];
    NSMutableArray *sessionDates = [NSMutableArray array];
    NSInteger totalSeconds = 0;
    NSInteger sessionCount = 0;
    NSInteger wordsRevealedToday = 0;
    NSInteger wordsSavedToday = 0;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    NSInteger todayYear = 0, todayMonth = 0, todayDay = 0;
    [cal getEra:nil year:&todayYear month:&todayMonth day:&todayDay fromDate:today];

    NSString *sql = @"SELECT book_id, started_at, ended_at, words_revealed, words_saved FROM reading_sessions WHERE ended_at IS NOT NULL";
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
        if ([delegate respondsToSelector:@selector(storageService:didGetReadingStats:withError:)]) {
            NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:sqlite3_errmsg(_database)] }];
            [delegate storageService:self didGetReadingStats:nil withError:err];
        }
        return;
    }
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        const char *bid = (const char *)sqlite3_column_text(stmt, 0);
        NSString *bookId = bid ? [NSString stringWithUTF8String:bid] : @"";
        long long startedMs = sqlite3_column_int64(stmt, 1);
        long long endedMs = sqlite3_column_int64(stmt, 2);
        NSInteger wr = sqlite3_column_int(stmt, 3);
        NSInteger ws = sqlite3_column_int(stmt, 4);
        [bookIds addObject:bookId];
        totalSeconds += (NSInteger)((endedMs - startedMs) / 1000);
        sessionCount++;
        NSDate *endedDate = [NSDate dateWithTimeIntervalSince1970:endedMs / 1000.0];
        [sessionDates addObject:endedDate];
        NSDateComponents *comp = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:endedDate];
        if ([comp year] == todayYear && [comp month] == todayMonth && [comp day] == todayDay) {
            wordsRevealedToday += wr;
            wordsSavedToday += ws;
        }
    }
    sqlite3_finalize(stmt);

    NSInteger totalWordsLearned = 0;
    NSString *countSql = @"SELECT COUNT(*) FROM vocabulary WHERE status = 'learned'";
    sqlite3_stmt *countStmt = NULL;
    if (sqlite3_prepare_v2(_database, [countSql UTF8String], -1, &countStmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(countStmt) == SQLITE_ROW) {
            totalWordsLearned = sqlite3_column_int(countStmt, 0);
        }
        sqlite3_finalize(countStmt);
    }

    NSMutableSet *uniqueDates = [NSMutableSet set];
    for (NSDate *d in sessionDates) {
        NSDateComponents *c = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:d];
        NSDate *dayStart = [cal dateFromComponents:c];
        [uniqueDates addObject:dayStart];
    }
    NSArray *sortedDates = [[uniqueDates allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSSet *dateSet = [NSSet setWithArray:sortedDates];
    NSInteger currentStreak = 0;
    if ([sortedDates count] > 0) {
        NSDate *mostRecent = [sortedDates lastObject];
        NSDate *d = mostRecent;
        while ([dateSet containsObject:d]) {
            currentStreak++;
            d = [cal dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:d options:0];
        }
    }

    NSInteger longestStreak = 1;
    if ([sortedDates count] > 0) {
        NSInteger run = 1;
        for (NSInteger i = 1; i < (NSInteger)[sortedDates count]; i++) {
            NSDate *prev = [sortedDates objectAtIndex:i - 1];
            NSDate *cur = [sortedDates objectAtIndex:i];
            NSInteger diff = (NSInteger)([cur timeIntervalSinceDate:prev] / (24 * 3600));
            if (diff == 1) {
                run++;
            } else {
                run = 1;
            }
            if (run > longestStreak) longestStreak = run;
        }
    }

    NSTimeInterval avgDuration = (sessionCount > 0) ? (NSTimeInterval)totalSeconds / (NSTimeInterval)sessionCount : 0;
    XLReadingStats *stats = [[XLReadingStats alloc] init];
    stats.totalBooksRead = [bookIds count];
    stats.totalReadingTime = totalSeconds;
    stats.totalWordsLearned = totalWordsLearned;
    stats.currentStreak = currentStreak;
    stats.longestStreak = longestStreak;
    stats.averageSessionDuration = avgDuration;
    stats.wordsRevealedToday = wordsRevealedToday;
    stats.wordsSavedToday = wordsSavedToday;
    if ([delegate respondsToSelector:@selector(storageService:didGetReadingStats:withError:)]) {
        [delegate storageService:self didGetReadingStats:stats withError:nil];
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
    
    const char *formatStr = (const char *)sqlite3_column_text(stmt, 5);
    book.format = [self bookFormatForString:formatStr ? [NSString stringWithUTF8String:formatStr] : @"epub"];
    book.fileSize = sqlite3_column_int64(stmt, 6);
    
    long long addedAtMs = sqlite3_column_int64(stmt, 7);
    book.addedAt = [NSDate dateWithTimeIntervalSince1970:addedAtMs / 1000.0];
    
    long long lastReadAtMs = sqlite3_column_int64(stmt, 8);
    book.lastReadAt = lastReadAtMs > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadAtMs / 1000.0] : nil;
    
    const char *srcLangStr = (const char *)sqlite3_column_text(stmt, 9);
    const char *tgtLangStr = (const char *)sqlite3_column_text(stmt, 10);
    XLLanguage sourceLang = [XLLanguageInfo languageForCodeString:srcLangStr ? [NSString stringWithUTF8String:srcLangStr] : @"en"];
    XLLanguage targetLang = [XLLanguageInfo languageForCodeString:tgtLangStr ? [NSString stringWithUTF8String:tgtLangStr] : @"en"];
    book.languagePair = [XLLanguagePair pairWithSource:sourceLang target:targetLang];
    
    const char *profStr = (const char *)sqlite3_column_text(stmt, 11);
    book.proficiencyLevel = [XLLanguageInfo proficiencyForCodeString:profStr ? [NSString stringWithUTF8String:profStr] : @"beginner"];
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
