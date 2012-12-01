
#import <UIKit/UIKit.h>
#import "RichText.h"
#import "NSString.h"

@interface RichTextLabel : UIView
{
    @private
    RichText* _text;
    UIColor* _textColor;
    UIColor* _highlightedTextColor;
    UIEdgeInsets _contentInset;
    BOOL _highlighted;
}

- (RichText*) text;
- (void) setText:(RichText*)text;

- (BOOL) highlighted;
- (void) setHighlighted:(BOOL)highlighted;

- (UIColor*) textColor;
- (void) setTextColor:(UIColor*)textColor;

@end
