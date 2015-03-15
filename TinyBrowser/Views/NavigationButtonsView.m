#import "NavigationButtonsView.h"
#import "NSLayoutConstraint+Helpers.h"

static const CGFloat kButtonHeight = 22.f;
static const CGFloat kButtonWidth = 22.f;
static const CGSize kNavigationButtonSize = { kButtonWidth, kButtonHeight};
static const CGFloat kMargin = 8.f;

@interface NavigationButtonsView ()

@property (nonatomic, weak) UIButton *nextButton;
@property (nonatomic, weak) UIButton *prevButton;

- (UIButton *)createNavigationButtonWithImageName:(NSString *)imageName
                                         action:(SEL)action;
- (void)nextButtonTapped:(id)sender;
- (IBAction)prevButtonTapped:(id)sender;

- (void)createSubviews;
- (void)createLayout;

@end

@implementation NavigationButtonsView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.clipsToBounds = YES;
        
        [self createSubviews];
        [self createLayout];
    }
    return self;
}

#pragma mark - Public

- (void)setButton:(NavigationButtonType)buttonType enabled:(BOOL)enabled {
    UIButton *button = nil;
    switch (buttonType) {
        case kNavigationButtonType_Prev:
            button = self.prevButton;
            break;
        case kNavigationButtonType_Next:
            button = self.nextButton;
            break;
        default:
            NSAssert(NO, @"Unsupported button type");
            break;
    }
    button.enabled = enabled;
}

+ (CGSize)preferdSize {
    return CGSizeMake(kButtonWidth * 2 + kMargin * 3, kButtonHeight);
}

#pragma mark - Private

- (void)createSubviews {
    UIButton *prevButton = [self createNavigationButtonWithImageName:@"back.png"
                                                              action:@selector(prevButtonTapped:)];
    self.prevButton = prevButton;
    [self addSubview:prevButton];
    
    UIButton *nextButton = [self createNavigationButtonWithImageName:@"next.png"
                                                              action:@selector(nextButtonTapped:)];
    self.nextButton = nextButton;
    [self addSubview:nextButton];
}

- (void)createLayout {
    UIButton *nextButton = self.nextButton;
    UIButton *prevButton = self.prevButton;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[prevButton]-8-[nextButton]-8-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(nextButton, prevButton)]];
    
    NSLayoutConstraint *prevButtonVerticalConstraint = [NSLayoutConstraint constraintForCenterByYView:prevButton
                                                                                             withView:self];
    NSLayoutConstraint *nextButtonVerticalConstraint = [NSLayoutConstraint constraintForCenterByYView:nextButton
                                                                                             withView:self];
    
    [self addConstraints:@[prevButtonVerticalConstraint, nextButtonVerticalConstraint]];
    
    NSArray *nextButtonSize = [NSLayoutConstraint constraintsForView:nextButton withSize:kNavigationButtonSize];
    [self addConstraints:nextButtonSize];
    
    NSArray *prevButtonSize = [NSLayoutConstraint constraintsForView:prevButton withSize:kNavigationButtonSize];
    [self addConstraints:prevButtonSize];
}

- (UIButton *)createNavigationButtonWithImageName:(NSString *)imageName
                                         action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.enabled = NO;
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setAdjustsImageWhenDisabled:YES];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (IBAction)nextButtonTapped:(id)sender {
    [self.delegate navigationButtonsView:self tappedButton:kNavigationButtonType_Next];
}

- (IBAction)prevButtonTapped:(id)sender {
    [self.delegate navigationButtonsView:self tappedButton:kNavigationButtonType_Prev];
}

@end
