//
//  DownloadService.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/21/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadService : NSObject

//@property (strong,nonatomic) NSString* documentsDirectory;
//@property (strong,nonatomic) NSURL* fileURL;

//- (void)fakeManager;
// manager not needed - expose the services
- (void)listFilesInDirectory:(NSString*)documentsDirectory;
- (void)downloadFrom:(NSURL*)fileURL toDirectory:(NSString*)documentsDirectory;

@end
