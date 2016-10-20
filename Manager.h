//
//  Manager.h
//  DownloadAndDisplayLocalHTML
//

#import <Foundation/Foundation.h>

@interface Manager : NSObject

//@property (strong, nonatomic) NSString* inputText;

+ (id)sharedManager;
- (void)html2TextManager;
- (void)dictionaryManager;
- (void)locationManager;

// download services:
- (void)downloadFile:(NSURL*)fileURL;
- (void)listFiles;

// translation services:
- (void)translateWord:(NSString*)input withCompletion:(void(^)(NSString *))completion;
- (void)sayWord:(NSString*)input;
- (void)translateArray:(NSArray*)keys;
- (NSString*)replaceWordsInDocument:(NSString*)htmlString;
@end
