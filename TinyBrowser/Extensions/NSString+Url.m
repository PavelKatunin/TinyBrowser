#import "NSString+Url.h"

static NSString* const kUrlRegexPattern = @"^(https?:\\/\\/)?([\\da-z\\.\\-_]+)\\.([a-z\\.]{2,6})([\\/\\w\\?\\.\\-_~:/\\[\\]#@\\!\\$&%\'\\(\\)\\*\\+,;=]*)*\\/?$";

@implementation NSString (Url)

- (NSString *)stringByAddingDefaultScheme:(NSString *)defaultScheme defaultDomain:(NSString *)defaultDomain {
    NSString* newString = self;
    if (newString.length > 0) {
        NSRange schemeRange = [newString urlSchemeRange];
        if ((defaultScheme != nil) && (schemeRange.location == NSNotFound)) {
            newString = [[NSString stringWithFormat:@"%@://", defaultScheme] stringByAppendingString:newString];
        }
        NSRange hostRange = [newString urlHostRange];
        if ((defaultDomain != nil) && (hostRange.length > 0) &&
            ([newString rangeOfString:@"." options:0 range:hostRange].location == NSNotFound)) {
            newString = [newString stringByInsertingString:[NSString stringWithFormat:@".%@", defaultDomain] atIndex:hostRange.location + hostRange.length];
        }
    }
    return newString;
}

- (NSRange)urlSchemeRange {
    NSUInteger pos = [self rangeOfString:@"://" options:NSCaseInsensitiveSearch].location;
    return (pos != NSNotFound) ? NSMakeRange(0, pos) : NSMakeRange(NSNotFound, 0);
}

- (NSRange)urlHostRange {
    NSRange schemeRange = [self urlSchemeRange];
    NSUInteger hostPos = (schemeRange.location != NSNotFound) ? schemeRange.location + schemeRange.length + 3 : 0;
    NSUInteger pos = [self rangeOfString:@"/" options:0 range:NSMakeRange(hostPos, self.length - hostPos)].location;
    NSUInteger hostLen = ((pos != NSNotFound) ? pos : self.length) - hostPos;
    return NSMakeRange(hostPos, hostLen);
}

- (NSString*)stringByInsertingString:(NSString*)string atIndex:(NSUInteger)loc {
    NSMutableString* newString = [self mutableCopy];
    [newString insertString:string atIndex:loc];
    return newString;
}

- (BOOL)isUrl {
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:kUrlRegexPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSTextCheckingResult* match = [regex firstMatchInString:self
                                                    options:0
                                                      range:NSMakeRange(0, [self length])];
    return match != nil;
}

@end
