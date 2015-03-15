#import <UIKit/UIKit.h>
#import "NavigationButtonsView.h"
#import "LoadingProgressView.h"

typedef NS_ENUM(NSUInteger, AddressBarEditingState) {
    kAddressBarEditingState_View,
    kAddressBarEditingState_Editing
};

typedef NS_ENUM(NSUInteger, AddressBarLoadingState) {
    kAddressBarLoadingState_Loading,
    kAddressBarLoadingState_NotLoading
};

@protocol AddressBarDelegate;

@interface AddressBar : UIView <LoadingProgressView, NavigationControl>

@property (nonatomic, weak) IBOutlet id <AddressBarDelegate> delegate;
@property (nonatomic, readonly) AddressBarEditingState editingState;
@property (nonatomic, assign) AddressBarLoadingState loadingState;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *urlString;

@end

@protocol AddressBarDelegate <NSObject>

@optional
- (void)addressBarDidRequestNextPage:(AddressBar *)bar;
- (void)addressBarDidRequestPrevPage:(AddressBar *)bar;
- (void)addressBar:(AddressBar *)bar didRequestString:(NSString *)address;
- (void)addressBarDidRequestReloading:(AddressBar *)bar;
- (void)addressBarDidRequestCanceling:(AddressBar *)bar;

@end
