//
//  XLStorageServiceBlockHelper.m
//  Xenolexia
//

#import "XLStorageServiceBlockHelper.h"
#import "../Models/Book.h"

@implementation XLStorageServiceBlockHelper

- (void)storageService:(id)service didSaveBook:(XLBook *)book withSuccess:(BOOL)success error:(NSError *)error {
    if (self.saveBookCompletion) {
        self.saveBookCompletion(success, error);
    }
}

- (void)storageService:(id)service didGetBook:(XLBook *)book withError:(NSError *)error {
    if (self.getBookCompletion) {
        self.getBookCompletion(book, error);
    }
}

- (void)storageService:(id)service didGetAllBooks:(NSArray *)books withError:(NSError *)error {
    if (self.getAllBooksCompletion) {
        self.getAllBooksCompletion(books, error);
    }
}

- (void)storageService:(id)service didDeleteBookWithId:(NSString *)bookId withSuccess:(BOOL)success error:(NSError *)error {
    if (self.deleteBookCompletion) {
        self.deleteBookCompletion(success, error);
    }
}

- (void)storageService:(id)service didInitializeDatabaseWithSuccess:(BOOL)success error:(NSError *)error {
    if (self.initDatabaseCompletion) {
        self.initDatabaseCompletion(success, error);
    }
}

@end
