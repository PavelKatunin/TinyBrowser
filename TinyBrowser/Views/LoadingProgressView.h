#import <UIKit/UIKit.h>

@protocol LoadingProgressView

@property (nonatomic, readonly, assign) double loadingProgress;

- (void)setLoadingProgress:(double)loadingProgress animated:(BOOL)animated;
- (void)startLoadingProgressAnimated:(BOOL)animated;
- (void)finishLoadingProgressAnimated:(BOOL)animated;

@end

@interface LoadingProgressView : UIView <LoadingProgressView>

@end
