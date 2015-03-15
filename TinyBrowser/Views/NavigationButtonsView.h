#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NavigationButtonType) {
    kNavigationButtonType_Prev,
    kNavigationButtonType_Next
};

@protocol NavigationButtonsViewDelegate;

@protocol NavigationControl

- (void)setButton:(NavigationButtonType)buttonType enabled:(BOOL)enabled;

@end

@interface NavigationButtonsView : UIView <NavigationControl>

@property (nonatomic, weak) id <NavigationButtonsViewDelegate> delegate;

+ (CGSize)preferdSize;

@end

@protocol NavigationButtonsViewDelegate <NSObject>

- (void)navigationButtonsView:(NavigationButtonsView *)view tappedButton:(NavigationButtonType)type;

@end

