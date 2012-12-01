
#import <Foundation/Foundation.h>
#import "WebUtility.h"

@interface RichText : NSObject
{
    @private
    NSMutableArray* _elements;
    UIFont* _font;
    UIColor* _color;
    
    CGFloat _width;
    CGFloat _height;
    CGFloat _minHeight;
}

- (void) addText:(NSString*)text;
- (void) addText:(NSString*)text maxLines:(NSInteger)maxLines;
- (void) addImage:(UIImage*)image;
- (void) addSeparator:(CGFloat)height;

- (void) setFont:(UIFont*)font;
- (void) setColor:(UIColor*)color;

- (void) setWidth:(CGFloat)width;
- (void) setMinHeight:(CGFloat)minHeight;
- (CGFloat) height;

- (void) drawAtPoint:(CGPoint)point highlighted:(BOOL)highlighted;

- (void) setNeedsLayout;
- (void) layoutIfNeeded;

@end
