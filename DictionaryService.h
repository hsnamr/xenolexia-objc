//
//  Utilities.h
//  DownloadAndDisplayLocalHTML
//

#import <Foundation/Foundation.h>

@interface DictionaryService : NSObject
@property (nonatomic, retain) NSArray* arrayOfBooks;
@property (nonatomic, retain) NSString* txtFileContents;

//- (void)serviceManager;
- (NSDictionary*)loadDictionary;
- (void)persistDictionary:(NSDictionary*)dictionary;

// exposed for unit testing only
- (NSString*)removeSymbolsFromString:(NSString*)input;
- (NSString*)removePunctuationFromString:(NSString*)input;


- (NSArray*)generateKeysArray;

@end
