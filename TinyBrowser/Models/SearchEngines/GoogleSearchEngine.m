#import "GoogleSearchEngine.h"
#import "GoogleSearchQueryKeys.h"
#import "NSURLComponents+Helpers.h"

NSString *const kSearchEngineGoogleName = @"Google";
NSString *const kSearchEngineGoogleMainPageLink = @"https://www.google.com";

static NSString *const kGoogleSecondLevelDomain = @"google";
static NSString *const kWwwDomain = @"www";
static NSString *const kSearchEngineGoogleLinkBase = @"http://www.google.com/search?gcx=x&ie=UTF-8&oe=UTF-8&client=safari&";

@interface GoogleSearchEngine ()

- (BOOL)isKindOfGoogleMainPageUrl:(NSURL *)url;
- (BOOL)isGoogleSecondLevelDomain:(NSString *)domain;
- (NSArray *)domainComponentsByRemovingWwwDomainFromComponents:(NSArray *)components;

@end


@implementation GoogleSearchEngine

#pragma mark - Public

- (NSString *)name {
    return kSearchEngineGoogleName;
}

- (NSURL *)makeSearchURLWithText:(NSString *)text {
    NSString *searchLinkTextPart = [NSString stringWithFormat:@"%@=%@",
                                    kGoogleSearchQueryTextKey,
                                    [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *link = [kSearchEngineGoogleLinkBase stringByAppendingString:searchLinkTextPart];
    return [NSURL URLWithString:link];
}

- (NSURL *)mainPageUrl {
    return [NSURL URLWithString:kSearchEngineGoogleMainPageLink];
}

- (BOOL)ajaxListenerShouldBeInjectedIntoPageAtUrl:(NSURL *)url {
    return [self isKindOfGoogleMainPageUrl:url];
}

- (BOOL)pagesShouldBeInjectedWithAJAXListener {
    return YES;
}

#pragma mark - Private

- (BOOL)isKindOfGoogleMainPageUrl:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSArray *domainComponents = [components hostComponents];
    domainComponents = [self domainComponentsByRemovingWwwDomainFromComponents:domainComponents];
    return (domainComponents.count == 2 && [self isGoogleSecondLevelDomain:domainComponents[0]]);
}

- (NSArray *)domainComponentsByRemovingWwwDomainFromComponents:(NSArray *)components {
    NSArray *resultComponents = components;
    if (components.count > 0 && [components.firstObject caseInsensitiveCompare:kWwwDomain] == NSOrderedSame) {
        
        resultComponents = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
    }
    return resultComponents;
}

- (BOOL)isGoogleSecondLevelDomain:(NSString *)domain {
    return [domain caseInsensitiveCompare:kGoogleSecondLevelDomain] == NSOrderedSame;
}

@end
