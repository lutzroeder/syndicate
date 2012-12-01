
#import <Foundation/Foundation.h>

@interface BadgeLabel : UILabel
{
    @private
    UIColor* _fillColor;
    UIColor* _highlightedFillColor;
}

- (void) setFillColor:(UIColor*)color;
- (void) setHighlightedFillColor:(UIColor*)color;

@end
