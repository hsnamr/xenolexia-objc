//
//  Manager.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/22/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
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
