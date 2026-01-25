//
//  XLExportService.h
//  Xenolexia
//
//  Export service for vocabulary (CSV, JSON, Anki formats)

#import <Foundation/Foundation.h>
#import "../Models/Vocabulary.h"

NS_ASSUME_NONNULL_BEGIN

/// Export formats
typedef NS_ENUM(NSInteger, XLExportFormat) {
    XLExportFormatCSV = 0,
    XLExportFormatJSON,
    XLExportFormatAnki
};

/// Export service
@interface XLExportService : NSObject

/// Export vocabulary items to a file
- (void)exportVocabularyItems:(NSArray<XLVocabularyItem *> *)items
                        format:(XLExportFormat)format
                    toFilePath:(NSString *)filePath
                withCompletion:(void(^)(BOOL success, NSError * _Nullable error))completion;

/// Export to CSV format
- (NSString *)exportToCSV:(NSArray<XLVocabularyItem *> *)items;

/// Export to JSON format
- (NSString *)exportToJSON:(NSArray<XLVocabularyItem *> *)items;

/// Export to Anki TSV format
- (NSString *)exportToAnki:(NSArray<XLVocabularyItem *> *)items;

@end

NS_ASSUME_NONNULL_END
