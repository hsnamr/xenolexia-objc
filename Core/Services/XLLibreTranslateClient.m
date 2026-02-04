//
//  XLLibreTranslateClient.m
//  Xenolexia
//
//  FOSS translation backend using LibreTranslate HTTP API (libcurl).
//

#import "XLLibreTranslateClient.h"
#import <curl/curl.h>

static size_t curlWriteCallback(char *ptr, size_t size, size_t nmemb, void *userdata) {
    NSMutableData *data = (NSMutableData *)userdata;
    if (data && ptr) {
        [data appendBytes:ptr length:size * nmemb];
    }
    return size * nmemb;
}

@implementation XLLibreTranslateClient

+ (void)translateText:(NSString *)text
       fromLanguage:(NSString *)sourceCode
         toLanguage:(NSString *)targetCode
            baseURL:(NSString *)baseURL
         completion:(void(^)(NSString *translatedText, NSError *error))completion {
    if (!text || !sourceCode || !targetCode || [baseURL length] == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"XLLibreTranslateClient" code:1 userInfo:@{ NSLocalizedDescriptionKey: @"Missing text or language or base URL" }]);
        }
        return;
    }
    NSString *urlStr = [baseURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    urlStr = [urlStr stringByAppendingString:@"/translate"];
    NSDictionary *bodyDict = @{
        @"q": text,
        @"source": sourceCode,
        @"target": targetCode,
        @"format": @"text"
    };
    NSError *jsonErr = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&jsonErr];
    if (jsonErr || !bodyData) {
        if (completion) completion(nil, jsonErr ?: [NSError errorWithDomain:@"XLLibreTranslateClient" code:2 userInfo:@{ NSLocalizedDescriptionKey: @"JSON encode failed" }]);
        return;
    }
    NSMutableData *responseData = [NSMutableData data];
    CURL *curl = curl_easy_init();
    if (!curl) {
        if (completion) completion(nil, [NSError errorWithDomain:@"XLLibreTranslateClient" code:3 userInfo:@{ NSLocalizedDescriptionKey: @"curl init failed" }]);
        return;
    }
    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_URL, [urlStr UTF8String]);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, [bodyData bytes]);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)[bodyData length]);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curlWriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, responseData);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "Xenolexia/1.0");
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    CURLcode res = curl_easy_perform(curl);
    long httpCode = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    if (res != CURLE_OK) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"XLLibreTranslateClient" code:(NSInteger)res userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:curl_easy_strerror(res)] }]);
        }
        return;
    }
    if (httpCode != 200) {
        if (completion) {
            NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"LibreTranslate HTTP %ld", nil), (long)httpCode];
            completion(nil, [NSError errorWithDomain:@"XLLibreTranslateClient" code:(NSInteger)httpCode userInfo:@{ NSLocalizedDescriptionKey: msg }]);
        }
        return;
    }
    id json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonErr];
    if (jsonErr || !json) {
        if (completion) completion(nil, jsonErr ?: [NSError errorWithDomain:@"XLLibreTranslateClient" code:4 userInfo:@{ NSLocalizedDescriptionKey: @"Invalid JSON response" }]);
        return;
    }
    NSString *translated = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        translated = [(NSDictionary *)json objectForKey:@"translatedText"];
    }
    if (![translated isKindOfClass:[NSString class]]) {
        translated = nil;
    }
    if (completion) {
        completion(translated ?: @"", translated ? nil : [NSError errorWithDomain:@"XLLibreTranslateClient" code:5 userInfo:@{ NSLocalizedDescriptionKey: @"No translatedText in response" }]);
    }
}

@end
