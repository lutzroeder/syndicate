
#import "UIImage.h"

@implementation UIImage (highlightedImage)

+ (UIImage*) highlightedImage:(UIImage*)image
{
    if (image != nil)
    {
        // Create white mask of original image
        UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        [[UIColor whiteColor] setFill];
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeMultiply);
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        CGContextClipToMask(context, rect, image.CGImage);
        CGContextAddRect(context, rect);
        CGContextDrawPath(context, kCGPathFill);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

+ (UIImage*) grayscaleImage:(UIImage*)image
{
    if (image != nil)
    {
        CGFloat width = image.size.width * image.scale;
        CGFloat height = image.size.height * image.scale;
        CGRect imageRect = CGRectMake(0, 0, width, height);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CGContextRef context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, kCGImageAlphaNone);
        CGContextDrawImage(context, imageRect, [image CGImage]);
        CGImageRef grayImage = CGBitmapContextCreateImage(context);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        context = CGBitmapContextCreate(nil, width, height, 8, 0, nil, kCGImageAlphaOnly);
        CGContextDrawImage(context, imageRect, [image CGImage]);
        CGImageRef mask = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        CGImageRef imageRef = CGImageCreateWithMask(grayImage, mask);
        image = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(imageRef);
        CGImageRelease(grayImage);
        CGImageRelease(mask);
    }
    return image;
}

+ (UIImage*) imageWithSize:(CGSize)imageSize fillColor:(UIColor*)fillColor
{
    CGRect rect = CGRectMake(0.0f, 0.0f, imageSize.width, imageSize.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();    
    CGContextSetFillColorWithColor(context, [fillColor CGColor]);
    CGContextFillRect(context, rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage*) imageWithSize:(CGFloat)imageSize drawCrossWithSize:(CGFloat)size width:(CGFloat)width color:(UIColor*)color;
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize, imageSize), NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetShouldAntialias(context, YES);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextSetLineWidth(context, width);
    CGContextSetLineCap(context, kCGLineCapButt);
    
    CGFloat start = (imageSize - size) / 2;
    CGFloat end = start + size;
    CGContextMoveToPoint(context, start, start);
    CGContextAddLineToPoint(context, end, end);
    CGContextMoveToPoint(context, end, start);
    CGContextAddLineToPoint(context, start, end);
    CGContextStrokePath(context);    

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;    
}

+ (UIImage*) imageWithSize:(CGFloat)imageSize drawCircleWithSize:(CGFloat)size width:(CGFloat)width color:(UIColor*)color fillColor:(UIColor*)fillColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize, imageSize), NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetShouldAntialias(context, YES);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextSetLineWidth(context, width);

    CGFloat start = (imageSize - size) / 2;
    CGRect rect = CGRectMake(start, start, size, size);
    CGContextStrokeEllipseInRect(context, rect);

    if (fillColor)
    {
        CGContextSetFillColorWithColor(context, [fillColor CGColor]);
        CGContextFillEllipseInRect(context, rect);
    }

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
