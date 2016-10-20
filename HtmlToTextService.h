//
//  HtmlToTextService.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/21/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HtmlToTextService : NSObject

@property (strong,nonatomic) NSString* htmlSource;
@property (strong,nonatomic) NSString* txtOutput;

- (void)serviceManager;
// no need to call these functions since they both must be performed and in a specific order
// just call serviceManager to do it
// exposed for unit testing only
- (NSString *)stringByStrippingTags:(NSString*)htmlSource;
- (NSString *)stringByRemovingExcessiveWhiteSpaces:(NSString*)input;

@end
