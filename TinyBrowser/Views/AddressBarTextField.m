#import "AddressBarTextField.h"

@implementation AddressBarTextField

- (void)setLeftViewWidth:(CGFloat)width {
    CGRect leftViewBounds = self.leftView.bounds;
    leftViewBounds.size.width = width;
    self.leftView.bounds = leftViewBounds;
}

@end
