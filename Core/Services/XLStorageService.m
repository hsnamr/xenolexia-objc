//
//  XLStorageService.m
//  Xenolexia
//

#import "XLStorageService.h"
#import "XLStorageServiceDelegate.h"
#import "../Models/Language.h"
#import "../Models/Vocabulary.h"
#import "../Models/Reader.h"
#import "SSFileSystem.h"
#import "../Native/XLSm2.h"
#import "FMDatabase.h"
#import "FMResultSet.h"

@interface XLStorageService ()

- (XLBook *)bookFromResultSet:(FMResultSet *)rs;
- (XLVocabularyItem *)vocabularyItemFromResultSet:(FMResultSet *)rs;
- (NSString *)formatStringForBookFormat:(XLBookFormat)format;
- (XLBookFormat)bookFormatForString:(NSString *)s;
- (XLReaderTheme)themeForString:(NSString *)s;
- (NSString *)stringForTheme:(XLReaderTheme)theme;
- (XLTextAlign)textAlignForString:(NSString *)s;
- (NSString *)stringForTextAlign:(XLTextAlign)align;
- (XLReadingSession *)readingSessionFromResultSet:(FMResultSet *)rs;

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
    
    if (_database) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            [delegate storageService:self didInitializeDatabaseWithSuccess:YES error:nil];
        }
        return;
    }
    _database = [[FMDatabase alloc] initWithPath:_databasePath];
    if (![_database open]) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSString *msg = [_database lastErrorMessage] ?: @"Failed to open database";
            NSError *error = [NSError errorWithDomain:@"XLStorageService"
                                                code:[_database lastErrorCode]
                                            userInfo:@{ NSLocalizedDescriptionKey: msg }];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
        }
        [_database release];
        _database = nil;
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
    
    if (![_database executeUpdate:createBooksTable]) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:1
                userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Unknown error" }];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
        }
        return;
    }
    if (![_database executeUpdate:createVocabularyTable]) {
        if ([delegate respondsToSelector:@selector(storageService:didInitializeDatabaseWithSuccess:error:)]) {
            NSError *error = [NSError errorWithDomain:@"XLStorageService" code:2
                userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Unknown error" }];
            [delegate storageService:self didInitializeDatabaseWithSuccess:NO error:error];
        }
        return;
    }
    
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
    [_database executeUpdate:createSessionsTable];
    [_database executeUpdate:createPreferencesTable];
    [_database executeUpdate:createWordListTable];
    // Non-fatal: continue so books/vocabulary still work
    
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
    
    long long addedMs = (long long)([book.addedAt timeIntervalSince1970] * 1000);
    long long lastReadMs = book.lastReadAt ? (long long)([book.lastReadAt timeIntervalSince1970] * 1000) : 0;
    BOOL ok = [_database executeUpdate:@"INSERT OR REPLACE INTO books (id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_lang, target_lang, proficiency, density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        book.bookId,
        book.title,
        book.author ?: [NSNull null],
        book.coverPath ?: [NSNull null],
        book.filePath,
        [self formatStringForBookFormat:book.format],
        [NSNumber numberWithLongLong:book.fileSize],
        [NSNumber numberWithLongLong:addedMs],
        [NSNumber numberWithLongLong:lastReadMs],
        [XLLanguageInfo codeStringForLanguage:book.languagePair.sourceLanguage],
        [XLLanguageInfo codeStringForLanguage:book.languagePair.targetLanguage],
        [XLLanguageInfo codeStringForProficiency:book.proficiencyLevel],
        [NSNumber numberWithDouble:book.wordDensity],
        [NSNumber numberWithDouble:book.progress],
        book.currentLocation ?: [NSNull null],
        [NSNumber numberWithInt:(int)book.currentChapter],
        [NSNumber numberWithInt:(int)book.totalChapters],
        [NSNumber numberWithInt:(int)book.currentPage],
        [NSNumber numberWithInt:(int)book.totalPages],
        [NSNumber numberWithInt:(int)book.readingTimeMinutes],
        book.sourceUrl ?: [NSNull null],
        [NSNumber numberWithBool:book.isDownloaded]];
    
    if (!ok && [delegate respondsToSelector:@selector(storageService:didSaveBook:withSuccess:error:)]) {
        NSError *error = [NSError errorWithDomain:@"XLStorageService" code:[_database lastErrorCode]
            userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Failed to save book" }];
        [delegate storageService:self didSaveBook:book withSuccess:NO error:error];
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
        if (_database) {
            [self getBookWithId:bookId delegate:delegate];
        }
        return;
    }
    
    FMResultSet *rs = [_database executeQuery:@"SELECT id, title, author, cover_path, file_path, format, file_size, added_at, last_read_at, source_lang, target_lang, proficiency, density, progress, current_location, current_chapter, total_chapters, current_page, total_pages, reading_time_minutes, source_url, is_downloaded FROM books WHERE id = ?", bookId];
    XLBook *book = nil;
    if ([rs next]) {
        book = [self bookFromResultSet:rs];
    }
    [rs close];
    
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
    
    FMResultSet *rs = [_database executeQuery:sql];
    NSMutableArray *books = [NSMutableArray array];
    while (rs && [rs next]) {
        XLBook *book = [self bookFromResultSet:rs];
        if (book) {
            [books addObject:book];
        }
    }
    [rs close];
    
    if ([delegate respondsToSelector:@selector(storageService:didGetAllBooks:withError:)]) {
        [delegate storageService:self didGetAllBooks:books withError:nil];
    }
}

- (void)deleteBookWithId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) {
            [self deleteBookWithId:bookId delegate:delegate];
        }
        return;
    }
    
    BOOL ok = [_database executeUpdate:@"DELETE FROM books WHERE id = ?", bookId];
    if (!ok && [delegate respondsToSelector:@selector(storageService:didDeleteBookWithId:withSuccess:error:)]) {
        NSError *error = [NSError errorWithDomain:@"XLStorageService" code:[_database lastErrorCode]
            userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Failed to delete book" }];
        [delegate storageService:self didDeleteBookWithId:bookId withSuccess:NO error:error];
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
    long long addedMs = (long long)([item.addedAt timeIntervalSince1970] * 1000);
    long long lastRevMs = item.lastReviewedAt ? (long long)([item.lastReviewedAt timeIntervalSince1970] * 1000) : 0;
    BOOL ok = [_database executeUpdate:@"INSERT OR REPLACE INTO vocabulary (id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        item.vocabularyId,
        item.sourceWord,
        item.targetWord,
        [XLLanguageInfo codeStringForLanguage:item.sourceLanguage],
        [XLLanguageInfo codeStringForLanguage:item.targetLanguage],
        item.contextSentence ?: [NSNull null],
        item.bookId ?: [NSNull null],
        item.bookTitle ?: [NSNull null],
        [NSNumber numberWithLongLong:addedMs],
        [NSNumber numberWithLongLong:lastRevMs],
        [NSNumber numberWithInt:(int)item.reviewCount],
        [NSNumber numberWithDouble:item.easeFactor],
        [NSNumber numberWithInt:(int)item.interval],
        [XLVocabularyItem codeStringForStatus:item.status]];
    if ([delegate respondsToSelector:@selector(storageService:didSaveVocabularyItem:withSuccess:error:)]) {
        NSError *err = ok ? nil : [NSError errorWithDomain:@"XLStorageService" code:[_database lastErrorCode] userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Save failed" }];
        [delegate storageService:self didSaveVocabularyItem:item withSuccess:ok error:err];
    }
}

- (void)getVocabularyItemWithId:(NSString *)itemId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getVocabularyItemWithId:itemId delegate:delegate]; }
        return;
    }
    FMResultSet *rs = [_database executeQuery:@"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE id = ?", itemId];
    XLVocabularyItem *item = nil;
    if ([rs next]) {
        item = [self vocabularyItemFromResultSet:rs];
    }
    [rs close];
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
    FMResultSet *rs = [_database executeQuery:@"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary ORDER BY added_at DESC"];
    NSMutableArray *items = [NSMutableArray array];
    while (rs && [rs next]) {
        XLVocabularyItem *item = [self vocabularyItemFromResultSet:rs];
        if (item) [items addObject:item];
    }
    [rs close];
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
    BOOL ok = [_database executeUpdate:@"DELETE FROM vocabulary WHERE id = ?", itemId];
    if ([delegate respondsToSelector:@selector(storageService:didDeleteVocabularyItemWithId:withSuccess:error:)]) {
        [delegate storageService:self didDeleteVocabularyItemWithId:itemId withSuccess:ok error:nil];
    }
}

- (void)searchVocabularyWithQuery:(NSString *)query delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self searchVocabularyWithQuery:query delegate:delegate]; }
        return;
    }
    NSString *pattern = [NSString stringWithFormat:@"%%%@%%", query];
    FMResultSet *rs = [_database executeQuery:@"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE source_word LIKE ? OR target_word LIKE ? ORDER BY added_at DESC", pattern, pattern];
    NSMutableArray *items = [NSMutableArray array];
    while (rs && [rs next]) {
        XLVocabularyItem *item = [self vocabularyItemFromResultSet:rs];
        if (item) [items addObject:item];
    }
    [rs close];
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

- (XLReadingSession *)readingSessionFromResultSet:(FMResultSet *)rs {
    XLReadingSession *session = [[XLReadingSession alloc] init];
    session.sessionId = [rs stringForColumnIndex:0] ?: @"";
    session.bookId = [rs stringForColumnIndex:1] ?: @"";
    long long startedMs = [rs longLongIntForColumnIndex:2];
    session.startedAt = [NSDate dateWithTimeIntervalSince1970:startedMs / 1000.0];
    long long endedMs = [rs longLongIntForColumnIndex:3];
    session.endedAt = (endedMs > 0) ? [NSDate dateWithTimeIntervalSince1970:endedMs / 1000.0] : nil;
    session.pagesRead = [rs intForColumnIndex:4];
    session.wordsRevealed = [rs intForColumnIndex:5];
    session.wordsSaved = [rs intForColumnIndex:6];
    if (session.endedAt && session.startedAt) {
        session.duration = [session.endedAt timeIntervalSinceDate:session.startedAt];
    }
    return session;
}

- (XLVocabularyItem *)vocabularyItemFromResultSet:(FMResultSet *)rs {
    XLVocabularyItem *item = [[XLVocabularyItem alloc] init];
    item.vocabularyId = [rs stringForColumnIndex:0] ?: @"";
    item.sourceWord = [rs stringForColumnIndex:1] ?: @"";
    item.targetWord = [rs stringForColumnIndex:2] ?: @"";
    item.sourceLanguage = [XLLanguageInfo languageForCodeString:[rs stringForColumnIndex:3] ?: @"en"];
    item.targetLanguage = [XLLanguageInfo languageForCodeString:[rs stringForColumnIndex:4] ?: @"en"];
    item.contextSentence = [rs stringForColumnIndex:5];
    item.bookId = [rs stringForColumnIndex:6];
    item.bookTitle = [rs stringForColumnIndex:7];
    long long addedMs = [rs longLongIntForColumnIndex:8];
    item.addedAt = [NSDate dateWithTimeIntervalSince1970:addedMs / 1000.0];
    long long lastRevMs = [rs longLongIntForColumnIndex:9];
    item.lastReviewedAt = lastRevMs > 0 ? [NSDate dateWithTimeIntervalSince1970:lastRevMs / 1000.0] : nil;
    item.reviewCount = [rs intForColumnIndex:10];
    item.easeFactor = [rs doubleForColumnIndex:11];
    item.interval = [rs intForColumnIndex:12];
    item.status = [XLVocabularyItem statusForCodeString:[rs stringForColumnIndex:13] ?: @"new"];
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
    FMResultSet *rs = [_database executeQuery:@"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE status != 'learned' AND (last_reviewed_at IS NULL OR (last_reviewed_at + interval * 86400000) <= ?) ORDER BY last_reviewed_at ASC LIMIT ?", [NSNumber numberWithLongLong:nowMs], [NSNumber numberWithInt:(int)limit]];
    NSMutableArray *items = [NSMutableArray array];
    while (rs && [rs next]) {
        XLVocabularyItem *item = [self vocabularyItemFromResultSet:rs];
        if (item) [items addObject:item];
    }
    [rs close];
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
    FMResultSet *selRs = [_database executeQuery:@"SELECT id, source_word, target_word, source_lang, target_lang, context_sentence, book_id, book_title, added_at, last_reviewed_at, review_count, ease_factor, interval, status FROM vocabulary WHERE id = ?", itemId];
    if (![selRs next]) {
        [selRs close];
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:2 userInfo:@{ NSLocalizedDescriptionKey: @"Item not found" }]];
        }
        return;
    }
    XLVocabularyItem *item = [self vocabularyItemFromResultSet:selRs];
    [selRs close];
    if (!item) {
        if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
            [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:NO error:[NSError errorWithDomain:@"XLStorageService" code:2 userInfo:nil]];
        }
        return;
    }
    /* Use native ObjC SM-2 (XLSm2) for identical behaviour with C# / xenolexia-shared-c */
    XLSm2State *state = [[[XLSm2State alloc] init] autorelease];
    state.easeFactor = item.easeFactor;
    state.interval = item.interval;
    state.reviewCount = item.reviewCount;
    state.status = (XLSm2Status)item.status;
    XLSm2Step((NSInteger)quality, state);
    NSInteger rc = state.reviewCount;
    double ef = state.easeFactor;
    NSInteger iv = state.interval;
    XLVocabularyStatus newStatus = item.status;
    switch (state.status) {
        case XLSm2StatusLearning: newStatus = XLVocabularyStatusLearning; break;
        case XLSm2StatusReview:   newStatus = XLVocabularyStatusReview; break;
        case XLSm2StatusLearned:  newStatus = XLVocabularyStatusLearned; break;
        default:                  newStatus = XLVocabularyStatusNew; break;
    }
    long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    BOOL ok = [_database executeUpdate:@"UPDATE vocabulary SET last_reviewed_at = ?, review_count = ?, ease_factor = ?, interval = ?, status = ? WHERE id = ?",
        [NSNumber numberWithLongLong:nowMs],
        [NSNumber numberWithInt:(int)rc],
        [NSNumber numberWithDouble:ef],
        [NSNumber numberWithInt:(int)iv],
        [XLVocabularyItem codeStringForStatus:newStatus],
        itemId];
    if ([delegate respondsToSelector:@selector(storageService:didRecordReviewForItemId:withSuccess:error:)]) {
        [delegate storageService:self didRecordReviewForItemId:itemId withSuccess:ok error:nil];
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
    FMResultSet *rs = [_database executeQuery:@"SELECT key, value FROM preferences"];
    while (rs && [rs next]) {
        NSString *k = [rs stringForColumnIndex:0];
        NSString *v = [rs stringForColumnIndex:1];
        if (k && v) {
            [dict setObject:v forKey:k];
        }
    }
    [rs close];

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
    XLReaderSettings *readerSettings = prefs.readerSettings ?: [XLReaderSettings defaultSettings];
    NSArray *pairs = @[
        @[ @"source_lang", [XLLanguageInfo codeStringForLanguage:prefs.defaultSourceLanguage] ],
        @[ @"target_lang", [XLLanguageInfo codeStringForLanguage:prefs.defaultTargetLanguage] ],
        @[ @"proficiency", [XLLanguageInfo codeStringForProficiency:prefs.defaultProficiencyLevel] ],
        @[ @"word_density", [NSString stringWithFormat:@"%.17g", prefs.defaultWordDensity] ],
        @[ @"reader_theme", [self stringForTheme:readerSettings.theme] ],
        @[ @"reader_font_family", readerSettings.fontFamily ?: @"System" ],
        @[ @"reader_font_size", [NSString stringWithFormat:@"%.17g", readerSettings.fontSize] ],
        @[ @"reader_line_height", [NSString stringWithFormat:@"%.17g", readerSettings.lineHeight] ],
        @[ @"reader_margin_horizontal", [NSString stringWithFormat:@"%.17g", readerSettings.marginHorizontal] ],
        @[ @"reader_margin_vertical", [NSString stringWithFormat:@"%.17g", readerSettings.marginVertical] ],
        @[ @"reader_text_align", [self stringForTextAlign:readerSettings.textAlign] ],
        @[ @"reader_brightness", [NSString stringWithFormat:@"%.17g", readerSettings.brightness] ],
        @[ @"onboarding_done", prefs.hasCompletedOnboarding ? @"true" : @"false" ],
        @[ @"notifications_enabled", prefs.notificationsEnabled ? @"true" : @"false" ],
        @[ @"daily_goal", [NSString stringWithFormat:@"%ld", (long)prefs.dailyGoal] ]
    ];
    for (NSArray *kv in pairs) {
        BOOL ok = [_database executeUpdate:@"INSERT OR REPLACE INTO preferences (key, value) VALUES (?, ?)", [kv objectAtIndex:0], [kv objectAtIndex:1]];
        if (!ok) {
            if ([delegate respondsToSelector:@selector(storageService:didSavePreferencesWithSuccess:error:)]) {
                NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Save failed" }];
                [delegate storageService:self didSavePreferencesWithSuccess:NO error:err];
            }
            return;
        }
    }
    if ([delegate respondsToSelector:@selector(storageService:didSavePreferencesWithSuccess:error:)]) {
        [delegate storageService:self didSavePreferencesWithSuccess:YES error:nil];
    }
}

- (void)getLibraryViewModeWithDelegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getLibraryViewModeWithDelegate:delegate]; }
        return;
    }
    BOOL grid = NO;
    FMResultSet *rs = [_database executeQuery:@"SELECT value FROM preferences WHERE key = 'library_view_mode'"];
    if ([rs next]) {
        if ([[rs stringForColumnIndex:0] isEqualToString:@"grid"]) grid = YES;
    }
    [rs close];
    if ([delegate respondsToSelector:@selector(storageService:didGetLibraryViewMode:error:)]) {
        [delegate storageService:self didGetLibraryViewMode:grid error:nil];
    }
}

- (void)saveLibraryViewMode:(BOOL)grid delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self saveLibraryViewMode:grid delegate:delegate]; }
        return;
    }
    BOOL ok = [_database executeUpdate:@"INSERT OR REPLACE INTO preferences (key, value) VALUES ('library_view_mode', ?)", grid ? @"grid" : @"list"];
    if ([delegate respondsToSelector:@selector(storageService:didSaveLibraryViewModeWithSuccess:error:)]) {
        [delegate storageService:self didSaveLibraryViewModeWithSuccess:ok error:nil];
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
    BOOL ok = [_database executeUpdate:@"INSERT INTO reading_sessions (id, book_id, started_at, ended_at, pages_read, words_revealed, words_saved) VALUES (?, ?, ?, NULL, 0, 0, 0)", sessionId, bookId, [NSNumber numberWithLongLong:nowMs]];
    if (!ok && [delegate respondsToSelector:@selector(storageService:didStartReadingSessionWithId:error:)]) {
        NSError *err = [NSError errorWithDomain:@"XLStorageService" code:1 userInfo:@{ NSLocalizedDescriptionKey: [_database lastErrorMessage] ?: @"Failed" }];
        [delegate storageService:self didStartReadingSessionWithId:nil error:err];
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
    BOOL ok = [_database executeUpdate:@"UPDATE reading_sessions SET ended_at = ?, words_revealed = ?, words_saved = ? WHERE id = ?", [NSNumber numberWithLongLong:nowMs], [NSNumber numberWithInt:(int)wordsRevealed], [NSNumber numberWithInt:(int)wordsSaved], sessionId];
    if ([delegate respondsToSelector:@selector(storageService:didEndReadingSessionWithSuccess:error:)]) {
        [delegate storageService:self didEndReadingSessionWithSuccess:ok error:nil];
    }
}

- (void)getActiveSessionForBookId:(NSString *)bookId delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getActiveSessionForBookId:bookId delegate:delegate]; }
        return;
    }
    FMResultSet *rs = [_database executeQuery:@"SELECT id, book_id, started_at, ended_at, pages_read, words_revealed, words_saved FROM reading_sessions WHERE book_id = ? AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1", bookId];
    XLReadingSession *session = nil;
    if ([rs next]) {
        session = [self readingSessionFromResultSet:rs];
    }
    [rs close];
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

    FMResultSet *rs = [_database executeQuery:@"SELECT book_id, started_at, ended_at, words_revealed, words_saved FROM reading_sessions WHERE ended_at IS NOT NULL"];
    while (rs && [rs next]) {
        NSString *bookId = [rs stringForColumnIndex:0] ?: @"";
        long long startedMs = [rs longLongIntForColumnIndex:1];
        long long endedMs = [rs longLongIntForColumnIndex:2];
        NSInteger wr = [rs intForColumnIndex:3];
        NSInteger ws = [rs intForColumnIndex:4];
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
    [rs close];

    NSInteger totalWordsLearned = 0;
    FMResultSet *countRs = [_database executeQuery:@"SELECT COUNT(*) FROM vocabulary WHERE status = 'learned'"];
    if ([countRs next]) {
        totalWordsLearned = [countRs intForColumnIndex:0];
    }
    [countRs close];

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

- (void)getWordsRevealedByDayWithLastDays:(NSInteger)lastDays delegate:(id<XLStorageServiceDelegate>)delegate {
    _currentDelegate = delegate;
    if (!_database) {
        [self initializeDatabaseWithDelegate:delegate];
        if (_database) { [self getWordsRevealedByDayWithLastDays:lastDays delegate:delegate]; }
        return;
    }
    NSMutableDictionary *byDate = [NSMutableDictionary dictionary];
    FMResultSet *rs = [_database executeQuery:@"SELECT date(ended_at/1000, 'unixepoch', 'localtime') as d, SUM(words_revealed) as total FROM reading_sessions WHERE ended_at IS NOT NULL GROUP BY d"];
    while (rs && [rs next]) {
        NSString *dateStr = [rs stringForColumnIndex:0];
        NSInteger total = [rs intForColumnIndex:1];
        if (dateStr) {
            [byDate setObject:[NSNumber numberWithInteger:total] forKey:dateStr];
        }
    }
    [rs close];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateFormatter *dayFmt = [[NSDateFormatter alloc] init];
    [dayFmt setDateFormat:@"EEE d"];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)lastDays];
    for (NSInteger i = lastDays - 1; i >= 0; i--) {
        NSDate *day = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:[NSDate date] options:0];
        NSDateComponents *comp = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:day];
        NSDate *dayStart = [cal dateFromComponents:comp];
        NSString *dateStr = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)[comp year], (long)[comp month], (long)[comp day]];
        NSNumber *wr = [byDate objectForKey:dateStr];
        NSInteger wordsRevealed = wr ? [wr integerValue] : 0;
        NSString *dayLabel = [dayFmt stringFromDate:dayStart];
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            dayLabel, @"dayLabel",
            [NSNumber numberWithInteger:wordsRevealed], @"wordsRevealed",
            nil]];
    }
    [dayFmt release];

    if ([delegate respondsToSelector:@selector(storageService:didGetWordsRevealedByDay:withError:)]) {
        [delegate storageService:self didGetWordsRevealedByDay:result withError:nil];
    }
}

- (XLBook *)bookFromResultSet:(FMResultSet *)rs {
    XLBook *book = [[XLBook alloc] init];
    book.bookId = [rs stringForColumnIndex:0] ?: @"";
    book.title = [rs stringForColumnIndex:1] ?: @"";
    book.author = [rs stringForColumnIndex:2];
    book.coverPath = [rs stringForColumnIndex:3];
    book.filePath = [rs stringForColumnIndex:4] ?: @"";
    book.format = [self bookFormatForString:[rs stringForColumnIndex:5] ?: @"epub"];
    book.fileSize = [rs longLongIntForColumnIndex:6];
    long long addedAtMs = [rs longLongIntForColumnIndex:7];
    book.addedAt = [NSDate dateWithTimeIntervalSince1970:addedAtMs / 1000.0];
    long long lastReadAtMs = [rs longLongIntForColumnIndex:8];
    book.lastReadAt = lastReadAtMs > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadAtMs / 1000.0] : nil;
    XLLanguage sourceLang = [XLLanguageInfo languageForCodeString:[rs stringForColumnIndex:9] ?: @"en"];
    XLLanguage targetLang = [XLLanguageInfo languageForCodeString:[rs stringForColumnIndex:10] ?: @"en"];
    book.languagePair = [XLLanguagePair pairWithSource:sourceLang target:targetLang];
    book.proficiencyLevel = [XLLanguageInfo proficiencyForCodeString:[rs stringForColumnIndex:11] ?: @"beginner"];
    book.wordDensity = [rs doubleForColumnIndex:12];
    book.progress = [rs doubleForColumnIndex:13];
    book.currentLocation = [rs stringForColumnIndex:14];
    book.currentChapter = [rs intForColumnIndex:15];
    book.totalChapters = [rs intForColumnIndex:16];
    book.currentPage = [rs intForColumnIndex:17];
    book.totalPages = [rs intForColumnIndex:18];
    book.readingTimeMinutes = [rs intForColumnIndex:19];
    book.sourceUrl = [rs stringForColumnIndex:20];
    book.isDownloaded = [rs intForColumnIndex:21] != 0;
    return book;
}

- (void)dealloc {
    if (_database) {
        [_database close];
        [_database release];
        _database = nil;
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
