#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "GoogleSearchEngine.h"
#import "NSURLComponents+Helpers.h"
#import "NSString+Url.h"
#import "Macros.h"

@interface TinyBrowserTests : XCTestCase

@end

@implementation TinyBrowserTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGoogleSearchEngine {
    GoogleSearchEngine *engine = [[GoogleSearchEngine alloc] init];
    NSURL *searchUrl = [engine makeSearchURLWithText:@"wiki"];
    NSURL *testURL = [NSURL URLWithString:@"http://www.google.com/search?gcx=x&ie=UTF-8&oe=UTF-8&client=safari&q=wiki"];
    XCTAssertEqualObjects(searchUrl, testURL);
    
    NSURL *searchUrl2 = [engine makeSearchURLWithText:@"apple"];
    NSURL *testURL2 = [NSURL URLWithString:@"http://www.google.com/search?gcx=x&ie=UTF-8&oe=UTF-8&client=safari&q=apple"];
    XCTAssertEqualObjects(searchUrl2, testURL2);
}

- (void)testURLComponentsHelpers {
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:@"https://developer.apple.com/somepage?das=aaa"] resolvingAgainstBaseURL:YES];
    NSArray *hostComponents = [components hostComponents];
    NSString *component1 = @"developer";
    NSString *component2 = @"apple";
    NSString *component3 = @"com";
    XCTAssert([hostComponents indexOfObject:component1] != NSNotFound &&
              [hostComponents indexOfObject:component2] != NSNotFound &&
              [hostComponents indexOfObject:component3] != NSNotFound, @"Here is not one of the required components");
}

- (void)testStringURLExtensions {
    NSString *testString1 = @"google.com";
    XCTAssert([testString1 isUrl], @"Incorrect URL test");
    
    NSString *testString2 = @"google.c";
    XCTAssert(![testString2 isUrl], @"Incorrect URL test");
    
    NSString *testString3 = @"wiki";
    XCTAssert(![testString3 isUrl], @"Incorrect URL test");
    
    NSString *testString4 = @"https://lenta.ru?abs=asd&asdas=fds";
    XCTAssert([testString4 isUrl], @"Incorrect URL test");
    
    NSString *testString5 = @"#*#*#*#*#?";
    XCTAssert(![testString5 isUrl], @"Incorrect URL test");
    
    NSString *testString6 = @"https://apple.com";
    XCTAssertEqualObjects(testString6, [@"apple.com" stringByAddingDefaultScheme:@"https" defaultDomain:nil]);
    
    NSString *testString7 = @"https://apple.ru";
    XCTAssertEqualObjects(testString7, [@"apple" stringByAddingDefaultScheme:@"https" defaultDomain:@"ru"]);
}

- (void)testMacros {
    int limit1 = limit(10, 2, 4);
    XCTAssertEqual(limit1, 4);
    
    int limit2 = limit(10, 4, 11);
    XCTAssertEqual(limit2, 10);
    
    int limit3 = limit(1, 111, 122);
    XCTAssertEqual(limit3, 111);
}

@end
