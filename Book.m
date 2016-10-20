//
//  Book.m
//  TextDictionary
//

#import "Book.h"

@implementation Book

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setWordAndTranslation:[aDecoder decodeObjectForKey:@"wordAndTranslation"]];
        [self setFilePath:[aDecoder decodeObjectForKey:@"filePath"]];
        [self setKeys:[aDecoder decodeObjectForKey:@"keys"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.wordAndTranslation forKey:@"wordAndTranslation"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    [aCoder encodeObject:self.keys forKey:@"keys"];
}

@end
