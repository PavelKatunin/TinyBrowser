#import "BrowserViewController.h"
#import "AddressBar.h"
#import <WebKit/WebKit.h>
#import "NSLayoutConstraint+Helpers.h"
#import "SearchEngine.h"
#import "GoogleSearchEngine.h"
#import "NSString+Url.h"
#import "Macros.h"

static NSString *const kEstimatedProgressKeyPath = @"estimatedProgress";
static NSString *const kCanGoBackKeyPath = @"canGoBack";
static NSString *const kCanGoForwardKeyPath = @"canGoForward";
static NSString *const kTitleKeyPath = @"title";
static NSString *const kURLKeyPath = @"URL";
static NSString *const kLoadingKeyPath = @"loading";

typedef NS_ENUM(NSUInteger, RequestType) {
    kRequestType_LoadUrl,
    kRequestType_WebSearch
};

@interface BrowserViewController () <AddressBarDelegate,
                                     WKNavigationDelegate,
                                     WKUIDelegate>

// views
@property (nonatomic, weak) IBOutlet AddressBar *addressBar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *addressBarHeight;
@property (nonatomic, weak) NSLayoutConstraint *webViewBottomOffset;
@property (nonatomic, weak) WKWebView *webView;

@property (nonatomic, strong) id<SearchEngine> searchEngine;

- (NSArray *)createWebViewConstraints;

- (void)loadRequest:(NSURLRequest *)request;
- (void)registerObserversForWebView;
- (void)subscribeForNotification:(NSString *)name selector:(SEL)selector;
- (void)unsubscribeFromNotification:(NSString *)name;
- (void)subscribeKeyboardNotifications;
- (void)unsubscribeKeyboardNotifications;
- (RequestType)requestTypeFromString:(NSString *)string;
- (void)showErrorPageForURL:(NSString *)url;
+ (BOOL)isExternalAppUrlScheme:(NSString *)urlScheme;
- (BOOL)openUrlInOtherAppIfShould:(NSURL *)url;

@end

@implementation BrowserViewController

#pragma mark - Deallocation

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        self.searchEngine = [[GoogleSearchEngine alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:nil];
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebView *webView = [[WKWebView alloc] init];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView = webView;
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    [self.view addSubview:webView];
    [self.view addConstraints:[self createWebViewConstraints]];
    
    [self registerObserversForWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self subscribeKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribeKeyboardNotifications];
}

#pragma mark - Private methods

- (NSArray *)createWebViewConstraints {
    WKWebView *webView = self.webView;
    AddressBar *addressBar = self.addressBar;
    NSMutableArray *constraints = [NSMutableArray array];
    NSArray *horizontalConstraints = [NSLayoutConstraint horizontalConstraintsForWrappedSubview:self.webView
                                                                                     withInsets:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    [constraints addObjectsFromArray:horizontalConstraints];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[addressBar]-0-[webView]"
                                                                             views:NSDictionaryOfVariableBindings(webView, addressBar)];
    
    NSLayoutConstraint *bottomOffset = [NSLayoutConstraint constraintWithItem:webView
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.f
                                                                     constant:0.f];
    
    self.webViewBottomOffset = bottomOffset;
    
    [constraints addObject:bottomOffset];
    
    [constraints addObjectsFromArray:verticalConstraints];
    return constraints;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.webView) {
        if ([keyPath isEqualToString:kEstimatedProgressKeyPath]) {
            [self.addressBar setLoadingProgress:self.webView.estimatedProgress
                                       animated:YES];
        }
        else if ([keyPath isEqualToString:kCanGoBackKeyPath]) {
            [self.addressBar setButton:kNavigationButtonType_Prev enabled:self.webView.canGoBack];
        }
        else if ([keyPath isEqualToString:kCanGoForwardKeyPath]) {
            [self.addressBar setButton:kNavigationButtonType_Next enabled:self.webView.canGoForward];
        }
        else if ([keyPath isEqualToString:kTitleKeyPath]) {
            self.addressBar.title = self.webView.title;
        }
        else if ([keyPath isEqualToString:kURLKeyPath]) {
            if (![self.webView.URL isFileURL]) {
                self.addressBar.urlString = [self.webView.URL absoluteString];
            }
        }
        else if ([keyPath isEqualToString:kLoadingKeyPath]) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = self.webView.loading;
            self.addressBar.loadingState = self.webView.loading ? kAddressBarLoadingState_Loading : kAddressBarLoadingState_NotLoading;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
}

- (void)registerObserversForWebView {
    
    [@[kEstimatedProgressKeyPath,
      kCanGoBackKeyPath,
      kCanGoForwardKeyPath,
      kTitleKeyPath,
      kURLKeyPath,
      kLoadingKeyPath]
     
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          [self.webView addObserver:self
                         forKeyPath:obj
                            options:NSKeyValueObservingOptionNew
                            context:NULL];
      }];
}

- (void)subscribeForNotification:(NSString *)name selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:selector
                                                 name:name
                                               object:nil];
}

- (void)unsubscribeFromNotification:(NSString *)name {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:name
                                                  object:nil];
}

- (void)subscribeKeyboardNotifications {
    [self subscribeForNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShowNotification:)];
    [self subscribeForNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHideNotification:)];
}

- (void)unsubscribeKeyboardNotifications {
    [self unsubscribeFromNotification:UIKeyboardWillShowNotification];
    [self unsubscribeFromNotification:UIKeyboardDidShowNotification];
    [self unsubscribeFromNotification:UIKeyboardWillHideNotification];
    [self unsubscribeFromNotification:UIKeyboardDidHideNotification];
}

- (RequestType)requestTypeFromString:(NSString *)string {
    return [string isUrl] ? kRequestType_LoadUrl : kRequestType_WebSearch;
}

- (void)showErrorPageForURL:(NSString *)url {
    // TODO: fix bug for iOS 8 http://stackoverflow.com/questions/24882834/wkwebview-not-working-in-ios-8-beta-4

    NSString *alertMesage = [NSString stringWithFormat:NSLocalizedString(@"idsLoadingPageErrorMessageFormat",
                                                                         @""),
                             url];
    NSString *title = NSLocalizedString(@"idsLoadingPageErrorTitle", @"");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:alertMesage
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                     }];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{
                     }];
}

+ (BOOL)isExternalAppUrlScheme:(NSString*)urlScheme {
    static NSArray* sSupportedUrlSchemes = nil;
    if (sSupportedUrlSchemes == nil) {
        sSupportedUrlSchemes = @[@"http", @"https", @"file"];
    }
    return (urlScheme != nil) && ![sSupportedUrlSchemes containsObject:urlScheme];
}

- (BOOL)openUrlInOtherAppIfShould:(NSURL *)url {
    UIApplication *app = [UIApplication sharedApplication];
    BOOL opened = NO;
    if ([[self class] isExternalAppUrlScheme:url.scheme] && [app canOpenURL:url]) {
        [app openURL:url];
        opened = YES;
    }
    return opened;
}

#pragma mark - AddressBarDelegate

- (void)addressBar:(AddressBar *)bar didRequestString:(NSString *)string {
    RequestType type = [self requestTypeFromString:string];
    NSURL *url = nil;
    switch (type) {
        case kRequestType_WebSearch:
            url = [self.searchEngine makeSearchURLWithText:string];
            break;
        case kRequestType_LoadUrl:
            url = [NSURL URLWithString:[string stringByAddingDefaultScheme:@"http" defaultDomain:nil]];
            break;
        default:
            NSAssert(NO, @"Unsupported type");
            break;
    }

    [self loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)addressBarDidRequestNextPage:(AddressBar *)bar {
    [self.webView goForward];
}

- (void)addressBarDidRequestPrevPage:(AddressBar *)bar {
    [self.webView goBack];
}

- (void)addressBarDidRequestReloading:(AddressBar *)bar {
    [self.webView reload];
}

- (void)addressBarDidRequestCanceling:(AddressBar *)bar {
    [self.webView stopLoading];
    [self.addressBar finishLoadingProgressAnimated:NO];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.addressBar finishLoadingProgressAnimated:YES];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self.addressBar startLoadingProgressAnimated:YES];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.addressBar finishLoadingProgressAnimated:YES];

    NSURL *url = [NSURL URLWithString:error.userInfo[NSURLErrorFailingURLStringErrorKey]];
    if (![self openUrlInOtherAppIfShould:url]) {
        [self showErrorPageForURL:error.userInfo[NSURLErrorFailingURLStringErrorKey]];
    }
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        NSURL *url = navigationAction.request.URL;
        [self openUrlInOtherAppIfShould:url];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - Keyboard notifications


- (void)keyboardWillShowNotification:(NSNotification *)notification {
    if (self.addressBar.editingState == kAddressBarEditingState_Editing) {
        NSDictionary *info = [notification userInfo];
        
        const CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        const CGPoint keyboardTargetOrigin = [self.view convertRect:keyboardFrame
                                                           fromView:nil].origin;
        const CGFloat viewOverlapValue = CGRectGetHeight(self.view.bounds) - keyboardTargetOrigin.y;
        
        self.webViewBottomOffset.constant = -viewOverlapValue;
        [self.view setNeedsUpdateConstraints];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[info[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        [self.view layoutIfNeeded];
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
        
    self.webViewBottomOffset.constant = 0;
    [self.view setNeedsUpdateConstraints];
        
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[info[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
        
    [UIView commitAnimations];
}

@end
