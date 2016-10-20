//
//  HtmlToTextService.m
//  DownloadAndDisplayLocalHTML
//

#import "HtmlToTextService.h"

@implementation HtmlToTextService

- (void)serviceManager {
    NSString* html2text = [self stringByStrippingTags:self.htmlSource];
    
    // Remove multi-spaces and line breaks
    NSString* finalString = [self stringByRemovingExcessiveWhiteSpaces:html2text];
    
    // additional cleanup for whatever tags that might have been missed
    finalString = [finalString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
    finalString = [finalString stringByReplacingOccurrencesOfString:@"&trade;" withString:@""];
    finalString = [finalString stringByReplacingOccurrencesOfString:@"&lt;FRAMESET&gt;" withString:@""];
    finalString = [finalString stringByReplacingOccurrencesOfString:@"&#x00a9" withString:@""];
    self.txtOutput = finalString;
}

// not perfect but close enough -- maybe there is a library that does a better job?
// Strip HTML tags
- (NSString *)stringByStrippingTags:(NSString*)htmlSource {
    
    // Find first & and short-cut if we can
    NSUInteger ampIndex = [htmlSource rangeOfString:@"<" options:NSLiteralSearch].location;
    if (ampIndex == NSNotFound) {
        return @""; // return empty string as no  HTML tags were found
        // caller should test for this return value
    }
    
    // Scan and find all tags
    NSScanner *scanner = [NSScanner scannerWithString:htmlSource];
    [scanner setCharactersToBeSkipped:nil];
    NSMutableSet *tags = [[NSMutableSet alloc] init];
    NSString *tag;
    do {
        // Scan up to <
        tag = nil;
        [scanner scanUpToString:@"<" intoString:NULL];
        [scanner scanUpToString:@">" intoString:&tag];
        
        // Add to set
        if (tag) {
            NSString *t = [[NSString alloc] initWithFormat:@"%@>", tag];
            [tags addObject:t];
        }
        
    } while (![scanner isAtEnd]);
    
    // Scan and find all tags
    NSScanner *scanner2 = [NSScanner scannerWithString:htmlSource];
    [scanner2 setCharactersToBeSkipped:nil];
    do {
        // Scan up to <
        tag = nil;
        [scanner2 scanUpToString:@"&lt;" intoString:NULL];
        [scanner2 scanUpToString:@"&gt;" intoString:&tag];
        
        // Add to set
        if (tag) {
            NSString *t = [[NSString alloc] initWithFormat:@"%@&gt;", tag];
            [tags addObject:t];
        }
        
    } while (![scanner2 isAtEnd]);
    
    NSScanner *scanner3 = [NSScanner scannerWithString:htmlSource];
    [scanner3 setCharactersToBeSkipped:nil];
    do {
        // Scan up to <
        tag = nil;
        [scanner3 scanUpToString:@"&lt;" intoString:NULL];
        [scanner3 scanUpToString:@">" intoString:&tag];
        
        // Add to set
        if (tag) {
            NSString *t = [[NSString alloc] initWithFormat:@"%@>", tag];
            [tags addObject:t];
        }
        
    } while (![scanner3 isAtEnd]);
    
    // Strings
    NSMutableString *result = [[NSMutableString alloc] initWithString:htmlSource];
    
    // Replace tags
    for (NSString *t in tags) {
        // Replace
        [result replaceOccurrencesOfString:t withString:@" " options:NSLiteralSearch range:NSMakeRange(0, result.length)];
    }
    
    return result;
}

// Remove newlines and white space from strong
- (NSString *)stringByRemovingExcessiveWhiteSpaces:(NSString*)input {
    
    // Strange New lines:
    //	Next Line, U+0085
    //	Form Feed, U+000C
    //	Line Separator, U+2028
    //	Paragraph Separator, U+2029
    
    // Scanner
    NSScanner *scanner = [[NSScanner alloc] initWithString:input];
    [scanner setCharactersToBeSkipped:nil];
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *temp;
    NSCharacterSet *newLineAndWhitespaceCharacters = [NSCharacterSet characterSetWithCharactersInString:
                                                      [NSString stringWithFormat:@" \t\n\r%C%C%C%C", 0x0085, 0x000C, 0x2028, 0x2029]];
    // Scan
    while (![scanner isAtEnd]) {
        
        // Get non new line or whitespace characters
        temp = nil;
        [scanner scanUpToCharactersFromSet:newLineAndWhitespaceCharacters intoString:&temp];
        if (temp) [result appendString:temp];
        
        // Replace with a space
        if ([scanner scanCharactersFromSet:newLineAndWhitespaceCharacters intoString:NULL]) {
            if (result.length > 0 && ![scanner isAtEnd]) // Dont append space to beginning or end of result
                [result appendString:@" "];
        }
        
    }
    
    return result;
}

@end
