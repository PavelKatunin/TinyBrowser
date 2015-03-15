#import <Foundation/Foundation.h>

@protocol SearchEngine <NSObject>
@required
@property (nonatomic, retain, readonly) NSString* name;

- (NSURL*)makeSearchURLWithText:(NSString*)text;
- (NSURL *)mainPageUrl;

@end