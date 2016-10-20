//
//  Book.h
//  TextDictionary
//
//  Created by admin on 5/21/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Book : NSObject <NSCoding>

@property (strong,nonatomic) NSMutableDictionary* wordAndTranslation; // key:value pair for source and target language
@property (strong,nonatomic) NSMutableArray* keys; // keys
// will be implemented if time allows - for now the app is limited to one hard-coded book, source is English and target is French
@property (strong, nonatomic) NSString* filePath; // file path
//@property (strong, nonatomic) NSString* targetLanguage; // deduced from location services or locale
//@property (strong, nonatomic) NSString* sourceLanguge; // deduced from location services or locale
@end
