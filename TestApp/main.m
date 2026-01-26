//
//  main.m
//  XenolexiaTestApp
//
//  Simple test app to verify SmallStep integration

#import <Foundation/Foundation.h>
#import "SSPlatform.h"
#import "SSFileSystem.h"

int main(int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSLog(@"=== Xenolexia Test App ===");
        NSLog(@"Platform: %@", [SSPlatform platformName]);
        NSLog(@"Version: %@", [SSPlatform platformVersion]);
        
        // Test platform detection
        if ([SSPlatform isLinux]) {
            NSLog(@"✓ Running on Linux (GNUStep)");
        } else if ([SSPlatform isMacOS]) {
            NSLog(@"✓ Running on macOS");
        } else if ([SSPlatform isiOS]) {
            NSLog(@"✓ Running on iOS");
        } else if ([SSPlatform isWindows]) {
            NSLog(@"✓ Running on Windows");
        } else {
            NSLog(@"⚠ Unknown platform");
        }
        
        // Test file system
        SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
        
        NSLog(@"\n=== File System Paths ===");
        NSLog(@"Documents: %@", [fileSystem documentsDirectory]);
        NSLog(@"Cache: %@", [fileSystem cacheDirectory]);
        NSLog(@"Temp: %@", [fileSystem temporaryDirectory]);
        NSLog(@"App Support: %@", [fileSystem applicationSupportDirectory]);
        
        // Test file operations
        NSLog(@"\n=== File Operations ===");
        NSString *testFile = [[fileSystem temporaryDirectory] stringByAppendingPathComponent:@"test.txt"];
        NSString *testContent = @"Hello from Xenolexia Test App!";
        
        NSError *error = nil;
        BOOL success = [fileSystem writeString:testContent toPath:testFile error:&error];
        if (success) {
            NSLog(@"✓ Successfully wrote test file");
            
            NSData *readData = [fileSystem readFileAtPath:testFile error:&error];
            if (readData) {
                NSString *readContent = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
                NSLog(@"✓ Successfully read test file: %@", readContent);
                
                // Clean up
                [fileSystem deleteFileAtPath:testFile error:&error];
                NSLog(@"✓ Cleaned up test file");
            } else {
                NSLog(@"✗ Failed to read test file: %@", error);
            }
        } else {
            NSLog(@"✗ Failed to write test file: %@", error);
        }
        
        NSLog(@"\n=== Test Complete ===");
    
    [pool drain];
    return 0;
}
