#import "NSURLComponents+Helpers.h"

static NSString *const kDefaultHostLevelSeparator = @".";

@implementation NSURLComponents (Helpers)

- (NSArray *)hostComponents {
    return [[self host] componentsSeparatedByString:kDefaultHostLevelSeparator];
}

@end
