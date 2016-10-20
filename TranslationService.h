//
//  TranslationService.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/22/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranslationService : NSObject

+ (id)sharedTranslator;

- (void)doSayWord:(NSString*)input;
- (void)doTranslateWord:(NSString*)input withCompletion:(void(^)(NSString *))completion;
- (void)doTranslateArray:(NSArray*)keysArray withCompletion:(void(^)(NSArray *))completion;

@end
