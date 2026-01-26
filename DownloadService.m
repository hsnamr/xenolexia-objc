//
//  DownloadService.m
//  DownloadAndDisplayLocalHTML
//

#import "DownloadService.h"

// SSFileSystem is compiled directly - use relative path
#import "../SmallStep/SmallStep/Core/SSFileSystem.h"

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
    NSArray *files = [_fileSystem listFilesInDirectory:documentsDirectory error:&error];
    if (error) {
        NSLog(@"Error listing files: %@", error);
    } else {
        NSLog(@"%@", files);
    }
}

- (void)downloadFrom:(NSURL*)fileURL toDirectory:(NSString*)documentsDirectory {
    // download and write file to Documents directory using SmallStep
    // Note: NSURLSession with blocks not supported in GNUStep
    // For now, this is a stub - full implementation would require delegate-based NSURLConnection
    NSLog(@"Download from %@ to %@ (block-based API not supported in GNUStep)", fileURL, documentsDirectory);
}

@end
