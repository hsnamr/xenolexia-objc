//
//  DownloadService.m
//  Xenolexia
//
//  Uses libcurl (FOSS, C) for portable HTTP(S) downloads on Linux/GNUStep and other platforms.
//

#import "DownloadService.h"
#import "SSFileSystem.h"
#import <curl/curl.h>
#import <string.h>

/** Download URL to a file path using libcurl (FOSS). Returns 0 on success, non-zero on failure. */
static int downloadURLToPath(const char *urlCStr, const char *pathCStr) {
    FILE *fp = fopen(pathCStr, "wb");
    if (!fp) return -1;
    CURL *curl = curl_easy_init();
    if (!curl) {
        fclose(fp);
        return -2;
    }
    curl_easy_setopt(curl, CURLOPT_URL, urlCStr);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, (curl_write_callback)fwrite);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "Xenolexia/1.0");
    CURLcode res = curl_easy_perform(curl);
    long httpCode = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
    curl_easy_cleanup(curl);
    fclose(fp);
    if (res != CURLE_OK || (httpCode != 200 && httpCode != 0))
        return (int)res ? (int)res : (int)httpCode;
    return 0;
}

@implementation DownloadService

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileSystem = [SSFileSystem sharedFileSystem];
    }
    return self;
}

- (void)listFilesInDirectory:(NSString*)documentsDirectory {
    NSError *error = nil;
    NSArray *files = [_fileSystem listFilesInDirectory:documentsDirectory error:&error];
    if (error) {
        NSLog(@"Error listing files: %@", error);
    } else {
        NSLog(@"%@", files);
    }
}

- (void)downloadFrom:(NSURL*)fileURL toDirectory:(NSString*)documentsDirectory {
    if (!fileURL || !documentsDirectory) {
        NSLog(@"DownloadService: nil URL or directory");
        return;
    }
    NSString *filename = [fileURL lastPathComponent];
    if ([filename length] == 0) filename = @"download";
    NSString *destPath = [documentsDirectory stringByAppendingPathComponent:filename];
    const char *urlC = [[fileURL absoluteString] UTF8String];
    const char *pathC = [destPath UTF8String];
    if (!urlC || !pathC) {
        NSLog(@"DownloadService: invalid URL or path");
        return;
    }
    int err = downloadURLToPath(urlC, pathC);
    if (err == 0) {
        NSLog(@"DownloadService: saved to %@", destPath);
    } else {
        NSLog(@"DownloadService: download failed (error %d) for %@", err, fileURL);
    }
}

@end
