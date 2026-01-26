//
//  TranslationService.m
//  DownloadAndDisplayLocalHTML
//

#import "TranslationService.h"
#import "MSTranslateAccessTokenRequester.h"
#import "MSTranslateVendor.h"
@import AVFoundation;

@interface TranslationService()
@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation TranslationService

+ (id)sharedTranslator {
    static TranslationService *sharedTranslator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTranslator = [[self alloc] init];
    });
    return sharedTranslator;
}

- (void)doSayWord:(NSString*)input {
    //Must be called before used to MSTranslateVendor
    [[MSTranslateAccessTokenRequester sharedRequester] requestSynchronousAccessToken:CLIENT_ID clientSecret:CLIENT_SECRET];
    [self doSay:input ofLanguage:@"ja"];
}

-(void)doTranslateArray:(NSArray*)keysArray withCompletion:(id)completion {
    //Must be called before used to MSTranslateVendor
    [[MSTranslateAccessTokenRequester sharedRequester] requestSynchronousAccessToken:CLIENT_ID clientSecret:CLIENT_SECRET];
    [self doTranslateArray:keysArray from:@"en" to:@"ja" withCompletion:completion];
}

-(void)doTranslateArray:(NSArray*)keysArray from:(NSString*)lang1 to:(NSString*)lang2 withCompletion:(id)completion {
    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
    
    [vendor requestTranslateArray:keysArray from: lang1 to:lang2 blockWithSuccess:^(NSArray *translatedTextArray) {
        
        //NSLog(@"translatedTextArray:%@", translatedTextArray);
        if( completion ) completion(translatedTextArray);
    } failure:^(NSError *error) {
        
    }];
}

-(void)doTranslateWord:(NSString*)input withCompletion:(void(^)(NSString *))completion {
    //Must be called before used to MSTranslateVendor
    [[MSTranslateAccessTokenRequester sharedRequester] requestAsynchronousAccessToken:CLIENT_ID clientSecret:CLIENT_SECRET];
    [self doTranslateWord:input from:@"ja" to:@"en" withCompletion:completion];
}

-(void)doTranslateWord:(NSString*)input from:(NSString*)lang1 to:(NSString*)lang2 withCompletion:(id)completion {
    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
    
    [vendor requestTranslate:input from:lang1 to:lang2 blockWithSuccess:^(NSString *translatedText) {
        
        //NSLog(@"%@: %@", input, translatedText);
        if( completion ) completion(translatedText);
    } failure:^(NSError *error) {
        
    }];
}

// update this to pronounce word(s) selected using UIMenuController
- (void)doSay:(NSString*)input ofLanguage:(NSString*)source{
    
    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
    
    //NSString* source = @"ja";
    
    [vendor requestSpeakingText:input language:source blockWithSuccess:
     ^(NSData *streamData)
     {
         NSError *error;
         
         self.player = [[AVAudioPlayer alloc] initWithData:streamData error:&error];
         [_player play];
     } failure:
     ^(NSError *error)
     {
         NSLog(@"error_speak: %@", error);
     }];
}


//#pragma mark DO NOT USE - FOR TESTING ONLY
//
//- (void)doPronouncePlaceholder{
//    
//    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
//    
//    [vendor requestSpeakingText:@"これはテストです。よろしくお願いします" language:@"ja" blockWithSuccess:
//     ^(NSData *streamData)
//     {
//         NSError *error;
//         
//         self.player = [[AVAudioPlayer alloc] initWithData:streamData error:&error];
//         [_player play];
//     } failure:
//     ^(NSError *error)
//     {
//         NSLog(@"error_speak: %@", error);
//     }];
//}
//
//// update this to translate the value in the WordAndTranslation dictionary in Book object
//- (void)doTranslatePlaceholder {
//    
//    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
//    
//    [vendor requestTranslateArray:@[@"今日は木曜日です", @"新幹線は速いです", @"日本語は難しくないです"] from: @"ja" to:@"en" blockWithSuccess:^(NSArray *translatedTextArray) {
//        
//        NSLog(@"translatedTextArray:%@", translatedTextArray);
//    } failure:^(NSError *error) {
//        
//    }];
//}
//
////// update this to translate the value in the WordAndTranslation dictionary in Book object
//- (void)doTranslate:(NSString*)input from:(NSString*)source to:(NSString*)target forInstance:(id)sender returns:(SEL)returnValue {
//    
//    MSTranslateVendor *vendor = [[MSTranslateVendor alloc] init];
//    
//    //NSString* target = @"ja";
//    //NSString* source = @"en";
//    
//    [vendor requestTranslate:input from:source to:target blockWithSuccess:^(NSString *translatedText) {
//        
//        NSLog(@"translatedText:%@", translatedText);
//        [sender performSelector:returnValue withObject: translatedText];
//    } failure:^(NSError *error) {
//        
//    }];
//}


@end
