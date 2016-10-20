//
//  DownloadService.m
//  DownloadAndDisplayLocalHTML
//

#import "DownloadService.h"

@implementation DownloadService

- (void)listFilesInDirectory:(NSString*)documentsDirectory {
    // list all files in Documents directory
    NSArray* files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    NSLog(@"%@", files);
}

- (void)downloadFrom:(NSURL*)fileURL toDirectory:(NSString*)documentsDirectory {
    // download and write file to Documents directory
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:fileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(!error) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[response suggestedFilename]];
            
            // check if file exists, return if true
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:filePath]){
                NSLog(@"File already exists, return");
                return;
            }
            
            // write file
            [data writeToFile:filePath atomically:YES];
            
        } else {
            NSLog(@"%@",error);
        }
        
    }] resume];
}

@end
