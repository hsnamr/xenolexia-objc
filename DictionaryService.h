//
//  Utilities.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/21/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DictionaryService : NSObject
@property (strong,nonatomic) NSArray* arrayOfBooks;
@property (strong,nonatomic) NSString* txtFileContents;

//- (void)serviceManager;
- (NSDictionary*)loadDictionary;
- (void)persistDictionary:(NSDictionary*)dictionary;

// exposed for unit testing only
- (NSString*)removeSymbolsFromString:(NSString*)input;
- (NSString*)removePunctuationFromString:(NSString*)input;


- (NSArray*)generateKeysArray;

@end