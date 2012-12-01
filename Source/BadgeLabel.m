
#import "BadgeLabel.h"

@implementation BadgeLabel

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [_fillColor release];
    [_highlightedFillColor release];
    [super dealloc];
}

- (void) setFillColor:(UIColor*)color
{
    [_fillColor release];
    _fillColor = [color retain];
}

- (void) setHighlightedFillColor:(UIColor*)color
{
    [_highlightedFillColor release];
    _highlightedFillColor = [color retain];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    UIColor* backgroundColor = self.highlighted ? _highlightedFillColor : _fillColor;
	CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    float radius = self.bounds.size.height / 2.0;
    CGContextBeginPath(context);
    CGContextAddArc(context, radius, radius, radius, (float) (M_PI / 2), (float) (3 * M_PI / 2), NO);
    CGContextAddArc(context, self.bounds.size.width - radius, radius, radius, (float) (3 * M_PI / 2), (float) (M_PI / 2), NO);
    CGContextClosePath(context);
    CGContextFillPath(context);
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGSize size = [self.text sizeWithFont:self.font];
    [self.text drawAtPoint:CGPointMake((self.bounds.size.width - size.width) / 2, (self.bounds.size.height - size.height) / 2) withFont:self.font];
    CGContextRestoreGState(context);
}

- (void) drawTextInRect:(CGRect)rect
{
}

@end
