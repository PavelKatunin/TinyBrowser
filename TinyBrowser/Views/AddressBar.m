#import "AddressBar.h"
#import <QuartzCore/QuartzCore.h>
#import "NSLayoutConstraint+Helpers.h"
#import "AddressBarTextField.h"
#import "UIColor+Browser.h"

static const CGFloat kCancelButtonWidth = 56.f;
static const CGFloat kAnimationDuration = 0.3f;
static const CGSize kTextFieldRightButtonSize = { 28.f, 16.f };
static const CGFloat kMargin = 8.f;

@interface AddressBar () <UITextFieldDelegate,
                          NavigationButtonsViewDelegate>

// views
@property (nonatomic, weak) UITextField *textField;
@property (nonatomic, weak) UIButton *cancelButton;
@property (nonatomic, weak) UIView *contentContainerView;
@property (nonatomic, weak) NavigationButtonsView *navigationButtonsView;
@property (nonatomic, weak) LoadingProgressView *progressView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *reloadButton;
@property (nonatomic, strong) UIButton *cancelRequestButton;

// state
@property (nonatomic, assign) AddressBarEditingState editingState;
@property (nonatomic, weak) NSLayoutConstraint *textFieldRightOffset;
@property (nonatomic, weak) NSLayoutConstraint *textFieldLeftOffset;
@property (nonatomic, strong) NSString *snapshottedUrl;

- (void)setEditingState:(AddressBarEditingState)state animated:(BOOL)animated;
- (void)setUiForState:(AddressBarEditingState)state;

- (UITextField *)createTextField;
- (UIView *)createContentContainerView;
- (UIButton *)createCancelButton;
- (NavigationButtonsView *)createNavigationButtonsView;
- (LoadingProgressView *)createProgressView;
- (UILabel *)createTitleLabel;
- (UIButton *)createReloadButton;
- (UIButton *)createCancelRequestButton;

- (NSArray *)createTextFieldConstraints;
- (NSArray *)createContentContainerViewConstraints;
- (NSArray *)createCancelButtonConstraints;
- (NSArray *)createNavigationButtonsViewConstraints;
- (NSArray *)createProgressViewConstraints;
- (NSArray *)createTitleViewConstraints;

- (void)cancelButtonTapped:(id)sender;

- (void)createLayout;
- (void)createSubviews;

@end

@implementation AddressBar

#pragma mark - Properties

- (void)setEditingState:(AddressBarEditingState)state {
    [self setEditingState:state animated:YES];
}

- (void)setLoadingState:(AddressBarLoadingState)loadingState {
    _loadingState = loadingState;
    switch (loadingState) {
        case kAddressBarLoadingState_Loading:
            self.textField.rightView = self.cancelRequestButton;
            self.textField.rightViewMode = UITextFieldViewModeUnlessEditing;
            break;
        case kAddressBarLoadingState_NotLoading: {
            self.textField.rightView = self.reloadButton;
            self.textField.rightViewMode = UITextFieldViewModeUnlessEditing;
        }
            break;
        default:
            NSAssert(NO, @"Unsupported state");
            break;
    }
    [self.textField setNeedsLayout];
    [self.textField layoutIfNeeded];
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setUrlString:(NSString *)urlString {
    self.textField.text = urlString;
}

- (NSString *)urlString {
    return self.textField.text;
}

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self != nil) {
        self.tintColor = [UIColor skinColor];
        [self createSubviews];
        [self createLayout];
        self.loadingState = kAddressBarLoadingState_NotLoading;
    }
    return self;
}

#pragma mark - Public

#pragma mark- ProgressView

- (double)loadingProgress {
    return self.progressView.loadingProgress;
}

- (void)setLoadingProgress:(double)loadingProgress animated:(BOOL)animated {
    [self.progressView setLoadingProgress:loadingProgress animated:animated];
    self.loadingState = kAddressBarLoadingState_Loading;
}

- (void)startLoadingProgressAnimated:(BOOL)animated {
    [self.progressView startLoadingProgressAnimated:animated];
    self.loadingState = kAddressBarLoadingState_Loading;
}

- (void)finishLoadingProgressAnimated:(BOOL)animated {
    [self.progressView finishLoadingProgressAnimated:animated];
    self.loadingState = kAddressBarLoadingState_NotLoading;
}

#pragma mark - NavigationControl

- (void)setButton:(NavigationButtonType)buttonType enabled:(BOOL)enabled {
    [self.navigationButtonsView setButton:buttonType enabled:enabled];
}

#pragma mark - Private

- (void)setEditingState:(AddressBarEditingState)state animated:(BOOL)animated {
    _editingState = state;
    
    if (state == kAddressBarEditingState_Editing) {
        self.snapshottedUrl = self.textField.text;
    }
    else {
        self.loadingState = _loadingState;
    }
    
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration
                              delay:0.
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self setUiForState:state];
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             if (_editingState == kAddressBarEditingState_Editing) {
                                 [self.textField selectAll:self.textField];
                                 [UIMenuController sharedMenuController].menuVisible = NO;
                             }
                         }];
    }
    else {
        [self setUiForState:state];
    }
}

- (void)setUiForState:(AddressBarEditingState)state {
    switch (state) {
        case kAddressBarEditingState_View:
            self.textFieldRightOffset.constant = - kMargin;
            self.textFieldLeftOffset.constant = [NavigationButtonsView preferdSize].width + kMargin;
            self.navigationButtonsView.alpha = 1.f;
            self.cancelButton.alpha = 0.f;
            break;
        case kAddressBarEditingState_Editing:
            self.textFieldRightOffset.constant = - kCancelButtonWidth - kMargin;
            self.textFieldLeftOffset.constant = kMargin;
            self.navigationButtonsView.alpha = 0.;
            self.cancelButton.alpha = 1.;
            break;
        default:
            NSAssert(NO, @"Unsuported state");
            break;
    }
}

- (UITextField *)createTextField {
    AddressBarTextField *textField = [[AddressBarTextField alloc] init];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.backgroundColor = [UIColor whiteColor];
    textField.delegate = self;
    textField.keyboardType = UIKeyboardTypeWebSearch;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.layer.cornerRadius = 5.f;
    textField.clipsToBounds = YES;
    textField.font = [UIFont systemFontOfSize:15.f];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.enablesReturnKeyAutomatically = YES;
    textField.returnKeyType = UIReturnKeyGo;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.leftView = [UIView new];
    [textField setLeftViewWidth:kMargin];
    textField.rightViewMode = UITextFieldViewModeUnlessEditing;
    textField.placeholder = NSLocalizedString(@"idsAddressBarPlaceholder", @"");
    
    return textField;
}

- (UIView *)createContentContainerView {
    UIView *containerView = [[UIView alloc] init];
    return containerView;
}

- (UIButton *)createCancelButton {
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:NSLocalizedString(@"idsCancel", @"") forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return cancelButton;
}

- (NavigationButtonsView *)createNavigationButtonsView {
    NavigationButtonsView *navigatioButtonsView = [[NavigationButtonsView alloc] init];
    navigatioButtonsView.delegate = self;
    return navigatioButtonsView;
}

- (LoadingProgressView *)createProgressView {
    LoadingProgressView *progressView = [[LoadingProgressView alloc] init];
    return progressView;
}

- (UILabel *)createTitleLabel {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
    titleLabel.textColor = [UIColor darkGrayColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    return titleLabel;
}

- (UIButton *)createReloadButton {
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [reloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];
    [reloadButton addConstraints:[NSLayoutConstraint constraintsForView:reloadButton
                                                               withSize:kTextFieldRightButtonSize]];
    [reloadButton addTarget:self action:@selector(reloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return reloadButton;
}

- (void)reloadButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addressBarDidRequestReloading:)]) {
        [self.delegate addressBarDidRequestReloading:self];
    }
}

- (UIButton *)createCancelRequestButton {
    UIButton *cancelRequestButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelRequestButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    [cancelRequestButton addConstraints:[NSLayoutConstraint constraintsForView:cancelRequestButton
                                                                      withSize:kTextFieldRightButtonSize]];
    
    [cancelRequestButton addTarget:self action:@selector(cancelRequestButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return cancelRequestButton;
}

- (void)cancelRequestButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addressBarDidRequestCanceling:)]) {
        [self.delegate addressBarDidRequestCanceling:self];
    }
}

- (void)cancelButtonTapped:(id)sender {
    self.editingState = kAddressBarEditingState_View;
    [self.textField resignFirstResponder];
    self.textField.text = self.snapshottedUrl;
}

- (void)createLayout {
    [self addConstraints:[self createContentContainerViewConstraints]];
    [self.contentContainerView addConstraints:[self createTextFieldConstraints]];
    [self.contentContainerView addConstraints:[self createCancelButtonConstraints]];
    [self.contentContainerView addConstraints:[self createNavigationButtonsViewConstraints]];
    [self.contentContainerView addConstraints:[self createProgressViewConstraints]];
    [self.contentContainerView addConstraints:[self createTitleViewConstraints]];
}

- (void)createSubviews {
    UIView *contentConteinerView = [self createContentContainerView];
    contentConteinerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainerView = contentConteinerView;
    [self addSubview:contentConteinerView];
    
    UITextField *textField = [self createTextField];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField = textField;
    [self.contentContainerView addSubview:textField];
    
    UIButton *cancelButton = [self createCancelButton];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelButton = cancelButton;
    [self.contentContainerView addSubview:cancelButton];
    
    NavigationButtonsView *navigationsButtonView = [self createNavigationButtonsView];
    navigationsButtonView.translatesAutoresizingMaskIntoConstraints = NO;
    navigationsButtonView.userInteractionEnabled = YES;
    self.navigationButtonsView = navigationsButtonView;
    [self.contentContainerView addSubview:navigationsButtonView];
    
    LoadingProgressView *progressView = [self createProgressView];
    self.progressView = progressView;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainerView addSubview:progressView];
    
    UILabel *titleLabel = [self createTitleLabel];
    self.titleLabel = titleLabel;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainerView addSubview:titleLabel];
    
    UIButton *reloadButton = [self createReloadButton];
    self.reloadButton = reloadButton;
    reloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.rightView = reloadButton;
    
    UIButton *cancelRequestButton = [self createCancelRequestButton];
    self.cancelRequestButton = cancelRequestButton;
    cancelRequestButton.translatesAutoresizingMaskIntoConstraints = NO;
}

#pragma mark - Constraints

- (NSArray *)createTextFieldConstraints {
    UITextField *textField = self.textField;
    UIView *containerView = self.contentContainerView;
    NSMutableArray *constraints = [NSMutableArray array];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(8@500)-[textField]-(8@500)-|"
                                                                               views:NSDictionaryOfVariableBindings(textField)];
    
    NSLayoutConstraint *leftOffset = [NSLayoutConstraint constraintWithItem:textField
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:containerView
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1.
                                                                   constant:[NavigationButtonsView preferdSize].width + kMargin];
    self.textFieldLeftOffset = leftOffset;
    NSLayoutConstraint *rightOffset = [NSLayoutConstraint constraintWithItem:textField
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:containerView
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.
                                                                    constant: - kMargin];
    self.textFieldRightOffset = rightOffset;
    
    [constraints addObjectsFromArray:@[leftOffset, rightOffset]];
    
    
    NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintForCenterByYView:textField withView:containerView];
    [constraints addObjectsFromArray:horizontalConstraints];
    [constraints addObject:verticalConstraint];
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintForView:textField withHeight:26.f];
    [textField addConstraint:height];
    
    return constraints;
}

- (NSArray *)createContentContainerViewConstraints {
    UIView *containerView = self.contentContainerView;

    NSArray *constraints = [NSLayoutConstraint constraintsForWrappedSubview:containerView
                                                                 withInsets:UIEdgeInsetsMake(10., 0., 0., 0.)];
    return constraints;
}

- (NSArray *)createCancelButtonConstraints {
    UIButton *cancelButton = self.cancelButton;
    UIView *containerView = self.contentContainerView;
    UITextField *textField = self.textField;
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[textField]-8-[cancelButton]-(8@500)-|"
                                                                               views:NSDictionaryOfVariableBindings(textField, cancelButton)];
    [constraints addObjectsFromArray:horizontalConstraints];
    
    NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintForCenterByYView:cancelButton
                                                                                   withView:containerView];
    [constraints addObject:verticalConstraint];
    
    return constraints;
}

- (NSArray *)createNavigationButtonsViewConstraints {
    NavigationButtonsView *navigationButtons = self.navigationButtonsView;
    UIView *containerView = self.contentContainerView;
    UITextField *textField = self.textField;
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(4@500)-[navigationButtons]-8-[textField]"
                                                                               views:NSDictionaryOfVariableBindings(textField, navigationButtons)];
    [constraints addObjectsFromArray:horizontalConstraints];
    
    NSLayoutConstraint *navigationButtonsHeight = [NSLayoutConstraint constraintForView:navigationButtons
                                                                             withHeight:[NavigationButtonsView preferdSize].height];
    
    [navigationButtons addConstraint:navigationButtonsHeight];
    
    NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintForCenterByYView:navigationButtons
                                                                        withView:containerView];
    [constraints addObject:verticalConstraint];
    
    return constraints;
}

- (NSArray *)createProgressViewConstraints {
    LoadingProgressView *progressView = self.progressView;
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *horizontalConstraints = [NSLayoutConstraint horizontalConstraintsForWrappedSubview:progressView
                                                                                     withInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [constraints addObjectsFromArray:horizontalConstraints];
    
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[progressView]-0-|"
                                                                             views:NSDictionaryOfVariableBindings(progressView)];
    
    [constraints addObjectsFromArray:verticalConstraints];
   
    NSLayoutConstraint *progressViewHeight = [NSLayoutConstraint constraintForView:progressView
                                                                        withHeight:2.f];
    [progressView addConstraint:progressViewHeight];
    
    return constraints;
}

- (NSArray *)createTitleViewConstraints {
    UILabel *titleLabel = self.titleLabel;
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *horizontalConstraints = [NSLayoutConstraint horizontalConstraintsForWrappedSubview:titleLabel
                                                                                     withInsets:UIEdgeInsetsMake(0, 4., 0, 4.)];
    [constraints addObjectsFromArray:horizontalConstraints];
    
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleLabel]-0-|"
                                                                             views:NSDictionaryOfVariableBindings(titleLabel)];
    
    [constraints addObjectsFromArray:verticalConstraints];
    
    NSLayoutConstraint *titleHeight = [NSLayoutConstraint constraintForView:titleLabel
                                                                        withHeight:18.f];
    [titleLabel addConstraint:titleHeight];
    
    return constraints;

}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.editingState = kAddressBarEditingState_Editing;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(addressBar:didRequestString:)]) {
        [self.delegate addressBar:self didRequestString:self.textField.text];
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.editingState = kAddressBarEditingState_View;
}

#pragma mark - NavigationButtonsViewDelegate

- (void)navigationButtonsView:(NavigationButtonsView *)view tappedButton:(NavigationButtonType)type {
    switch (type) {
        case kNavigationButtonType_Prev:
            if ([self.delegate respondsToSelector:@selector(addressBarDidRequestPrevPage:)]) {
                [self.delegate addressBarDidRequestPrevPage:self];
            }
            break;
        case kNavigationButtonType_Next:
            if ([self.delegate respondsToSelector:@selector(addressBarDidRequestNextPage:)]) {
                [self.delegate addressBarDidRequestNextPage:self];
            }
            break;
            
        default:
            NSAssert(NO, @"Unsupported type");
            break;
    }
}

@end
