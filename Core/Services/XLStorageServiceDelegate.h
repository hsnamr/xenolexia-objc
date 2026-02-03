//
//  XLStorageServiceDelegate.h
//  Xenolexia
//
//  Delegate protocol for storage service callbacks (GNUStep compatible)

#import <Foundation/Foundation.h>
#import "../Models/Book.h"
#import "../Models/Vocabulary.h"
#import "../Models/Reader.h"

@protocol XLStorageServiceDelegate <NSObject>

@optional

// Book operation callbacks
- (void)storageService:(id)service didSaveBook:(XLBook *)book withSuccess:(BOOL)success error:(NSError *)error;
- (void)storageService:(id)service didGetBook:(XLBook *)book withError:(NSError *)error;
- (void)storageService:(id)service didGetAllBooks:(NSArray *)books withError:(NSError *)error;
- (void)storageService:(id)service didDeleteBookWithId:(NSString *)bookId withSuccess:(BOOL)success error:(NSError *)error;

// Vocabulary operation callbacks
- (void)storageService:(id)service didSaveVocabularyItem:(XLVocabularyItem *)item withSuccess:(BOOL)success error:(NSError *)error;
- (void)storageService:(id)service didGetVocabularyItem:(XLVocabularyItem *)item withError:(NSError *)error;
- (void)storageService:(id)service didGetAllVocabularyItems:(NSArray *)items withError:(NSError *)error;
- (void)storageService:(id)service didDeleteVocabularyItemWithId:(NSString *)itemId withSuccess:(BOOL)success error:(NSError *)error;
- (void)storageService:(id)service didSearchVocabulary:(NSArray *)items withError:(NSError *)error;
- (void)storageService:(id)service didGetVocabularyDueForReview:(NSArray *)items withError:(NSError *)error;
- (void)storageService:(id)service didRecordReviewForItemId:(NSString *)itemId withSuccess:(BOOL)success error:(NSError *)error;

// Preferences (Phase 0)
- (void)storageService:(id)service didGetPreferences:(XLUserPreferences *)prefs withError:(NSError *)error;
- (void)storageService:(id)service didSavePreferencesWithSuccess:(BOOL)success error:(NSError *)error;

// Reading sessions (Phase 0)
- (void)storageService:(id)service didStartReadingSessionWithId:(NSString *)sessionId error:(NSError *)error;
- (void)storageService:(id)service didEndReadingSessionWithSuccess:(BOOL)success error:(NSError *)error;
- (void)storageService:(id)service didGetActiveSession:(XLReadingSession *)session withError:(NSError *)error;

// Statistics (Phase 0)
- (void)storageService:(id)service didGetReadingStats:(XLReadingStats *)stats withError:(NSError *)error;

// Database initialization callback
- (void)storageService:(id)service didInitializeDatabaseWithSuccess:(BOOL)success error:(NSError *)error;

@end
