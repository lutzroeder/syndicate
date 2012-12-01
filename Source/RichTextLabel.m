
#import "RichTextLabel.h"

@implementation RichTextLabel

- (id) initWithFrame:(CGRect)frame 
{
	self = [super initWithFrame:frame];

    _contentInset   = UIEdgeInsetsZero;
    
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor clearColor];

    _textColor = [[UIColor blackColor] retain];
    _highlightedTextColor = [[UIColor whiteColor] retain];

    return self;
}

- (void) dealloc
{
    [_text release];
    [_textColor release];
    [_highlightedTextColor release];

    [super dealloc];
}

- (BOOL)isHighlighted 
{
    return _highlighted;
}

- (void) drawRect:(CGRect)rect 
{
    [super drawRect:rect];

    if (_highlighted) 
    {
        [_highlightedTextColor setFill];
    } 
    else 
    {
        [_textColor setFill];
    }

    CGPoint origin = CGPointMake(rect.origin.x + _contentInset.left, rect.origin.y + _contentInset.top);
    [_text drawAtPoint:origin highlighted:_highlighted];
}

- (RichText*) text
{
    return _text;
}

- (void) setText:(RichText*)text
{
    if (text != _text) 
    {
        [_text release];
        _text = [text retain];
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

- (UIColor*) textColor
{
    return _textColor;
}

- (void) setTextColor:(UIColor*)textColor
{
    if (textColor != _textColor)
    {
        [_textColor release];
        _textColor = [textColor retain];
        [self setNeedsDisplay];
    }
}

- (BOOL) highlighted
{
    return _highlighted;
}

- (void) setHighlighted:(BOOL)highlighted
{
    if (highlighted != _highlighted)
    {
        _highlighted = highlighted;
        [self setNeedsDisplay];
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];

    CGPoint point = [touch locationInView:self];
    point.x -= _contentInset.left;
    point.y -= _contentInset.top;

    // X = [_text hitText:point]
    // if (X) { setHightlightedElement:X }
    
    /*
    UITableView* tableView = nil;
    UIView* view = self;
    while (view.superview != nil)
    {
        view = view.superview;
        if ([view isKindOfClass:tableView.class])
        {
            tableView = (UITableView*) view;
            break;
        }
    }
    */

    [super touchesBegan:touches withEvent:event];
}

@end
