//
//  DownloadService.m
//  DownloadAndDisplayLocalHTML
//

#import "DownloadService.h"
#import <SmallStep/SmallStep.h>

@interface DownloadService ()
@property (nonatomic, strong) SSFileSystem *fileSystem;
@end

@implementation DownloadService

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileSystem = [SSFileSystem sharedFileSystem];
    }
    return self;
}

- (void)listFilesInDirectory:(NSString*)documentsDirectory {
    // list all files in Documents directory using SmallStep
    NSError *error = nil;
    NSArray *files = [self.fileSystem listFilesInDirectory:documentsDirectory error:&error];
    if (error) {
        NSLog(@"Error listing files: %@", error);
    } else {
        NSLog(@"%@", files);
    }
}

- (void)downloadFrom:(NSURL*)fileURL toDirectory:(NSString*)documentsDirectory {
    // download and write file to Documents directory using SmallStep
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:fileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(!error) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[response suggestedFilename]];
            
            // check if file exists, return if true
            if ([self.fileSystem fileExistsAtPath:filePath]){
                NSLog(@"File already exists, return");
                return;
            }
            
            // write file using SmallStep
            NSError *writeError = nil;
            BOOL success = [self.fileSystem writeData:data toPath:filePath error:&writeError];
            if (!success) {
                NSLog(@"Failed to write file: %@", writeError);
            }
            
        } else {
            NSLog(@"%@",error);
        }
        
    }] resume];
}

@end
