#import <Foundation/Foundation.h>

@interface NSString (Url)

- (NSString *)stringByAddingDefaultScheme:(NSString *)defaultScheme defaultDomain:(NSString *)defaultDomain;
- (NSRange)urlSchemeRange;
- (NSRange)urlHostRange;
- (NSString*)stringByInsertingString:(NSString*)string atIndex:(NSUInteger)loc;
- (BOOL)isUrl;

@end
