//
//  SSFileSystem.h
//  SmallStep
//
//  Cross-platform file system operations

#import <Foundation/Foundation.h>


/// File system operations protocol
@protocol SSFileSystem <NSObject>

/// Get documents directory path
- (NSString *)documentsDirectory;

/// Get cache directory path
- (NSString *)cacheDirectory;

/// Get temporary directory path
- (NSString *)temporaryDirectory;

/// Get application support directory path
- (NSString *)applicationSupportDirectory;

/// Check if file exists
- (BOOL)fileExistsAtPath:(NSString *)path;

/// Create directory at path
- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error;

/// Read file contents
- (NSData *)readFileAtPath:(NSString *)path error:(NSError **)error;

/// Write data to file
- (BOOL)writeData:(NSData *)data toPath:(NSString *)path error:(NSError **)error;

/// Write string to file
- (BOOL)writeString:(NSString *)string toPath:(NSString *)path error:(NSError **)error;

/// Delete file at path
- (BOOL)deleteFileAtPath:(NSString *)path error:(NSError **)error;

/// List files in directory
- (NSArray *)listFilesInDirectory:(NSString *)path error:(NSError **)error;

/// Get file attributes
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;

@end

/// File system implementation
@interface SSFileSystem : NSObject <SSFileSystem>

+ (instancetype)sharedFileSystem;

@end

