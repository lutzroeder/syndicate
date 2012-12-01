
#import "RichText.h"

@implementation RichText

- (id) init
{
    self = [super init];
    
    _elements = [[NSMutableArray alloc] init];
    _font = [[UIFont systemFontOfSize:[UIFont systemFontSize]] retain];
    _color = [[UIColor blackColor] retain];
    
    return self;
}

- (void) dealloc
{
    [_color release];
    [_font release];
    [_elements release];
    [super dealloc];
}

- (void) addText:(NSString*)text
{
    [self addText:text maxLines:0];
}

- (void) addText:(NSString*)text maxLines:(NSInteger)maxLines;
{
    NSMutableDictionary* element = [NSMutableDictionary dictionary];
    [element setObject:@"text" forKey:@"type"];
    [element setObject:text forKey:@"text"];
    [element setObject:_color forKey:@"color"];
    [element setObject:_font forKey:@"font"];
    if (maxLines > 0)
    {
        [element setObject:[NSNumber numberWithInt:maxLines] forKey:@"maxLines"];
    }
    [_elements addObject:element];
    [self setNeedsLayout];   
}

- (void) addSeparator:(CGFloat)height;
{
    NSMutableDictionary* element = [NSMutableDictionary dictionary];
    [element setObject:@"separator" forKey:@"type"];
    [element setObject:[NSNumber numberWithFloat:height] forKey:@"height"];
    [_elements addObject:element];
    [self setNeedsLayout];
}

- (void) addImage:(UIImage*)image
{
    NSMutableDictionary* element = [NSMutableDictionary dictionary];
    [element setObject:@"image" forKey:@"type"];
    [element setObject:image forKey:@"image"];
    [_elements addObject:element];
    [self setNeedsLayout];
}

- (void) setFont:(UIFont*)font
{
    [_font release];
    _font = [font retain];    
    [self setNeedsLayout];
}

- (void) setColor:(UIColor*)color
{
    [_color release];
    _color = [color retain];
    [self setNeedsLayout];
}

- (void) setWidth:(CGFloat)width
{
    if (width != _width) 
    {
        _width = width;
        [self setNeedsLayout];
    }
}

- (CGFloat) height
{
    [self layoutIfNeeded];
    return _height;
}

- (void) setMinHeight:(CGFloat)minHeight
{
    if (minHeight != _minHeight)
    {
        _minHeight = minHeight;
        [self setNeedsLayout];
    }
}

- (void) drawAtPoint:(CGPoint)point highlighted:(BOOL)highlighted
{
    [self layoutIfNeeded];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    for (NSMutableDictionary* element in _elements)
    {
        NSString* type = [element objectForKey:@"type"];
        CGFloat x = point.x + [[element objectForKey:@"x"] floatValue];
        CGFloat y = point.y + [[element objectForKey:@"y"] floatValue];
        CGFloat width = [[element objectForKey:@"width"] floatValue];
        CGFloat height = [[element objectForKey:@"height"] floatValue];

        if ([@"text" isEqualToString:type])
        {
            UIFont* font = [element objectForKey:@"font"];
            NSString* text = [element objectForKey:@"text"];
            CGRect rect = CGRectMake(x, y, width, height);
            
            if (!highlighted)
            {
                UIColor* color = [element objectForKey:@"color"];
                [color setFill];
            }

            UILineBreakMode lineBreakMode = NSLineBreakByWordWrapping;
            if ([element objectForKey:@"maxLines"])
            {
                lineBreakMode = NSLineBreakByTruncatingTail;
            }

            [text drawInRect:rect withFont:font lineBreakMode:lineBreakMode];
        }
        else if ([@"image" isEqualToString:type])
        {
            UIImage* image = [element objectForKey:@"image"];
            CGSize size = image.size;
            if ((size.width > 1) && (size.height > 1))
            {
                CGContextRef currentContext = UIGraphicsGetCurrentContext();
                CGContextSaveGState(currentContext);
                CGContextSetShadow(currentContext, CGSizeMake(0, 0.5), 1);
                [[UIColor whiteColor] setFill];
                CGRect rect1 = CGRectMake(x + 1, y + 4, width + 6, height + 6);
                CGContextFillRect(context, rect1);
                CGContextRestoreGState(currentContext);
                CGRect rect2 = CGRectMake(x + 1 + 3, y + 4 + 3, width, height);
                [image drawInRect:rect2];
            }
        }
    }

    CGContextRestoreGState(context);
}

- (void) setNeedsLayout
{
    _height = 0;
}

- (void) layoutIfNeeded
{
    if (_height == 0)
    {
        CGFloat x = 0;
        CGFloat y = 5;
        for (NSMutableDictionary* element in _elements)
        {
            NSString* type = [element objectForKey:@"type"];
            if ([@"text" isEqualToString:type])
            {            
                NSString* text = [element objectForKey:@"text"];
                UIFont* font = [element objectForKey:@"font"];

                CGFloat constraintHeight = 300;
                UILineBreakMode lineBreakMode = NSLineBreakByWordWrapping;
                if ([element objectForKey:@"maxLines"])
                {
                    float fontHeight = [@"X" sizeWithFont:font].height;
                    NSInteger maxLines = [[element objectForKey:@"maxLines"] integerValue];
                    constraintHeight = fontHeight * maxLines;
                    lineBreakMode = NSLineBreakByTruncatingTail;
                }

                CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(_width - 1, constraintHeight) lineBreakMode:lineBreakMode];

                [element setObject:[NSNumber numberWithFloat:x + 1] forKey:@"x"];
                [element setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
                [element setObject:[NSNumber numberWithFloat:size.width] forKey:@"width"];
                [element setObject:[NSNumber numberWithFloat:size.height] forKey:@"height"];             

                y = y + size.height;
                _height = y;
            }
            else if ([@"image" isEqualToString:type])
            {
                UIImage* image = [element objectForKey:@"image"];
                CGSize size = image.size;
                if ((size.width > 1) && (size.height > 1))
                {
                    [element setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
                    [element setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
                    [element setObject:[NSNumber numberWithFloat:size.width] forKey:@"width"];
                    [element setObject:[NSNumber numberWithFloat:size.height] forKey:@"height"];             

                    y = y + size.height + 12;                
                    _height = y;
                }
            }
            else if ([@"separator" isEqualToString:type])
            {
                CGFloat height = [[element objectForKey:@"height"] floatValue];
                
                y = y + height;
                _height = y;
            }
        }
        
        _height = _height + 7;
        
        if (_height < _minHeight)
        {
            CGFloat h = (_minHeight - _height) / 2;

            for (NSMutableDictionary* element in _elements)
            {
                CGFloat x = [[element objectForKey:@"x"] floatValue];
                x = x + h;
                [element setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
            }
            
            _height = _minHeight;
        }
    }
}

@end
