//
//  Utilities.m
//  DownloadAndDisplayLocalHTML
//

#import "DictionaryService.h"

//@interface DictionaryService()
//
//@property (strong, nonatomic) NSMutableArray *keysList;
//
//@end

@implementation DictionaryService

- (NSDictionary*)loadDictionary {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [self loadDictionaryFromUserDefaults:userDefaults];
}

-(void)persistDictionary:(NSDictionary*)dictionary {
    //NSLog(@"%@",dictionary); // can't handle UTF8 characters
    // use a for-loop to print the dictionary items instead
    for (NSString* key in dictionary) {
        NSLog(@"key: %@, value: %@", key, (NSString*)[dictionary objectForKey:key]);
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self persistDictionary:dictionary toUserDefaults:userDefaults];
}

- (NSString*)removeSymbolsFromString:(NSString*)input {
    NSMutableCharacterSet *seperatorSet = [NSMutableCharacterSet symbolCharacterSet];
    NSMutableArray *words = [[input componentsSeparatedByCharactersInSet:seperatorSet] mutableCopy];
    NSString *output = [words componentsJoinedByString:@" "];
    
    return output;
}

- (NSString*)removePunctuationFromString:(NSString*)input {
    NSMutableCharacterSet *seperatorSet = [NSMutableCharacterSet punctuationCharacterSet];
    NSMutableArray *words = [[input componentsSeparatedByCharactersInSet:seperatorSet] mutableCopy];
    NSString *output = [words componentsJoinedByString:@" "];
    
    return output;
}

- (void)cleanupTxtFileContents {
    /* assume we already have the following:
     NSString *txtFilePath = [[NSBundle mainBundle] pathForResource:@"\source" ofType:@"txt"];
     NSString *txtFileContents = [NSString stringWithContentsOfFile:txtFilePath encoding:NSUTF8StringEncoding error:NULL];
     */
    NSString* txtFileContents = self.txtFileContents;
    
    // prints content of flattened (txt) html file
    //NSLog(@"%@",txtFileContents);
    
    // convert string to lowercase
    NSString *newString2 = [txtFileContents lowercaseString];
    
    // remove all symbols from string
    NSString *newString3 = [self removeSymbolsFromString:newString2];
    
    // remove all punctuation from string
    NSString *newString1 = [self removePunctuationFromString:newString3];
    
    self.txtFileContents = newString1;
}

// run once for new books only
// current implementation is not straightforward to test :(
- (NSArray*)generateKeysArray {
    
    //NSMutableDictionary *wordsDictionary = [NSMutableDictionary new];
    NSMutableArray* keysList = [NSMutableArray new];
    
    // clean up the txt file contents
    [self cleanupTxtFileContents];
    
    NSString* txtFileContents = self.txtFileContents;
    
    // remove white characters and split into array
    NSMutableCharacterSet *seperatorSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableArray *words = [[txtFileContents componentsSeparatedByCharactersInSet:seperatorSet] mutableCopy];
    
    // works with no issues:
    for (NSString* word in words) {
        // don't just add every word extracted from the html file, be picky about it
        // copulas, conjunctions, prepositions, numbers and so on are not needed
        // average word length in English is 5.1 letters, this is a beginners learning app, so avoid big words
        // some non-words will slip through not everything will be caught
        // would be nice if plural forms and verb conjugations can be caught - for now skipped
        // update: reduced word length to less than 8 and testing if it contains any number
        if(([word length] > 2) && ([word length] < 8) && !([word integerValue]) && !([word floatValue]) && !([word isEqualToString:@"and"]) && !([word isEqualToString:@"the"]) && !([word isEqualToString:@""]) && !([word isEqualToString:@"their"]) && !([word isEqualToString:@"are"]) && !([word isEqualToString:@"have"]) && !([word isEqualToString:@"had"]) && !([word isEqualToString:@"has"]) && !([word isEqualToString:@"your"]) && !([word isEqualToString:@"but"]) && !([word isEqualToString:@"for"]) && ([word rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) ) {
            //[wordsDictionary setObject:@"replace-with-translation" forKey:word];
            [keysList addObject:word];
        }
    }
    
    // remove empty string from dictionary
    //[wordsDictionary removeObjectForKey:@""];
    
    // remove duplicates
    NSArray *noDuplicates = [keysList valueForKeyPath:@"@distinctUnionOfObjects.self"];
    
    NSMutableArray *sortedArray = [NSMutableArray arrayWithArray: [noDuplicates sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    //NSLog(@"%i", sortedArray.count); //365
    
    // further remove words that are too similar
    int i;
    for (i = 1; i < [sortedArray count]; i++) {
        NSString *currentWord = [sortedArray objectAtIndex:i];
        NSString *previousWord = [sortedArray objectAtIndex:i-1];
        if(!([currentWord rangeOfString:previousWord].location == NSNotFound))  {
            // if this word is too similar to the word before it
            [sortedArray removeObjectAtIndex:i];
        }
    }
    
    //NSLog(@"%i", sortedArray.count); // 317
    
    // one more run remove words that are too similar
    for (i = 1; i < [sortedArray count]; i++) {
        NSString *currentWord = [sortedArray objectAtIndex:i];
        NSString *previousWord = [sortedArray objectAtIndex:i-1];
        if(!([currentWord rangeOfString:previousWord].location == NSNotFound))  {
            // if this word is too similar to the word before it
            [sortedArray removeObjectAtIndex:i];
        }
    }
    
    //NSLog(@"%i", sortedArray.count); // 302
    
    // a final run to remove words that are too similar
    // it is okay to waste clock cycles here to find that last few words
    // it is cheap and Clang is fast at this
    for (i = 1; i < [sortedArray count]; i++) {
        NSString *currentWord = [sortedArray objectAtIndex:i];
        NSString *previousWord = [sortedArray objectAtIndex:i-1];
        if(!([currentWord rangeOfString:previousWord].location == NSNotFound))  {
            // if this word is too similar to the word before it
            [sortedArray removeObjectAtIndex:i];
        }
    }
    
    //NSLog(@"%i", sortedArray.count); // 297
    // with a little bit of selectiveness the array of unique words have been reduced
    // from over 400 to less than 300
    // still too big for translator service
    
    return sortedArray.copy;
    
    //bookObject.keys = sortedArray;
    //bookObject.wordAndTranslation = wordsDictionary;
}

- (NSDictionary*)loadDictionaryFromUserDefaults:(NSUserDefaults*)userDefaults {
    NSDictionary *dictionary = [userDefaults dictionaryForKey:@"translations"];
    return dictionary;
}

- (void)persistDictionary:(NSDictionary *)dictionary toUserDefaults:(NSUserDefaults*)userDefaults{
    [userDefaults setObject:dictionary forKey:@"translations"];
    [userDefaults synchronize];
}

@end
