#import "LoadingProgressView.h"
#import "Macros.h"
#import "UIColor+Browser.h"

static const NSTimeInterval kAnimationDurationCoefficient = 0.5f;
static const CGFloat kLoadingProgressMin = 0.0f;
static const CGFloat kLoadingProgressMax = 1.0f;

@interface LoadingProgressView ()

@property (nonatomic, strong) UIView* progressView;

- (void)createLayout;
- (void)relayout;
- (CGRect)calculateProgressViewFrame;

- (void)setLoadingProgress:(double)loadingProgress
                  animated:(BOOL)animated
            animationSpeed:(CGFloat)animationSpeed
                completion:(void(^)())completion;

@end

@implementation LoadingProgressView

#pragma mark - Properties

@synthesize progressView = _progressView;
@synthesize loadingProgress = _loadingProgress;


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self createLayout];
    }
    return self;
}


#pragma mark - UIView implementation

- (void)layoutSubviews {
    [super layoutSubviews];
    [self relayout];
}


#pragma mark - UI methods

- (void)createLayout {
    CGRect viewBounds = self.bounds;
    CGRect progressFrame = CGRectMake(0.f, 0.f, 0.f, viewBounds.size.height);
    
    self.backgroundColor = [UIColor clearColor];
    
    self.progressView = [[UIView alloc] initWithFrame:progressFrame];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.progressView.hidden = YES;
    self.progressView.backgroundColor = [UIColor skinColor];
    [self addSubview:self.progressView];
}

- (void)relayout {
    self.progressView.frame = [self calculateProgressViewFrame];
}

- (CGRect)calculateProgressViewFrame {
    CGRect viewBounds = self.bounds;
    CGFloat progressViewWidth = viewBounds.size.width * _loadingProgress;
    return CGRectMake(self.progressView.frame.origin.x,
                      self.progressView.frame.origin.y,
                      progressViewWidth,
                      self.progressView.frame.size.height);
}


#pragma mark - Progress methods

- (void)setLoadingProgress:(double)loadingProgress {
    [self setLoadingProgress:loadingProgress animated:NO];
}

- (void)setLoadingProgress:(double)loadingProgress animated:(BOOL)animated {
    [self setLoadingProgress:loadingProgress
                    animated:animated
              animationSpeed:kAnimationDurationCoefficient
                  completion:nil];
}

- (void)setLoadingProgress:(double)loadingProgress
                  animated:(BOOL)animated animationSpeed:(CGFloat)animationSpeed
                completion:(void(^)())completion {
    
    CGFloat oldLoadingProgress = _loadingProgress;
    _loadingProgress = limit(loadingProgress, kLoadingProgressMin, kLoadingProgressMax);
    
    CGRect progressViewFrame = [self calculateProgressViewFrame];
    
    void (^animations)() = ^{
        _progressView.frame = progressViewFrame;
    };
    void (^animationsCompletion)(BOOL finished) = ^(BOOL finished) {
        if (finished && (completion != nil)) {
            completion();
        }
    };
    
    NSTimeInterval animationDuration = ABS(loadingProgress - oldLoadingProgress) * animationSpeed;
    if (animated && (animationDuration > 0) && oldLoadingProgress < _loadingProgress) {
        [UIView animateWithDuration:animationDuration
                         animations:animations
                         completion:animationsCompletion];
    }
    else {
        animations();
        animationsCompletion(YES);
    }
}

- (void)startLoadingProgressAnimated:(BOOL)animated {
    BlockWeakSelf wSelf = self;
    [self setLoadingProgress:kLoadingProgressMin animated:animated animationSpeed:0.f completion:^{
        wSelf.progressView.hidden = NO;
    }];
}

- (void)finishLoadingProgressAnimated:(BOOL)animated {
    BlockWeakSelf wSelf = self;
    [self setLoadingProgress:kLoadingProgressMax animated:animated animationSpeed:kAnimationDurationCoefficient completion:^{
        wSelf.progressView.hidden = YES;
    }];
}


@end
