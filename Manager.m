//
//  Manager.m
//  DownloadAndDisplayLocalHTML
//

#import "Manager.h"
#import "DictionaryService.h"
#import "HtmlToTextService.h"
#import "DownloadService.h"
#import "LocationService.h"
#import "TranslationService.h"

@implementation Manager {
    DictionaryService* myDictionaryService;
    HtmlToTextService* myHtml2TxtService;
    DownloadService* myDownloadService;
    LocationService* myLocationService;
    TranslationService* myTranslationService;
}

+ (id)sharedManager {
    static Manager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)downloadFile:(NSURL*)fileURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // example HTML file
    //NSURL *fileURL = [NSURL URLWithString:@"https://docs.oracle.com/javase/7/docs/api/javax/swing/text/html/HTMLDocument.html"];
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // download HTML file using download service
    myDownloadService = [DownloadService new];

    [myDownloadService downloadFrom:fileURL toDirectory:documentsDirectory];
}

- (void)listFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    [myDownloadService listFilesInDirectory:documentsDirectory];
}

- (void)html2TextManager {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // read HTML from local file
    NSString *htmlFile = [documentsDirectory stringByAppendingPathComponent:@"HTMLDocument.html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // flatten HTML by calling HTML to text service
    myHtml2TxtService = [HtmlToTextService new];
    myHtml2TxtService.htmlSource = htmlString;
    [myHtml2TxtService serviceManager];
}

- (void)dictionaryManager {
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // add to dictionary by calling dictionary service
    myDictionaryService = [DictionaryService new];
    myDictionaryService.txtFileContents = myHtml2TxtService.txtOutput;
    //[myDictionaryService serviceManager];
    NSDictionary* translations = [myDictionaryService loadDictionary];
    NSLog(@"translations as read from userdefaults: %@", translations);
    
    if(!translations) {
        // if dictionary does not exist
        NSLog(@"translations is nil");
        [self translateArray:[myDictionaryService generateKeysArray]];
        
        //NSLog(@"This is the array: %@\n\nNotify the manager to translate it.", self.keysList);
        //[myDictionaryService askManagerToTranslateArray];
    }
}

- (void)locationManager {
    myLocationService = [LocationService new];
    [myLocationService fakeManager];
}

//- (void)translationManager {
//    // does nothing - replaced with more specialized methods
//    ///////////////////// TO-DO:
//    // do translation on htmlString
//    // translate 2-4 words every page (250-300 words)
//    // remember translated words
//}

// calls the translation manager (or service) to do the translation
// then calls the dictionary service to persist and print the dictionary
- (void)translateArray:(NSArray*)keys {
    unsigned long keysCount = keys.count;
    NSLog(@"keys count: %lu", keysCount);
    myTranslationService = [TranslationService sharedTranslator];
    myDictionaryService = [DictionaryService new];
    
    // if array is big - in testing I found that +400 takes way too much time here
    // it is defintely not due to creating the dictionary
    // so it must be the Translator service taking too much time to respond
    // I waited 6 minutes with no response back - possibly timed out?
    // perhaps we can translate just a portion of it?
    
    if (keysCount > 100) {
        // testing showed that 100 is a reasonable size to translate and get back a response within an acceptable timeframe
        NSLog(@"keysCount > 100");
        // ------------------------------------------------------------------------------------------
        // To-Do:
        // split array into multiple arrays
        // translate first array, then every Y number of pages translate an array
        // so that the number of translated (learned) words increases with every Y pages
        // CURRENTLY NOT IMPLEMENTED - for now we are doing the following instead
        // ------------------------------------------------------------------------------------------
        
        // the array is sorted alphabetically, randomize it to increase the chance of translating words across multiple pages
        // ideally we would restore the original word ordering of the document but this should be good enough
        NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:keys];
        for(NSUInteger i = keysCount; i > 1; i--) {
            NSUInteger j = arc4random_uniform((u_int32_t)i);
            [temp exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
        }
        
        //NSLog(@"[temp count] %lu", [temp count]);
        
        // translate 100 words
        NSArray* tempA = [temp subarrayWithRange:NSMakeRange(0, 100)];
        //NSLog(@"[tempA count] %lu", [tempA count]);
        
        [myTranslationService doTranslateArray:tempA withCompletion:^(NSArray *translatedTextArray) {
            //NSLog(@"%@", translatedTextArray);
            // create dictionary:
            NSMutableDictionary *wordAndTranslationDictionary = [NSMutableDictionary new];
            
            for (int i = 0; i < tempA.count; i++) {
                [wordAndTranslationDictionary setValue:translatedTextArray[i] forKey:tempA[i]];
            }
            //NSLog(@"resuling dict: %@", wordAndTranslationDictionary);
            [myDictionaryService persistDictionary:wordAndTranslationDictionary];
        }];
    } else {
        // less than 100
        // translate the entire array
        // unlikely to ever run
        [myTranslationService doTranslateArray:keys withCompletion:^(NSArray *translatedTextArray) {
            // create dictionary:
            NSMutableDictionary *wordAndTranslationDictionary = [NSMutableDictionary new];
            
            for (int i = 0; i < keysCount; i++) {
                [wordAndTranslationDictionary setValue:translatedTextArray[i] forKey:keys[i]];
            }
            [myDictionaryService persistDictionary:wordAndTranslationDictionary];
        }];
    }
}

- (void)translateWord:(NSString*)input withCompletion:(void(^)(NSString *))completion {
    myTranslationService = [TranslationService sharedTranslator];
    [myTranslationService doTranslateWord:input withCompletion:^(NSString *translatedText) {
        // pass translation to view controller (webview or menu) to display translation for selected word
        // NSLog(@"In Manager %@: %@", input, translatedText);
        if( completion ) completion(translatedText);
    }];
}

- (void)sayWord:(NSString*)input {
    myTranslationService = [TranslationService sharedTranslator];
    [myTranslationService doSayWord:input];
}

- (NSString*)replaceWordsInDocument:(NSString*)htmlString{
    myDictionaryService = [DictionaryService new];
    NSDictionary* dictionary = [myDictionaryService loadDictionary];
    return [self replaceWordsInDocument:htmlString withTranslation:dictionary];
}

- (NSString*)replaceWordsInDocument:(NSString*)htmlString withTranslation:(NSDictionary*)translation {
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    // htmlString contains file content
    //NSString *htmlFile = [documentsDirectory stringByAppendingPathComponent:@"HTMLDocument.html"];
    //NSMutableString* htmlString = [NSMutableString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    // replace some words in htmlString with values in translation dictionary
    NSMutableString *string = htmlString.mutableCopy;
    for(NSString *key in translation) {
        [string replaceOccurrencesOfString:key withString:translation[key] options:0 range:NSMakeRange(0, string.length)];
    }
    
    // return the string with translations
    return string.copy;
}

@end
